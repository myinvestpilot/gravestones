from flask import current_app as app
from datetime import datetime
import pymongo
from eve.methods.post import post_internal
from eve.methods.patch import patch_internal
from eve.methods.put import put_internal
from eve.methods.delete import deleteitem_internal, delete, deleteitem
from eve.methods.common import get_document
import json
from utils import Stock, ExcleFuc, Tools
from datetime import timedelta
import pandas as pd
from pandas.tseries.offsets import BDay
import pytz
import copy
from flask import abort
from bson import ObjectId
from deco import concurrent, synchronized


class Portfolio(object):
    @staticmethod
    def init_portfolio(items):
        today = datetime.today()
        initial_money = items[0]['initial_money']
        # wrap items which contain portfolio field
        items[0]["cal_date"] = today
        items[0]["is_public"] = False
        items[0]["portfolio_risk_money"] = 0
        items[0]["portfolio_risk_ratio"] = 0
        items[0]["portfolio_floating_profit_loss"] = 0
        items[0]["portfolio_win_ratio"] = 0
        items[0]["portfolio_profit_loss_ratio"] = 0
        items[0]["portfolio_market_value"] = initial_money
        items[0]["portfolio_return_ratio"] = 0
        items[0]["portfolio_return_ratio_year"] = 0
        items[0]["portfolio_position_date"] = today
        items[0]["portfolio_position"] = 0
        items[0]["portfolio_profit_loss_month_ratio"] = 0
        items[0]["portfolio_retreat_range"] = 0
        items[0]["portfolio_created_date"] = today
        items[0]["portfolio_current_date"] = today
        items[0]["portfolio_begin_month_money"] = 0
        items[0]["portfolio_begin_month_net"] = 0
        items[0]["portfolio_average_position_day"] = 0
        items[0]["portfolio_begin_amount"] = initial_money
        items[0]["portfolio_current_amount"] = initial_money
        items[0]["portfolio_created_net"] = 1
        items[0]["portfolio_current_net"] = 1
        items[0]["portfolio_biggest_retreat_day"] = 0
        items[0]["portfolio_biggest_retreat_range"] = 0
        items[0]["portfolio_trade_style"] = "Normal"
        items[0]["portfolio_trade_total_count"] = 0
        items[0]["portfolio_trade_total_day"] = 0
        items[0]["portfolio_trade_count_ratio"] = 0
        items[0]["portfolio_sync_time"] = today

    @staticmethod
    @concurrent
    def get_portfolio(portfolio_id, start_date=None):
        """
        Get portfolio info
        :param portfolio_id:
        :return:
        """
        Possition.position_history(portfolio_id, start_date)
        NetAssetValue.update_net(portfolio_id, start_date)
        RiskManager.update_risk(portfolio_id)
        Possition.update_possition(portfolio_id)
        Portfolio.update_portfolio(portfolio_id)

    @staticmethod
    def cal_win_ratio(portfolio_id):
        """
        Calculate portfolio win ratio
        :param portfolio_id:
        :return:
        """
        win = 0
        cursor = app.data.driver.db.risk_manager.find({'$and': [{"_deleted": False}, {"portfolios": portfolio_id}]})
        if cursor.count() > 0:
            for item in cursor:
                if item["buy_dp"]["floating_profit_loss"] > 0:
                    win += 1
            return win / cursor.count()
        else:
            return 0

    @staticmethod
    def cal_profit_loss_ratio(portfolio_id):
        """
        Calculate portfolio profit loss ratio
        :param portfolio_id:
        :return:
        """
        profit = 0
        loss = 0
        cursor = app.data.driver.db.risk_manager.find({'$and': [{"_deleted": False}, {"portfolios": portfolio_id}]})
        if cursor.count() > 0:
            for item in cursor:
                if item["buy_dp"]["floating_profit_loss"] >= 0:
                    profit += item["buy_dp"]["floating_profit_loss"]
                else:
                    loss += item["buy_dp"]["floating_profit_loss"]
            if loss != 0:
                return -1 * profit / loss
            else:
                return 0
        else:
            return 0

    @staticmethod
    def get_net_month_value(portfolio_id):
        """
        Get net value of this month
        :param portfolio_id:
        :return:
        """
        mm = mn = 0
        begin_month = datetime.today().replace(day=1).date()
        lookup_dict = {'$and': [{"_deleted": False}, {"trade_date": {'$gte': Tools.date_to_datetime(begin_month)}}, {"portfolios": portfolio_id}]}
        data = app.data.driver.db.net_asset_value.find(lookup_dict).sort('trade_date', pymongo.ASCENDING).limit(1)
        if data.count() > 0:
            mm = data[0]["portfolio_market_value"]
            mn = data[0]["portfolio_net_value"]
        return mm, mn

    @staticmethod
    def get_retreat(portfolio_id):
        """
        Get retreat day & range
        :param portfolio_id:
        :return:
        """
        day = n_range = 0
        lookup_dict = {'$and': [{"_deleted": False}, {"portfolios": portfolio_id}]}
        cursor = app.data.driver.db.net_asset_value.find(lookup_dict)
        if cursor.count() > 0:
            for item in cursor:
                if item["portfolio_net_retreat_day"] > day:
                    day = item["portfolio_net_retreat_day"]
                if item["portfolio_net_retreat_change"] < n_range:
                    n_range = item["portfolio_net_retreat_change"]
        return day, n_range

    @staticmethod
    def update_portfolio(portfolio_id):
        """
        Update portfolio info
        :param portfolio_id:
        :return:
        """
        today = datetime.today()
        if today.hour < 20:
            today = datetime.today() + timedelta(-1)
        start = today.date() + timedelta(-1)
        end = today.date() + timedelta(+1)
        risks = app.data.driver.db.risk_manager.find({'$and': [{"_deleted": False}, {"portfolios": portfolio_id}, {"is_hold": False}]})
        portfolio = app.data.driver.db.portfolios.find({'$and': [{"_deleted": False}, {"_id": portfolio_id}]})
        net_asset_value = app.data.driver.db.net_asset_value.find_one({'$and': [{"_deleted": False}, {"portfolios": portfolio_id}, {"trade_date": {'$gte': Tools.date_to_datetime(start), '$lt': Tools.date_to_datetime(end)}}]})
        if net_asset_value is None:
            return
        p_dict = {}
        p_dict["cal_date"] = today
        p_dict["portfolio_risk_money"] = ExcleFuc.sumif('risk_manager', {'$and': [{"_deleted": False}, {"portfolios": portfolio_id}, {"is_hold": True}]}, 'buy_dp', 'risk_cost_money')
        p_dict["portfolio_market_value"] = net_asset_value['portfolio_market_value']
        p_dict["portfolio_risk_ratio"] = p_dict["portfolio_risk_money"] / p_dict["portfolio_market_value"]
        p_dict["portfolio_floating_profit_loss"] = ExcleFuc.sumif('risk_manager', {'$and': [{"_deleted": False}, {"portfolios": portfolio_id}, {"is_hold": False}]}, 'buy_sale_dp', 'trade_profit') + ExcleFuc.sumif('position', {'$and': [{"_deleted": False}, {"portfolios": portfolio_id}]},'profit_or_loss')
        p_dict["portfolio_win_ratio"] = Portfolio.cal_win_ratio(portfolio_id)
        p_dict["portfolio_profit_loss_ratio"] = Portfolio.cal_profit_loss_ratio(portfolio_id)
        p_dict["portfolio_current_net"] = net_asset_value['portfolio_net_value']
        p_dict["portfolio_current_amount"] = net_asset_value['portfolio_net_amount']
        p_dict["portfolio_return_ratio"] = p_dict["portfolio_current_net"] - 1
        if (today.replace(tzinfo=pytz.UTC) - portfolio[0]["portfolio_created_date"].astimezone(pytz.UTC)).days == 0:
            p_dict["portfolio_return_ratio_year"] = 0
        else:
            p_dict["portfolio_return_ratio_year"] = p_dict["portfolio_return_ratio"] / (today.replace(tzinfo=pytz.UTC) - portfolio[0]["portfolio_created_date"].astimezone(pytz.UTC)).days * 365
        p_dict["portfolio_position"] = ExcleFuc.sumif('position', {'$and': [{"_deleted": False}, {"portfolios": portfolio_id}]}, 'market_value') / p_dict["portfolio_market_value"]
        p_dict["portfolio_current_date"] = today
        mm, mn = Portfolio.get_net_month_value(portfolio_id)
        p_dict["portfolio_begin_month_money"] = mm
        p_dict["portfolio_begin_month_net"] = mn
        p_dict["portfolio_profit_loss_month_ratio"] = (p_dict["portfolio_current_net"] - p_dict["portfolio_begin_month_net"]) / p_dict["portfolio_begin_month_net"]
        p_dict["portfolio_retreat_range"] = net_asset_value['portfolio_net_retreat_change']
        p_dict["portfolio_trade_total_count"] = risks.count()
        if p_dict["portfolio_trade_total_count"] == 0:
            p_dict["portfolio_average_position_day"] = 0
        else:
            p_dict["portfolio_average_position_day"] = round(float(ExcleFuc.sumif('risk_manager', {'$and': [{"_deleted": False}, {"portfolios": portfolio_id}, {"is_hold": False}]}, 'buy_sale_dp', 'hold_trade_day') / p_dict["portfolio_trade_total_count"]), 0)
        day, n_range = Portfolio.get_retreat(portfolio_id)
        p_dict["portfolio_biggest_retreat_day"] = day
        p_dict["portfolio_biggest_retreat_range"] = n_range
        p_dict["portfolio_trade_total_day"] = len(pd.bdate_range(portfolio[0]["portfolio_created_date"], today))
        if p_dict["portfolio_trade_total_day"] == 0:
            p_dict["portfolio_trade_count_ratio"] = 0
        else:
            p_dict["portfolio_trade_count_ratio"] = p_dict["portfolio_trade_total_count"] / p_dict["portfolio_trade_total_day"]
        if p_dict["portfolio_trade_count_ratio"] >= 1:
            p_dict["portfolio_trade_style"] = "1"
        elif p_dict["portfolio_trade_count_ratio"] >= 0.5:
            p_dict["portfolio_trade_style"] = "2"
        elif p_dict["portfolio_trade_count_ratio"] >= 0.1:
            p_dict["portfolio_trade_style"] = "3"
        else:
            p_dict["portfolio_trade_style"] = "4"

        lookup = {'_id': portfolio_id}
        patch_internal('portfolios', p_dict, concurrency_check=False, **lookup)


