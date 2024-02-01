from bson import ObjectId
from eve.io.base import BaseJSONEncoder
from eve.io.media import MediaStorage
# from cattle import Cattle
from flask import current_app as app
import tushare as ts
from datetime import datetime, timedelta, date
import json


class ObjectIdEncoder(BaseJSONEncoder):
    """ ObjectIdEncoder subclass used by the json render function.
    This is different from BaseJSONEoncoder since it also addresses
    encoding of ObjectId
    """

    def default(self, obj):
        if isinstance(obj, ObjectId):
            return str(obj)
        else:
            # delegate rendering to base class method (the base class
            # will properly render ObjectIds, datetimes, etc.)
            return super(ObjectIdEncoder, self).default(obj)


# class QiNiuMediaStorage(MediaStorage):
#     """
#     QiNiuMediaStorage subclass used by the media storage funciton which uses QiNiu Cloud Storage Service.
#     """
#     def __init__(self, app=None):
#         """
#         :param app: the flask application (eve itself). This can be used by
#         the class to access, amongst other things, the app.config object to
#         retrieve class-specific settings.
#         """
#         super(QiNiuMediaStorage, self).__init__(app)
#         # Config QiNiu Cloud Service
#         self.cattle = Cattle(app.config['QN_AK'], app.config['QN_SK'])
#         self.bucket = self.cattle.get_bucket(app.config['QN_BUCKET'])
#
#     def get(self, id_or_filename, resource=None):
#         pass
#
#     def put(self, content, filename=None, content_type=None, resource=None):
#         """
#         Storage file to QiNiu Cloud.
#         """
#         file_buffer = content.read()
#         result_dict = self.bucket.put_data(file_buffer, override=False)
#         if result_dict["key"]:
#             filename = result_dict["key"]
#             return filename
#         else:
#             return result_dict
#
#     def delete(self, id_or_filename, resource=None):
#         pass
#
#     def exists(self, id_or_filename, resource=None):
#         pass
#
#
# class QiNiuCloudStorage:
#     """
#     :param app: the flask application (eve itself). This can be used by
#     the class to access, amongst other things, the app.config object to
#     retrieve class-specific settings.
#     """
#     def __init__(self):
#         # Config QiNiu Cloud Service
#         self.cattle = Cattle(app.config['QN_AK'], app.config['QN_SK'])
#         self.bucket = self.cattle.get_bucket(app.config['QN_BUCKET'])
#
#     def put(self, data, filePath=None, content_type=None, resource=None):
#         """
#         Storage file to QiNiu Cloud.
#         """
#         file_buffer = data.read()
#         result_dict = self.bucket.put_data(file_buffer, override=False)
#         if result_dict["key"]:
#             filename = result_dict["key"]
#             return filename
#         else:
#             return result_dict


