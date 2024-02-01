# -*- coding: utf-8 -*-

from eve import Eve
from v1.oauth2.oauth2 import BearerAuth
from v1.oauth2.flask_sentinel import ResourceOwnerPasswordCredentials
import bcrypt
from flask import abort
from v1.oauth2.flask_sentinel import oauth
from flask import jsonify, request, render_template, Blueprint
import logging
import json
from bson import ObjectId
from datetime import datetime
import pymongo
from core import RiskManager, Portfolio, CashFlow, NetAssetValue, Possition, TradeHistory
from flask.ext.bootstrap import Bootstrap
from eve_docs import eve_docs
from deco import concurrent, synchronized
from flask_bootstrap import Bootstrap


def before_every_get(resource, request, payload):
    # custom INFO-level message is sent to the log file
    # app.logger.info('We just answered to a GET request!')
    pass


@synchronized
def pre_get_callback(resource, request, lookup):
    if resource == 'portfolios':
        if len(lookup) != 0:
            Portfolio.get_portfolio(ObjectId(lookup["_id"]))
        else:
            portfolios = app.data.driver.db.portfolios.find({"_deleted": False})
            for portfolio in portfolios:
                Portfolio.get_portfolio(ObjectId(portfolio["_id"]))


def pre_post_callback(resource, request, lookup):
    if resource == 'users':
        pass
    if resource == 'admin':
        abort(403)


def before_insert(resource_name, items):
    """
    Before DB Insert Event
    :param resource_name:
    :param items:
    :return:
    """
    # hash password when user create
    if resource_name == 'users':
        password = items[0]['hashpw']
        salt = bcrypt.gensalt()
        items[0]['hashpw'] = bcrypt.hashpw(password.encode('utf-8'), salt)
    if resource_name == 'portfolios':
        # init calDate, when calculate portfolio to update calDate
        Portfolio.init_portfolio(items)
    if resource_name == 'risk_manager':
        RiskManager.buy(items)


def after_inserted(resource_name, items):
    if resource_name == 'portfolios':
        portfolio_id = items[0]["_id"]
        user_id = items[0]["__user_id__"]
        init_money = items[0]["initial_money"]
        CashFlow.init_cash(portfolio_id, user_id, init_money)
        NetAssetValue.init_net(portfolio_id, user_id, init_money)
    if resource_name == 'risk_manager':
        risk_id = items[0]["_id"]
        Possition.add(risk_id, items)
        TradeHistory.add_buy(risk_id, items)
        # update portfolio info after insert risk
        risk = app.data.driver.db.risk_manager.find_one({"_id": risk_id})
        Portfolio.get_portfolio(risk["portfolios"], risk["buy"]["trade_buy_date"])
    if resource_name == 'cashflow_history':
        Portfolio.get_portfolio(items[0]["portfolios"], items[0]["transfer_date"])


def on_update(resource_name, updates, original):
    if resource_name == 'users':
        password = updates['hashpw']
        salt = bcrypt.gensalt()
        updates['hashpw'] = bcrypt.hashpw(password.encode('utf-8'), salt)
    if resource_name == 'risk_manager' and not updates.has_key("is_event"):
        if updates.has_key("sale"):
            RiskManager.sale(original, updates)
        elif updates.has_key("buy"):
            RiskManager.update_buy_dp(original, updates)


def on_updated(resource_name, updates, original):
    if resource_name == 'risk_manager' and not updates.has_key("is_event"):
        if updates.has_key("sale"):
            if not original.has_key("buy_sale_dp"):
                Possition.remove(original["_id"])
                TradeHistory.add_sale(original, updates)
            else:
                TradeHistory.update_sale(original, updates)
            # update portfolio info after insert risk sale
            Portfolio.get_portfolio(updates["portfolios"], updates["sale"]["trade_sale_date"])
        elif updates.has_key("buy"):
            TradeHistory.update_buy(original, updates)
            if not original.has_key("buy_sale_dp"):
                Possition.update(original, updates)
            # update portfolio info after update risk buy
            Portfolio.get_portfolio(updates["portfolios"], updates["buy"]["trade_buy_price"])