class RiskManager(object):
    @staticmethod
    def update_risk(portfolio_id):
        risks = app.data.driver.db.risk_manager.find({'$and': [{"_deleted": False}, {"is_hold": True}, {"portfolios": portfolio_id}]})
        if risks.count() > 0:
            for risk in risks:
                amount = risk["buy"]["amount"]
                stock_dict = Stock.get_stock_realtime_data(risk["buy"]["code"])
                risk["buy_dp"]["price"] = float(stock_dict["price"])
                risk["buy_dp"]["market_value"] = risk["buy_dp"]["price"]*amount
                risk["buy_dp"]["position_ratio"] = risk["buy_dp"]["market_value"] / risk["buy_dp"]["risk_all_money"]
                if risk["buy_dp"]["price"] < risk["buy"]["stop_price"]:
                    risk["buy_dp"]["is_should_sale"] = True
                else:
                    risk["buy_dp"]["is_should_sale"] = False
                risk["buy_dp"]["floating_profit_loss"] = (float(stock_dict["price"]) - risk["buy"]["trade_buy_price"]) * amount
                risk["buy_dp"]["floating_profit_loss_ratio"] = risk["buy_dp"]["floating_profit_loss"] / (risk["buy_dp"]["cost_price"]*amount)

                update_risk = copy.deepcopy(risk)
                if update_risk.has_key("_created"):
                    update_risk.pop("_created")
                if update_risk.has_key("_deleted"):
                    update_risk.pop("_deleted")
                if update_risk.has_key("_etag"):
                    update_risk.pop("_etag")
                if update_risk.has_key("_updated"):
                    update_risk.pop("_updated")
                if update_risk.has_key("_id"):
                    update_risk.pop("_id")
                update_risk["is_event"] = False
                lookup = {'_id': risk["_id"]}
                patch_internal('risk_manager', update_risk, concurrency_check=False, **lookup)

    @staticmethod
    def buy(items):
        """
        Initial buy info
        :param items:
        :return:
        """
        code = items[0]["buy"]["code"]
        amount = items[0]["buy"]["amount"]
        buy_price = items[0]["buy"]["trade_buy_price"]
        buy_money = buy_price*amount
        stop_price = items[0]["buy"]["stop_price"]
        trade_date = items[0]["buy"]["trade_buy_date"]
        target_price = items[0]["buy"]["target_price"]
        stock_dict = Stock.get_stock_data(code, trade_date)
        buy_dp = {}
        buy_dp["name"] = stock_dict["name"]
        buy_dp["price"] = float(stock_dict["price"])
        buy_dp["market_value"] = buy_dp["price"]*amount
        buy_dp["risk_all_money"] = RiskManager.get_risk_all_money(trade_date.date(), items[0]["portfolios"])
        buy_dp["position_ratio"] = buy_dp["market_value"] / buy_dp["risk_all_money"]
        buy_dp["is_should_sale"] = False
        buy_dp["buy_fee_cost"] = RiskManager.cal_buy_fee(code, buy_money)
        buy_dp["cost_price"] = (buy_money + buy_dp["buy_fee_cost"]) / amount
        buy_dp["floating_profit_loss"] = (float(stock_dict["price"]) - buy_price) * amount
        buy_dp["floating_profit_loss_ratio"] = buy_dp["floating_profit_loss"] / (buy_dp["cost_price"]*amount)
        buy_dp["risk_cost_money"] = (buy_dp["cost_price"] - stop_price) * amount
        buy_dp["target_profit"] = (target_price - buy_dp["cost_price"]) * amount
        if buy_dp["cost_price"] != stop_price:
            buy_dp["up_buy_amount"] = 0.02*buy_dp["risk_all_money"] / (buy_dp["cost_price"] - stop_price)
        else:
            buy_dp["up_buy_amount"] = 0
        buy_dp["stop_ratio"] = (buy_dp["cost_price"] - stop_price) / buy_dp["cost_price"]
        if buy_dp["cost_price"] != stop_price:
            buy_dp["risk_reward_ratio"] = (target_price - buy_dp["cost_price"]) / (buy_dp["cost_price"] - stop_price)
        else:
            buy_dp["risk_reward_ratio"] = 0
        buy_dp["trade_buy_high_price"] = float(stock_dict["high"])
        buy_dp["trade_buy_low_price"] = float(stock_dict["low"])
        if float(stock_dict["high"]) != float(stock_dict["low"]):
            buy_dp["trade_buy_score"] = (float(stock_dict["high"]) - buy_price) / (float(stock_dict["high"]) - float(stock_dict["low"]))
        else:
            buy_dp["trade_buy_score"] = 0
        items[0]["is_hold"] = True
        items[0]["buy_dp"] = buy_dp

    @staticmethod
    def update_buy(updates):
        """
        Update buy info and buy_dp
        :param updates:
        :return:
        """
        code = updates["buy"]["code"]
        amount = updates["buy"]["amount"]
        buy_price = updates["buy"]["trade_buy_price"]
        buy_money = buy_price*amount
        stop_price = updates["buy"]["stop_price"]
        trade_date = updates["buy"]["trade_buy_date"]
        target_price = updates["buy"]["target_price"]
        stock_dict = Stock.get_stock_data(code, trade_date)
        buy_dp = {}
        buy_dp["name"] = stock_dict["name"]
        buy_dp["price"] = float(stock_dict["price"])
        buy_dp["market_value"] = buy_dp["price"]*amount
        buy_dp["risk_all_money"] = RiskManager.get_risk_all_money(trade_date.date(), updates["portfolios"])
        buy_dp["position_ratio"] = buy_dp["market_value"] / buy_dp["risk_all_money"]
        buy_dp["is_should_sale"] = False
        buy_dp["buy_fee_cost"] = RiskManager.cal_buy_fee(code, buy_money)
        buy_dp["cost_price"] = (buy_money + buy_dp["buy_fee_cost"]) / amount
        buy_dp["floating_profit_loss"] = (float(stock_dict["price"]) - buy_price) * amount
        buy_dp["floating_profit_loss_ratio"] = buy_dp["floating_profit_loss"] / (buy_dp["cost_price"]*amount)
        buy_dp["risk_cost_money"] = (buy_dp["cost_price"] - stop_price) * amount
        buy_dp["target_profit"] = (target_price - buy_dp["cost_price"]) * amount
        if buy_dp["cost_price"] != stop_price:
            buy_dp["up_buy_amount"] = 0.02*buy_dp["risk_all_money"] / (buy_dp["cost_price"] - stop_price)
        else:
            buy_dp["up_buy_amount"] = 0
        buy_dp["stop_ratio"] = (buy_dp["cost_price"] - stop_price) / buy_dp["cost_price"]
        if buy_dp["cost_price"] != stop_price:
            buy_dp["risk_reward_ratio"] = (target_price - buy_dp["cost_price"]) / (buy_dp["cost_price"] - stop_price)
        else:
            buy_dp["risk_reward_ratio"] = 0
        buy_dp["trade_buy_high_price"] = float(stock_dict["high"])
        buy_dp["trade_buy_low_price"] = float(stock_dict["low"])
        if float(stock_dict["high"]) != float(stock_dict["low"]):
            buy_dp["trade_buy_score"] = (float(stock_dict["high"]) - buy_price) / (float(stock_dict["high"]) - float(stock_dict["low"]))
        else:
            buy_dp["trade_buy_score"] = 0
        updates["buy_dp"] = buy_dp

    @staticmethod
    def sale(original, updates):
        """
        Sale field MUST use update method to insert the risk manager field
        :param original, updates:
        :return:
        """
        code = original["buy"]["code"]
        sale_price = updates["sale"]["trade_sale_price"]
        buy_price = original["buy"]["trade_buy_price"]
        trade_buy_date = original["buy"]["trade_buy_date"]
        trade_sale_date = updates["sale"]["trade_sale_date"]
        amount = original["buy"]["amount"]
        sale_money = sale_price * amount
        stock_dict = Stock.get_stock_data(code, trade_sale_date)
        buy_sale_dp = {}
        buy_sale_dp["trade_sale_high_price"] = float(stock_dict["high"])
        buy_sale_dp["trade_sale_low_price"] = float(stock_dict["low"])
        buy_sale_dp["sale_fee_cost"] = RiskManager.cal_sale_fee(code, sale_money)
        buy_sale_dp["hold_trade_day"] = len(pd.bdate_range(trade_buy_date, trade_sale_date))
        buy_sale_dp["trade_profit"] = amount*(sale_price - buy_price) - buy_sale_dp["sale_fee_cost"] - original["buy_dp"]["buy_fee_cost"]
        buy_sale_dp["trade_profit_ratio"] = buy_sale_dp["trade_profit"] / (amount*original["buy_dp"]["cost_price"])
        if float(stock_dict["high"]) != float(stock_dict["low"]):
            buy_sale_dp["trade_sale_score"] = (sale_price - float(stock_dict["low"])) / (float(stock_dict["high"]) - float(stock_dict["low"]))
        else:
            buy_sale_dp["trade_sale_score"] = 0
        buy_sale_dp["trade_score"] = buy_sale_dp["trade_profit"] / original["buy_dp"]["target_profit"]
        updates["is_hold"] = False
        updates["buy_sale_dp"] = buy_sale_dp

    @staticmethod
    def update_buy_sale_dp_by_buy(original, buy_updates):
        """
        Sale field MUST use update method to insert the risk manager field
        :param items:
        :return:
        """
        code = buy_updates["buy"]["code"]
        sale_price = original["sale"]["trade_sale_price"]
        buy_price = buy_updates["buy"]["trade_buy_price"]
        trade_buy_date = buy_updates["buy"]["trade_buy_date"].replace(tzinfo=pytz.UTC) # Convert time zone to UTC
        trade_sale_date = original["sale"]["trade_sale_date"].astimezone(pytz.UTC)
        amount = buy_updates["buy"]["amount"]
        sale_money = sale_price * amount
        stock_dict = Stock.get_stock_data(code, trade_sale_date)
        buy_sale_dp = {}
        buy_sale_dp["trade_sale_high_price"] = float(stock_dict["high"])
        buy_sale_dp["trade_sale_low_price"] = float(stock_dict["low"])
        buy_sale_dp["sale_fee_cost"] = RiskManager.cal_sale_fee(code, sale_money)
        buy_sale_dp["hold_trade_day"] = len(pd.bdate_range(trade_buy_date, trade_sale_date))
        buy_sale_dp["trade_profit"] = amount*(sale_price - buy_price) - buy_sale_dp["sale_fee_cost"] - buy_updates["buy_dp"]["buy_fee_cost"]
        buy_sale_dp["trade_profit_ratio"] = buy_sale_dp["trade_profit"] / (amount*buy_updates["buy_dp"]["cost_price"])
        if float(stock_dict["high"]) != float(stock_dict["low"]):
            buy_sale_dp["trade_sale_score"] = (sale_price - float(stock_dict["low"])) / (float(stock_dict["high"]) - float(stock_dict["low"]))
        else:
            buy_sale_dp["trade_sale_score"] = 0
        buy_sale_dp["trade_score"] = buy_sale_dp["trade_profit"] / buy_updates["buy_dp"]["target_profit"]
        buy_updates["buy_sale_dp"] = buy_sale_dp

    @staticmethod
    def is_should_sale(code, stop_price):
        """
        Check whether stock is should sale or not
        :return:
        """
        stock_dict = Stock.get_stock_realtime_data(code)
        if float(stock_dict["price"]) < stop_price:
            return True
        else:
            return False

    @staticmethod
    def cal_buy_fee(code, buy_money):
        """
        Calculate trade buy fee cost.
        ETF trade fee less than 5 Yuan is calculated actually.
        Stock trade fee less than 5 Yuan is calculated 5 Yuan.
        Trade ratio is 0.0003
        Transfer fee(Only ShangHai Stock) is 0.00002
        Tax fee is 0.001
        :param code:
        :param buy_money:
        :return:
        """
        TRADE_RATIO = 0.0003
        TRANSFER_RATIO = 0.00002
        if code[0] == '5' or code[0] == '1':
            buy_fee = buy_money*TRADE_RATIO
        else:
            if buy_money*TRADE_RATIO <= 5:
                buy_fee = 5
            else:
                buy_fee = buy_money*TRADE_RATIO
        if code[0] == '6':
            buy_fee += buy_money*TRANSFER_RATIO
        return buy_fee

    @staticmethod
    def cal_sale_fee(code, sale_money):
        """
        Calculate trade sale fee cost.
        ETF trade fee less than 5 Yuan is calculated actually.
        Stock trade fee less than 5 Yuan is calculated 5 Yuan.
        Trade ratio is 0.0003
        Transfer fee(Only ShangHai Stock) is 0.00002
        Tax fee is 0.001
        :param code:
        :param sale_money:
        :return:
        """
        TAX_RATIO = 0.001
        TRADE_RATIO = 0.0003
        TRANSFER_RATIO = 0.00002
        if code[0] == '5' or code[0] == '1':
            sale_fee = sale_money*TRADE_RATIO
        else:
            if sale_money*TRADE_RATIO <= 5:
                sale_fee = 5
            else:
                sale_fee = sale_money*TRADE_RATIO
        if code[0] == '6':
            sale_fee += sale_money*(TRANSFER_RATIO + TAX_RATIO)
        elif code[0] == '5' or code[0] == '1':
            pass
        else:
            sale_fee += sale_money*TAX_RATIO
        return sale_fee

    @staticmethod
    def get_risk_all_money(trade_date, portfolio_id):
        """
        Get Risk_All_Money from net_asset_value collection
        :param trade_date:
        :param portfolio_id:
        :return:
        """
        start = trade_date + timedelta(-1)
        end = trade_date + timedelta(+1)
        lookup_dict = {'$and': [{"_deleted": False}, {"trade_date": {'$gte': Tools.date_to_datetime(start), '$lt': Tools.date_to_datetime(end)}}, {"portfolios": portfolio_id}]}
        data = ExcleFuc.vlookup("net_asset_value", lookup_dict, "portfolio_market_value")
        if data is None:
            data = app.data.driver.db.net_asset_value.find({'$and': [{"_deleted": False}, {"portfolios": portfolio_id}]}).sort('_updated', pymongo.DESCENDING).limit(1)[0]["portfolio_market_value"]
        return data

    @staticmethod
    def update_buy_dp(original, updates):
        """
        Update buy_dp, if the key is buy then update the buy items and check whether db has
        the buy_sale_dp or not, if it has then it need update the buy_sale_dp
        :param original, updates:
        :return:
        """
        RiskManager.update_buy(updates)
        RiskManager.update_buy_sale_dp(original, updates)

    @staticmethod
    def update_buy_sale_dp(original, updates):
        """
        Update buy_sale_dp if risk_manger collection has the field,
        if not it will ignore
        :param original, updates:
        :return:
        """
        if original.has_key("buy_sale_dp"):
            RiskManager.update_buy_sale_dp_by_buy(original, updates)

    @staticmethod
    def get_risk_manager(id):
        """
        Get risk manager document by the ID
        :param id:
        :return:
        """
        return app.data.driver.db.risk_manager.find_one({"_id": id})