class Stock(object):
    @staticmethod
    def get_h_data(code, start=datetime.today().date(), end=datetime.today().date(), index=False):
        """
        Get stock history data, if date is none-trade-day,
        it fetch data by back a day until 8 times
        :param code:
        :param start:
        :param end:
        :param index:
        :return:
        """
        # Try 8 times to get market data
        count = 0
        while True:
            data = ts.get_h_data(code=code, start=str(start), end=str(end), index=index)
            if count > 7:
                break
            if data is not None:
                break
            count += 1
            start = start - timedelta(1)
        return data

    @staticmethod
    def get_zz500():
        """
        Get ZZ500 index
        :return:
        """
        zz500_data = Stock.get_h_data("399905", index=True)
        if zz500_data is not None:
            zz500_str = zz500_data.to_json(orient='records')
            zz500_list = json.loads(zz500_str)
            zz500_dict = zz500_list[0]
            return zz500_dict
        else:
            return {"close": "", "open": "", "high": "", "low": ""}

    @staticmethod
    def get_hs300():
        """
        Get HS300 index
        :return:
        """
        hs300_data = Stock.get_h_data('000300', index=True)
        if hs300_data is not None:
            hs300_str = hs300_data.to_json(orient='records')
            hs300_list = json.loads(hs300_str)
            hs300_dict = hs300_list[0]
            return hs300_dict
        else:
            return {"close": "", "open": "", "high": "", "low": ""}

    @staticmethod
    def get_hs300_by_date(date):
        """
        Get HS300 index
        :return:
        """
        hs300_data = Stock.get_etf_his_data('399300', date.date(), date.date())
        if hs300_data is not None:
            if hs300_data.has_key(str(date.date())):
                stock_dic = hs300_data[str(date.date())]
                return stock_dic
        return {"close": "0", "open": "0", "high": "0", "low": "0"}

    @staticmethod
    def get_zz500_by_date(date):
        """
        Get ZZ500 index
        :return:
        """
        zz500_data = Stock.get_etf_his_data('399905', date.date(), date.date())
        if zz500_data is not None:
            if zz500_data.has_key(str(date.date())):
                stock_dic = zz500_data[str(date.date())]
                return stock_dic
        return {"close": "0", "open": "0", "high": "0", "low": "0"}

    @staticmethod
    def is_trade_day():
        """
        Check whether the date is trade_day or not
        :return:
        """
        hs300 = Stock.get_hs300()
        if hs300:
            return True
        else:
            return False

    @staticmethod
    def get_etf_his_data(code, start, end):
        """
        Get ETF market data
        :param code:
        :param start:
        :param end:
        :return:
        """
        stock_data = ts.get_hist_data(code=code, start=str(start), end=str(end))
        if stock_data is not None:
            stock_str = stock_data.to_json(orient='index')
            stock_dic = json.loads(stock_str)
            return stock_dic

    @staticmethod
    def get_stock_his_data(code, start, end):
        """
        Get stock history market data
        :param code:
        :param start:
        :param end:
        :return:{date: {}}
        """
        stock_data = Stock.get_h_data(code=code, start=start, end=end)
        if stock_data is not None:
            stock_str = stock_data.to_json(orient='index')
            stock_dic = json.loads(stock_str)
            stock_dic_date = {}
            for k, v in stock_dic.iteritems():
                k = datetime.utcfromtimestamp(int(k)/1000).strftime('%Y-%m-%d')
                stock_dic_date[k] = v
            return stock_dic_date
        else:
            return {"close": "0", "open": "0", "high": "0", "low": "0", "amount": "0", "volume": "0"}

    @staticmethod
    def get_stock_realtime_data(code):
        """
        Get stock realtime market data
        :param code:
        :return:
        """
        stock_data = ts.get_realtime_quotes(code)
        stock_str = stock_data.to_json(orient='records')
        stock_list = json.loads(stock_str)
        stock_dict = stock_list[0]
        stock_dict["close"] = stock_dict["pre_close"]
        return stock_dict

    @staticmethod
    def get_stock_data(code, date):
        """
        Get Stock data by date
        :param code:
        :param date:
        :return:
        """
        if datetime.today().date() <= date.date():
            stock_dic = Stock.get_stock_realtime_data(code)
        else:
            if code[0] == '5' or code[0] == '1':
                stock_data = Stock.get_etf_his_data(code, date.date(), date.date())
            else:
                stock_data = Stock.get_stock_his_data(code, date.date(), date.date())
            if stock_data.has_key(str(date.date())):
                stock_dic = stock_data[str(date.date())]
            else:
                # Use get_stock_realtime_data() for the stock is in stopping market
                stock_dic = {}
            stock_realtime_data = Stock.get_stock_realtime_data(code)
            for k, v in stock_dic.iteritems():
                stock_realtime_data[k] = v
            stock_dic = stock_realtime_data
            if not stock_dic.has_key("close"):
                stock_dic["close"] = stock_dic["pre_close"]
        return stock_dic


class ExcleFuc(object):

    @staticmethod
    def vlookup(resource, lookup_list, v_out):
        """
        Like Excle vlookup function
        :param resource:
        :param lookup_list:
        :param v_out:
        :return:
        """
        document = app.data.driver.db[resource].find_one(lookup_list)
        if document:
            return document[v_out]

    @staticmethod
    def sumif(resource, lookup_list, column, sub_col=None):
        """
        Like Excle sumif function
        :param resource:
        :param lookup_list:
        :param column:
        :param sub_col:
        :return:
        """
        result = 0
        cursor = app.data.driver.db[resource].find(lookup_list)
        if cursor.count() > 0:
            for item in cursor:
                if sub_col is not None:
                    result += item[column][sub_col]
                else:
                    result += item[column]
        return result


class Tools(object):
    @staticmethod
    def date_to_datetime(date_to_convert):
        """
        Convert datetime.date to datetime.datetime
        :param date_to_convert:
        :return:
        """
        return datetime.combine(date_to_convert, datetime.min.time())