def on_delete_item(resource_name, item):
    pass


def on_deleted_item(resource_name, item):
    if resource_name == 'risk_manager':
        Possition.remove(item["_id"])
        TradeHistory.remove(item["_id"])
        # update portfolio info from deleted risk date
        risk = app.data.driver.db.risk_manager.find_one({"_id": item["_id"], "_deleted": True})
        Portfolio.get_portfolio(risk["portfolios"], risk["buy"]["trade_buy_date"])
    if resource_name == 'cashflow_history':
        # update portfolio info from deleted cash date
        cash = app.data.driver.db.cashflow_history.find_one({"_id": item["_id"], "_deleted": True})
        Portfolio.get_portfolio(cash["portfolios"], cash["transfer_date"])


def after_post_upload_callback(request, payload):
    """
    Add media file path to upload resource response which is first created
    :param request: post request
    :param payload: post response payload
    :return: None
    """
    # get response which is string
    response = payload.response[0]
    # convert response to dict
    dict = json.loads(response)
    # add file_path to response dict
    file_id = app.data.driver.db.upload.find_one({"_id": ObjectId(dict["_id"])})["file"]
    dict["file_path"] = "/" + app.config['API_VERSION'] + "/" + app.config['MEDIA_ENDPOINT'] + "/" + str(file_id)
    # convert dict to response string
    json_str = json.dumps(dict)
    payload.content_length = len(json_str)
    payload.response[0] = json_str


def on_fetch(resource_name, items):
    pass

cloud = Blueprint('cloud', __name__, template_folder='templates')


@cloud.route('/asset', methods=['GET'])
def asset(name=None):
    return render_template('asset.html', name=name)


@cloud.route('/quotation', methods=['GET'])
def quotation(name=None):
    return render_template('quotation.html', name=name)


@cloud.route('/strategy', methods=['GET'])
def strategy(name=None):
    return render_template('strategy.html', name=name)


app = Eve(auth=BearerAuth, settings='v1/settings.py')
app.register_blueprint(cloud)
app.on_pre_GET += pre_post_callback
app.on_pre_GET += pre_get_callback
app.on_post_GET += before_every_get
app.on_insert += before_insert
app.on_update += on_update
app.on_updated += on_updated
app.on_fetch += on_fetch
app.on_inserted += after_inserted
app.on_delete_item += on_delete_item
app.on_deleted_item += on_deleted_item
app.on_post_POST_upload += after_post_upload_callback
ResourceOwnerPasswordCredentials(app)
Bootstrap(app)


@app.route('/user', methods=['GET'])
@oauth.require_oauth()
def user():
    try:
        token = request.headers.get('Authorization').split(' ')[1]
    except:
        token = None
    token_dic = app.data.driver.db.tokens.find_one({"access_token": token})
    user_dic = app.data.driver.db.users.find_one(token_dic["user_id"])
    user_dic["_id"] = str(user_dic["_id"])
    # hidden hash password key
    user_dic.pop("hashpw")
    return jsonify(user_dic)

if __name__ == '__main__':
    # import logging
    # logger = logging.getLogger('eve')
    # logger.addHandler(logging.StreamHandler())
    # logger.setLevel(logging.DEBUG)

    # enable logging to 'app.log' file
    handler = logging.FileHandler('log/app.log')

    # set a custom log format, and add request
    # metadata to each log line
    handler.setFormatter(logging.Formatter(
        '%(asctime)s %(levelname)s: %(message)s '
        '[in %(filename)s:%(lineno)d] -- ip: %(clientip)s, '
        'url: %(url)s, method:%(method)s'))

    # the default log level is set to WARNING, so
    # we have to explictly set the logging level
    # to INFO to get our custom message logged.
    app.logger.setLevel(logging.INFO)

    # append the handler to the default application logger
    app.logger.addHandler(handler)

    # config eve-docs support
    # Bootstrap(app)
    # app.register_blueprint(eve_docs, url_prefix='/docs')

    app.run(ssl_context='adhoc')