class CashFlow(object):
    @staticmethod
    def init_cash(portfolio_id, user_id, initial_money):
        # wrap a cash_history dict to post_internal
        today = datetime.today()
        cash_dict = {'portfolios': portfolio_id, '__user_id__': user_id, 'transfer_money': initial_money,
                     'transfer_date': today, 'portfolio_net': 1}
        post_internal('cashflow_history', cash_dict)


class TradeHistory(object):
    @staticmethod
    def add_buy(risk_id, items):
        """
        Add trade history, ```buy_or_sale = True``` mean buy.
        :param dict:
        :param buy_or_sale:
        :return:
        """
        dict = {"__user_id__": items[0]["__user_id__"], "portfolios": items[0]["portfolios"],
                "code": items[0]["buy"]["code"], "name": items[0]["buy_dp"]["name"], "buy_or_sale": True,
                "trade_amount": items[0]["buy"]["amount"], "risk_id": risk_id,
                "trade_date": items[0]["buy"]["trade_buy_date"], "trade_price": items[0]["buy"]["trade_buy_price"],
                "trade_cost": items[0]["buy_dp"]["buy_fee_cost"],
                "trade_money": -items[0]["buy"]["amount"] * items[0]["buy"]["trade_buy_price"]}
        post_internal('trade_history', dict)

    @staticmethod
    def update_buy(original, updates):
        """
        When risk manager update buy it also need update trade_history collection
        :param updates:
        :param original:
        :return:
        """
        buy_dict = {"__user_id__": original["__user_id__"], "portfolios": original["portfolios"],
                "code": updates["buy"]["code"], "name": updates["buy_dp"]["name"], "buy_or_sale": True,
                "trade_amount": updates["buy"]["amount"], "risk_id": original["_id"],
                "trade_date": updates["buy"]["trade_buy_date"], "trade_price": updates["buy"]["trade_buy_price"],
                "trade_cost": updates["buy_dp"]["buy_fee_cost"],
                "trade_money": -updates["buy"]["amount"] * updates["buy"]["trade_buy_price"]}
        lookup = {'$and': [{"risk_id": original["_id"]}, {"buy_or_sale": True}]}
        patch_internal('trade_history', buy_dict, concurrency_check=False, **lookup)
        # Update sale trade history
        sale_dict = {"__user_id__": original["__user_id__"], "portfolios": original["portfolios"],
                "code": updates["buy"]["code"], "name": updates["buy_dp"]["name"], "buy_or_sale": False,
                "trade_amount": -updates["buy"]["amount"], "risk_id": original["_id"],
                "trade_date": original["sale"]["trade_sale_date"], "trade_price": original["sale"]["trade_sale_price"],
                "trade_cost": original["buy_sale_dp"]["sale_fee_cost"],
                "trade_money": updates["buy"]["amount"] * original["sale"]["trade_sale_price"]}
        lookup = {'$and': [{"risk_id": original["_id"]}, {"buy_or_sale": False}]}
        patch_internal('trade_history', sale_dict, concurrency_check=False, **lookup)

    @staticmethod
    def add_sale(original, updates):
        """
        Add trade history, ```buy_or_sale = True``` mean buy.
        :param dict:
        :param buy_or_sale:
        :return:
        """
        dict = {"__user_id__": original["__user_id__"], "portfolios": original["portfolios"],
                "code": original["buy"]["code"], "name": original["buy_dp"]["name"], "buy_or_sale": False,
                "trade_amount": -original["buy"]["amount"], "risk_id": original["_id"],
                "trade_date": updates["sale"]["trade_sale_date"], "trade_price": updates["sale"]["trade_sale_price"],
                "trade_cost": updates["buy_sale_dp"]["sale_fee_cost"],
                "trade_money": original["buy"]["amount"] * updates["sale"]["trade_sale_price"]}
        post_internal('trade_history', dict)

    @staticmethod
    def update_sale(original, updates):
        """
        When risk manager update sale it also need update trade_history collection
        :param updates:
        :param original:
        :return:
        """
        dict = {"__user_id__": original["__user_id__"], "portfolios": original["portfolios"],
                "code": original["buy"]["code"], "name": original["buy_dp"]["name"], "buy_or_sale": False,
                "trade_amount": -original["buy"]["amount"], "risk_id": original["_id"],
                "trade_date": updates["sale"]["trade_sale_date"], "trade_price": updates["sale"]["trade_sale_price"],
                "trade_cost": updates["buy_sale_dp"]["sale_fee_cost"],
                "trade_money": original["buy"]["amount"] * updates["sale"]["trade_sale_price"]}
        lookup = {'$and': [{"risk_id": original["_id"]}, {"buy_or_sale": False}]}
        patch_internal('trade_history', dict, concurrency_check=False, **lookup)

    @staticmethod
    def remove(risk_id):
        """
        Remove trade_history by risk_id
        :param risk_id:
        :return:
        """
        # Delete buy trade if it exists
        buy_lookup = {'$and': [{"risk_id": risk_id}, {"buy_or_sale": True}]}
        buy_original = get_document('trade_history', concurrency_check=False, **buy_lookup)
        if buy_original and buy_original.get('_deleted') is False:
            deleteitem_internal('trade_history', concurrency_check=False, **buy_original)
        # Delete sale trade if it exists
        sale_lookup = {'$and': [{"risk_id": risk_id}, {"buy_or_sale": False}]}
        sale_original = get_document('trade_history', concurrency_check=False, **sale_lookup)
        if sale_original and sale_original.get('_deleted') is False:
            deleteitem_internal('trade_history', concurrency_check=False, **sale_original)


class Possition(object):
    @staticmethod
    def update_possition(portfolio_id):
        positions = app.data.driver.db.position.find({'$and': [{"_deleted": False}, {"portfolios": portfolio_id}]})
        if positions.count() > 0:
            for position in positions:
                amount = position["amount"]
                stock_dict = Stock.get_stock_realtime_data(position["code"])
                position["price"] = float(stock_dict["price"])
                position["market_value"] = position["price"]*amount
                if position["price"] < position["stop_price"]:
                    position["is_should_sale"] = True
                else:
                    position["is_should_sale"] = False
                position["floating_profit_loss"] = (float(stock_dict["price"]) - position["cost_price"]) * amount
                position["floating_profit_loss_ratio"] = position["floating_profit_loss"] / (position["cost_price"]*amount)

                update_position = copy.deepcopy(position)
                if update_position.has_key("_created"):
                    update_position.pop("_created")
                if update_position.has_key("_deleted"):
                    update_position.pop("_deleted")
                if update_position.has_key("_etag"):
                    update_position.pop("_etag")
                if update_position.has_key("_updated"):
                    update_position.pop("_updated")
                if update_position.has_key("_id"):
                    update_position.pop("_id")

                lookup = {'_id': position["_id"]}
                patch_internal('position', update_position, concurrency_check=False, **lookup)

    @staticmethod
    def add(risk_id, items):
        """
        Add possition when risk manager has a buy action
        :param risk_id:
        :param items:
        :return:
        """
        possition = {
            "risk_id": risk_id,
            "__user_id__": items[0]["__user_id__"],
            "portfolios": items[0]["portfolios"],
            "code": items[0]["buy"]["code"],
            "name": items[0]["buy_dp"]["name"],
            "price": items[0]["buy_dp"]["price"],
            "stop_price": items[0]["buy"]["stop_price"],
            "market_value": items[0]["buy_dp"]["market_value"],
            "cost_price": items[0]["buy_dp"]["cost_price"],
            "amount": items[0]["buy"]["amount"],
            "profit_or_loss": items[0]["buy_dp"]["floating_profit_loss"],
            "profit_or_loss_ratio": items[0]["buy_dp"]["floating_profit_loss_ratio"],
            "is_should_sale": items[0]["buy_dp"]["is_should_sale"],
            "position_ratio": items[0]["buy_dp"]["position_ratio"],
        }
        post_internal('position', possition)

    @staticmethod
    def remove(risk_id):
        """
        Remove possition by risk id
        :param risk_id:
        :return:
        """
        lookup = {"risk_id": risk_id}
        original = get_document('position', concurrency_check=False, **lookup)
        if original and original.get('_deleted') is False:
            deleteitem_internal('position', concurrency_check=False, **lookup)

    @staticmethod
    def update(original, updates):
        """
        Update possiton when update risk buy field and the stock is holding
        :param original:
        :param updates:
        :return:
        """
        dict = {
            "code": updates["buy"]["code"],
            "name": updates["buy_dp"]["name"],
            "price": updates["buy_dp"]["price"],
            "stop_price": updates["buy"]["stop_price"],
            "cost_price": updates["buy_dp"]["cost_price"],
            "market_value": updates["buy_dp"]["market_value"],
            "amount": updates["buy"]["amount"],
            "profit_or_loss": updates["buy_dp"]["floating_profit_loss"],
            "profit_or_loss_ratio": updates["buy_dp"]["floating_profit_loss_ratio"],
            "is_should_sale": updates["buy_dp"]["is_should_sale"],
            "position_ratio": updates["buy_dp"]["position_ratio"],
        }
        patch_internal('position', dict, {"risk_id": original["_id"]})

    @staticmethod
    def convert_trade_to_position(trade):
        """
        Convert trade history to position history
        :param trade:
        :return:
        """
        ph_dict = {}
        ph_dict["__user_id__"] = trade["__user_id__"]
        ph_dict["portfolios"] = trade["portfolios"]
        ph_dict["trade_date"] = trade["trade_date"]
        ph_dict["code"] = trade["code"]
        ph_dict["name"] = trade["name"]
        ph_dict["position_amount"] = float(trade["trade_amount"])
        ph_dict["close_price"] = float(Stock.get_stock_data(trade["code"], trade["trade_date"])["close"])
        ph_dict["market_value"] = float(ph_dict["close_price"]*ph_dict["position_amount"])
        return ph_dict

    @staticmethod
    def group_trade_list(trade_list):
        """
        Group list by trade item code
        :param trade_list:
        :return:
        """
        group_list = []
        dict = {}
        for item in trade_list:
            if not dict.has_key(item["code"]):
                dict[item["code"]] = item
            else:
                dict[item["code"]]["trade_amount"] += item["trade_amount"]
                if dict[item["code"]]["trade_amount"] == 0:
                    dict.pop(item["code"])
        for k, v in dict.iteritems():
            group_list.append(v)
        return group_list

    @staticmethod
    def position_history(portfolio_id, start_date=None):
        """
        Make position history by trade history collection
        :param portfolio_id:
        :param start_date: if it is set then use it to make position history
        :return:
        """
        trades = app.data.driver.db.trade_history.find({'$and': [{"_deleted": False}, {"portfolios": portfolio_id}]}).sort('trade_date', pymongo.ASCENDING)
        positions = app.data.driver.db.position_history.find({'$and': [{"_deleted": False}, {"portfolios": portfolio_id}]}).sort('trade_date', pymongo.DESCENDING)
        if trades.count() == 0:
            return
        trades_dict = {}
        positions_dict = {}
        positions_list = []
        today = datetime.today()
        if today.hour < 20:
            today = datetime.today() + timedelta(-1)
        trade_day = trades[0]["trade_date"]
        position_day = None
        if positions.count() > 0:
            p_d = positions[0]["trade_date"]
            position_day = p_d + timedelta(1)
            if not positions_dict.has_key(str(p_d.date())):
                positions_dict[str(p_d.date())] = []
            for position in positions:
                if position["trade_date"].date() == p_d.date():
                    positions_dict[str(p_d.date())].append(position)
                else:
                    break
        if start_date is None:
            start_date = trade_day
            if position_day is not None:
                start_date = position_day
        elif start_date.date() < trade_day.date():
            start_date = trade_day
        if start_date.date() > today.date():
            return
        if len(pd.bdate_range(start_date.date(), today.date())) == 0:
            return
        # Delete exists rows
        if position_day is not None:
            if start_date.date() < position_day.date():
                start = start_date.date() + timedelta(-1)
                app.data.driver.db.position_history.delete_many({'$and': [{"portfolios": portfolio_id}, {"trade_date": {'$gte': Tools.date_to_datetime(start)}}]})
        date = trades[0]["trade_date"].date()
        for trade in trades:
            if date == trade["trade_date"].date():
                if not trades_dict.has_key(str(date)):
                    trades_dict[str(date)] = []
                trades_dict[str(date)].append(trade)
            else:
                date = trade["trade_date"].date()
                if not trades_dict.has_key(str(date)):
                    trades_dict[str(date)] = []
                trades_dict[str(date)].append(trade)

        for bday in pd.bdate_range(start_date.date(), today.date()):
            if not positions_dict.has_key(str((bday - BDay(1)).date())):
                if not positions_dict:
                    if not positions_dict.has_key(str(bday.date())):
                        positions_dict[str(bday.date())] = []
                    trade_list = trades_dict[str(bday.date())]
                    trade_list = Possition.group_trade_list(trade_list)
                    for item in trade_list:
                        positions_dict[str(bday.date())].append(Possition.convert_trade_to_position(item))
                else:
                    # deepcopy to modify position_list value
                    position_list = copy.deepcopy(positions_dict[str((bday.date() - BDay(1)).date())])
                    if not positions_dict.has_key(str(bday.date())):
                            positions_dict[str(bday.date())] = []
                    if trades_dict.has_key(str(bday.date())):
                        trade_list = copy.deepcopy(trades_dict[str(bday.date())])
                        trade_list = Possition.group_trade_list(trade_list)
                        for trade_item in trade_list:
                            check = False
                            for position_item in position_list:
                                if position_item["code"] == trade_item["code"]:
                                    check = True
                                    position_item["position_amount"] += trade_item["trade_amount"]
                                    if position_item["position_amount"] != 0:
                                        position_item["trade_date"] = bday
                                        position_item["close_price"] = float(Stock.get_stock_data(trade_item["code"], bday)["close"])
                                        position_item["market_value"] = float(position_item["close_price"]*position_item["position_amount"])
                                        positions_dict[str(bday.date())].append(position_item)
                            if not check:
                                positions_dict[str(bday.date())].append(Possition.convert_trade_to_position(trade_item))
                        for item in position_list:
                            check = True
                            for pd_item in positions_dict[str(bday.date())]:
                                if pd_item["code"] == item["code"]:
                                    check = False
                            if check:
                                item["trade_date"] = bday
                                item["close_price"] = float(Stock.get_stock_data(item["code"], bday)["close"])
                                item["market_value"] = float(item["close_price"]*item["position_amount"])
                                positions_dict[str(bday.date())].append(item)
                    else:
                        for item in position_list:
                            item["trade_date"] = bday
                            item["close_price"] = float(Stock.get_stock_data(item["code"], bday)["close"])
                            item["market_value"] = float(item["close_price"]*item["position_amount"])
                            positions_dict[str(bday.date())].append(item)
            else:
                # deepcopy to modify position_list value
                position_list = copy.deepcopy(positions_dict[str((bday.date() - BDay(1)).date())])
                if not positions_dict.has_key(str(bday.date())):
                        positions_dict[str(bday.date())] = []
                if trades_dict.has_key(str(bday.date())):
                    trade_list = copy.deepcopy(trades_dict[str(bday.date())])
                    trade_list = Possition.group_trade_list(trade_list)
                    for trade_item in trade_list:
                        check = False
                        for position_item in position_list:
                            if position_item["code"] == trade_item["code"]:
                                check = True
                                position_item["position_amount"] += trade_item["trade_amount"]
                                if position_item["position_amount"] != 0:
                                    position_item["trade_date"] = bday
                                    position_item["close_price"] = float(Stock.get_stock_data(trade_item["code"], bday)["close"])
                                    position_item["market_value"] = float(position_item["close_price"]*position_item["position_amount"])
                                    positions_dict[str(bday.date())].append(position_item)
                        if not check:
                            positions_dict[str(bday.date())].append(Possition.convert_trade_to_position(trade_item))
                    for item in position_list:
                        check = True
                        for pd_item in positions_dict[str(bday.date())]:
                            if pd_item["code"] == item["code"]:
                                check = False
                        if check:
                            item["trade_date"] = bday
                            item["close_price"] = float(Stock.get_stock_data(item["code"], bday)["close"])
                            item["market_value"] = float(item["close_price"]*item["position_amount"])
                            positions_dict[str(bday.date())].append(item)
                else:
                    for item in position_list:
                        item["trade_date"] = bday
                        item["close_price"] = float(Stock.get_stock_data(item["code"], bday)["close"])
                        item["market_value"] = float(item["close_price"]*item["position_amount"])
                        positions_dict[str(bday.date())].append(item)
        if positions.count() > 0:
            positions_dict.pop(str(p_d.date()))
        for k, v_list in positions_dict.iteritems():
            for i in v_list:
                if i.has_key("_created"):
                    i.pop("_created")
                if i.has_key("_deleted"):
                    i.pop("_deleted")
                if i.has_key("_etag"):
                    i.pop("_etag")
                if i.has_key("_id"):
                    i.pop("_id")
                if i.has_key("_updated"):
                    i.pop("_updated")
                positions_list.append(i)

        post_internal('position_history', positions_list)


class NetAssetValue(object):
    @staticmethod
    def init_net(portfolio_id, user_id, initial_money):
        today = datetime.today()
        # wrap a net_asset_value dict to post_internal
        net_dict = {"portfolios": portfolio_id, "__user_id__": user_id, "trade_date": today,
                    "portfolio_net_value": 1, "portfolio_net_amount": initial_money,
                    "portfolio_market_value": initial_money, "portfolio_position_value": 0,
                    "portfolio_avaliable_cash": initial_money, "portfolio_buy_cost": 0, "portfolio_cash_transfer": 0,
                    "portfolio_amount_change": 0, "portfolio_day_change": 0, "portfolio_net_retreat_change": 0,
                    "portfolio_net_retreat_day": 0, "zz500_index": Stock.get_zz500()["close"], "zz500_index_net": 1,
                    "hs300_index": Stock.get_hs300()["close"], "hs300_index_net": 1, "portfolio_trad_count": 0}
        post_internal('net_asset_value', net_dict)

    @staticmethod
    def update_net(portfolio_id, start_date=None):
        """
        Update Net Value day by day
        :param portfolio_id:
        :param start_date:
        :return:
        """
        net = app.data.driver.db.net_asset_value.find({'$and': [{"_deleted": False}, {"portfolios": portfolio_id}]}).sort('trade_date', pymongo.DESCENDING)
        if net.count() == 0:
            return
        today = datetime.today()
        if today.hour < 20:
            today = datetime.today() + timedelta(-1)
        start_net = copy.deepcopy(net[0])
        end_net = copy.deepcopy(net[net.count()-1])
        next_net = {}
        net_day = net[0]["trade_date"]
        if start_date is None:
            start_date = net[0]["trade_date"] + timedelta(1)
        if start_date.date() > today.date():
            return
        if len(pd.bdate_range(start_date.date(), today.date()).day) <= 0:
            return
        # Delete exists rows
        if start_date.date() <= net_day.date():
            start = start_date.date() + timedelta(-1)
            app.data.driver.db.net_asset_value.delete_many({'$and': [{"portfolios": portfolio_id}, {"trade_date": {'$gte': Tools.date_to_datetime(start)}}]})
        max_net = net[0]["portfolio_net_value"]
        for item in net:
            if max_net < item["portfolio_net_value"]:
                max_net = item["portfolio_net_value"]
        net_list = []
        for bday in pd.bdate_range(start_date.date(), today.date()):
            next_net["portfolios"] = start_net["portfolios"]
            next_net["__user_id__"] = start_net["__user_id__"]
            next_net["trade_date"] = bday
            start = bday.date() + timedelta(-1)
            end = bday.date() + timedelta(+1)
            trade_lookup = {'$and': [{"_deleted": False}, {"trade_date": {'$gte': Tools.date_to_datetime(start), '$lt': Tools.date_to_datetime(end)}}, {"portfolios": portfolio_id}]}
            next_net["portfolio_buy_cost"] = ExcleFuc.sumif('trade_history', trade_lookup, 'trade_money')
            next_net["portfolio_position_value"] = ExcleFuc.sumif('position_history', {'$and': [{"portfolios": portfolio_id}, {"trade_date": bday}]}, 'market_value')
            next_net["portfolio_net_amount"] = start_net["portfolio_net_amount"] + start_net["portfolio_amount_change"]
            next_net["portfolio_avaliable_cash"] = start_net["portfolio_avaliable_cash"] + start_net["portfolio_cash_transfer"] + next_net["portfolio_buy_cost"]
            next_net["portfolio_market_value"] = next_net["portfolio_position_value"] + next_net["portfolio_avaliable_cash"]
            next_net["portfolio_net_value"] = next_net["portfolio_market_value"] / next_net["portfolio_net_amount"]
            if max_net < next_net["portfolio_net_value"]:
                max_net = next_net["portfolio_net_value"]
            cash_lookup = {'$and': [{"_deleted": False}, {"transfer_date": {'$gte': Tools.date_to_datetime(start), '$lt': Tools.date_to_datetime(end)}}, {"portfolios": portfolio_id}]}
            next_net["portfolio_cash_transfer"] = ExcleFuc.sumif('cashflow_history', cash_lookup, 'transfer_money')
            next_net["portfolio_amount_change"] = next_net["portfolio_cash_transfer"] / next_net["portfolio_net_value"]
            next_net["portfolio_day_change"] = (next_net["portfolio_net_value"] - start_net["portfolio_net_value"]) / start_net["portfolio_net_value"]
            next_net["portfolio_net_retreat_change"] = (next_net["portfolio_net_value"] - max_net) / max_net
            if next_net["portfolio_net_retreat_change"] < 0 and start_net["portfolio_net_retreat_change"] == 0:
                next_net["portfolio_net_retreat_day"] = 1
            elif next_net["portfolio_net_retreat_change"] < 0 and start_net["portfolio_net_retreat_change"] < 0:
                next_net["portfolio_net_retreat_day"] = start_net["portfolio_net_retreat_change"] + 1
            else:
                next_net["portfolio_net_retreat_day"] = 0
            next_net["zz500_index"] = float(Stock.get_zz500_by_date(bday)["close"])
            next_net["zz500_index_net"] = next_net["zz500_index"] / float(end_net["zz500_index"])
            next_net["hs300_index"] = float(Stock.get_hs300_by_date(bday)["close"])
            next_net["hs300_index_net"] = next_net["hs300_index"] / float(end_net["hs300_index"])
            next_net["portfolio_trad_count"] = app.data.driver.db.trade_history.find(trade_lookup).count()

            start_net = copy.deepcopy(next_net)
            net_list.append(copy.deepcopy(next_net))

        post_internal('net_asset_value', net_list)


class Products(object):
    @staticmethod
    def buy_product(self):
        pass