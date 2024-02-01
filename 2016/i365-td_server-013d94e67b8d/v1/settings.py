# -*- coding: utf-8 -*-

# Config DEBUG
DEBUG = True

# Enable Log
OPLOG = True

# Config DB Name
MONGO_HOST = 'localhost'
MONGO_PORT = 27017
MONGO_DBNAME = 'i365'

# Config Client Manager Dashboard Secret
SENTINEL_MANAGEMENT_USERNAME = 'root'
SENTINEL_MANAGEMENT_PASSWORD = 'i365'

# Config Token Expires Time
OAUTH2_PROVIDER_TOKEN_EXPIRES_IN = 72000

# Enable reads (GET), inserts (POST) and DELETE for resources/collections
# (if you omit this line, the API will default to ['GET'] and provide
# read-only access to the endpoint).
RESOURCE_METHODS = ['GET', 'POST', 'DELETE']

# Enable reads (GET), edits (PUT/PATCH) and deletes of individual items
# (defaults to read-only item access).
ITEM_METHODS = ['GET', 'PUT', 'PATCH', 'DELETE']

# Name of the field used to store the owner of each document
AUTH_FIELD = '__user_id__'

# Config API version
API_VERSION = 'v1'

# Cache Control
CACHE_CONTROL = 'max-age=20'
CACHE_EXPIRES = 20

# Enable Embedding Resource
EMBEDDING = True

# Enable Soft Delete
SOFT_DELETE = True

# disable default behaviour
RETURN_MEDIA_AS_BASE64_STRING = False

# return media as URL instead
RETURN_MEDIA_AS_URL = True

# Config QiNiu Account
# QN_AK = '4UXsD-HtYCn_7ZsCVtM90n0pCq3jD5eRMndr5ZBX'
# QN_SK = 'OG-v757UsxMeZ3gLP5earfRErshs0hRWZoQiElnE'
# QN_BUCKET = 'improve365'

# set up the desired media endpoint
MEDIA_ENDPOINT = 'media'
EXTENDED_MEDIA_INFO = ['content_type', 'name', 'length']

# Enable Multipart-Form to Json
# MULTIPART_FORM_FIELDS_AS_JSON = True

users = {
    'item_title': 'users',

    'auth_field': '',

    # soft delete and projection cannot coexist
    'soft_delete': False,

    'public_methods': ['POST'],
    'resource_methods': ['POST'],
    'item_methods': ['GET', 'PATCH'],

    # excludes hashpw field to response
    'datasource': {
        'projection': {'hashpw': 0},
        # 'filter': {'username': {'$exists': True}}, # only expose and update documents with an existing username field.
    },

    # Clients using the URI Query Parameter method SHOULD also send a
    # Cache-Control header containing the "no-store" option. Server
    # success (2XX status) responses to these requests SHOULD contain a
    # Cache-Control header with the "private" option.
    'cache_control': '',
    'cache_expires': 0,

    'schema': {
        'username': {
            'type': 'string',
            'minlength': 1,
            'maxlength': 10,
            'required': True,
            'unique': True,
        },
        # 'role' is a list, and can only contain values from 'allowed'.
        'role': {
            'type': 'list',
            'allowed': ['user'],
        },
        'hashpw': {
            'type': 'string',
            'required': True,
        },
        'email': {
            'type': 'string',
            'regex': '^[a-zA-Z0-9_.+-]+@[a-zA-Z0-9-]+\.[a-zA-Z0-9-.]+$',
            'required': True,
        },
        'phone': {
            'type': 'string',
            'regex': '^(13[0-9]|15[012356789]|17[678]|18[0-9]|14[57])[0-9]{8}$',
            'required': True,
        },
        'subscribe_products': {
            'type': 'list',
            'schema': {
                'type': 'dict',
                'schema': {
                    'products': {
                        'type': 'objectid',
                        'data_relation': {
                             'resource': 'products',
                             'field': '_id',
                             'embeddable': True
                         },
                    },
                    'subscribe_date': {'type': 'datetime'},
                    'expires_date': {'type': 'datetime'},
                }
            },
        },
    }
}


portfolios = {
    'item_title': 'portfolios',
    'url': 'users/<regex("[a-f0-9]{24}"):__user_id__>/portfolios',
    'schema': {
        'name': {
            'type': 'string',
            'minlength': 1,
            'maxlength': 10,
            'required': True,
        },
        'initial_money': {
            'type': 'number',
            'required': True,
        },
        '__user_id__': {
            # when soft delete and auth field enable meanwhile, database schema must add auth field,
            # case when eve soft delete resource and it deepcopy the resource to marked_document
            # which dependent schema. if schema have no auth field, the marked_document also have no
            # auth field, finally mongodb store the deleted resource which have no auth field. It make
            # eve cannot get the deleted resource cause it enable the auth field.
            'type': 'objectid',
        },
        'users': {
            'type': 'objectid',
            'data_relation': {
                 'resource': 'users',
                 'field': '_id',
                 'embeddable': True
             },
        },
        'cal_date': {'type': 'datetime', },
        'is_public': {'type': 'boolean'},
        'portfolio_risk_money': {'type': 'number'},
        'portfolio_risk_ratio': {'type': 'number'},
        'portfolio_floating_profit_loss': {'type': 'number'},
        'portfolio_win_ratio': {'type': 'number'},
        'portfolio_profit_loss_ratio': {'type': 'number'},
        'portfolio_market_value': {'type': 'number'},
        'portfolio_return_ratio': {'type': 'number'},
        'portfolio_return_ratio_year': {'type': 'number'},
        'portfolio_position_date': {'type': 'datetime'},
        'portfolio_position': {'type': 'number'},
        'portfolio_profit_loss_month_ratio': {'type': 'number'},
        'portfolio_retreat_range': {'type': 'number'},
        'portfolio_created_date': {'type': 'datetime'},
        'portfolio_current_date': {'type': 'datetime'},
        'portfolio_begin_month_money': {'type': 'number'},
        'portfolio_begin_month_net': {'type': 'number'},
        'portfolio_average_position_day': {'type': 'number'},
        'portfolio_begin_amount': {'type': 'number'},
        'portfolio_current_amount': {'type': 'number'},
        'portfolio_created_net': {'type': 'number'},
        'portfolio_current_net': {'type': 'number'},
        'portfolio_biggest_retreat_day': {'type': 'number'},
        'portfolio_biggest_retreat_range': {'type': 'number'},
        'portfolio_trade_style': {'type': 'string'},
        'portfolio_trade_total_count': {'type': 'number'},
        'portfolio_trade_total_day': {'type': 'number'},
        'portfolio_trade_count_ratio': {'type': 'number'},
        'portfolio_sync_time': {'type': 'datetime'},
        'portfolio_pic': {'type': 'string'},
    }
}

risk_manager = {
    'item_title': 'risk_manager',
    'url': 'portfolios/<regex("[a-f0-9]{24}"):portfolios>/risk_manager',
    'schema': {
        '__user_id__': {
            # when soft delete and auth field enable meanwhile, database schema must add auth field,
            # case when eve soft delete resource and it deepcopy the resource to marked_document
            # which dependent schema. if schema have no auth field, the marked_document also have no
            # auth field, finally mongodb store the deleted resource which have no auth field. It make
            # eve cannot get the deleted resource cause it enable the auth field.
            'type': 'objectid',
        },
        'portfolios': {
            'type': 'objectid',
            'required': True,
            'data_relation': {
                 'resource': 'portfolios',
                 'field': '_id',
                 'embeddable': True
             },
        },
        'is_hold': {'type': 'boolean'},
        'is_event': {'type': 'boolean'},
        'buy': {
            'type': 'dict',
            'schema': {
                'code': {
                    'type': 'string',
                    'minlength': 6,
                    'maxlength': 6,
                },
                'amount': {'type': 'number'},
                'stop_price': {'type': 'number'},
                'target_price': {'type': 'number'},
                'trade_buy_date': {'type': 'datetime'},
                'trade_buy_price': {'type': 'number'},
                'trade_buy_comment': {'type': 'string'},
                'buy_kbar_img': {'type': 'string'},
            }
        },
        'sale': {
            'type': 'dict',
            'schema': {
                'trade_sale_date': {'type': 'datetime'},
                'trade_sale_price': {'type': 'number'},
                'trade_sale_comment': {'type': 'string'},
                'sale_kbar_img': {'type': 'string'},
            }
        },
        'buy_dp': {
            'type': 'dict',
            'schema': {
                'name': {'type': 'string'},
                'risk_all_money': {'type': 'number'},
                'position_ratio': {'type': 'number'},
                'price': {'type': 'number'},
                'is_should_sale': {'type': 'boolean'},
                'cost_price': {'type': 'number'},
                'floating_profit_loss': {'type': 'number'},
                'floating_profit_loss_ratio': {'type': 'number'},
                'risk_cost_money': {'type': 'number'},
                'target_profit': {'type': 'number'},
                'up_buy_amount': {'type': 'number'},
                'market_value': {'type': 'number'},
                'stop_ratio': {'type': 'number'},
                'risk_reward_ratio': {'type': 'number'},
                'trade_buy_score': {'type': 'number'},
                'trade_buy_high_price': {'type': 'number'},
                'trade_buy_low_price': {'type': 'number'},
                'buy_fee_cost': {'type': 'number'},
            },
            'dependencies': ['buy']
        },
        'buy_sale_dp': {
            'type': 'dict',
            'schema': {
                'hold_trade_day': {'type': 'number'},
                'trade_profit': {'type': 'number'},
                'trade_profit_ratio': {'type': 'number'},
                'trade_sale_score': {'type': 'number'},
                'trade_score': {'type': 'number'},
                'trade_sale_high_price': {'type': 'number'},
                'trade_sale_low_price': {'type': 'number'},
                'sale_fee_cost': {'type': 'number'},
                'trade_kbar_img': {'type': 'string'},
            },
            'dependencies': ['buy', 'sale']
        },
    }
}

cashflow_history = {
    'item_title': 'cashflow_history',
    'url': 'portfolios/<regex("[a-f0-9]{24}"):portfolios>/cashflow_history',
    'schema': {
        '__user_id__': {
            # when soft delete and auth field enable meanwhile, database schema must add auth field,
            # case when eve soft delete resource and it deepcopy the resource to marked_document
            # which dependent schema. if schema have no auth field, the marked_document also have no
            # auth field, finally mongodb store the deleted resource which have no auth field. It make
            # eve cannot get the deleted resource cause it enable the auth field.
            'type': 'objectid',
        },
        'portfolios': {
            'type': 'objectid',
            'data_relation': {
                 'resource': 'portfolios',
                 'field': '_id',
                 'embeddable': True
             },
        },
        'transfer_money': {'type': 'number'},
        'transfer_date': {'type': 'datetime'},
        'portfolio_net': {'type': 'number'},
    },
}

trade_history = {
    'item_title': 'trade_history',
    'url': 'portfolios/<regex("[a-f0-9]{24}"):portfolios>/trade_history',
    'schema': {
        '__user_id__': {
            # when soft delete and auth field enable meanwhile, database schema must add auth field,
            # case when eve soft delete resource and it deepcopy the resource to marked_document
            # which dependent schema. if schema have no auth field, the marked_document also have no
            # auth field, finally mongodb store the deleted resource which have no auth field. It make
            # eve cannot get the deleted resource cause it enable the auth field.
            'type': 'objectid',
        },
        'portfolios': {
            'type': 'objectid',
            'data_relation': {
                 'resource': 'portfolios',
                 'field': '_id',
                 'embeddable': True
             },
        },
        'risk_id': {'type': 'objectid'},
        'code': {'type': 'string'},
        'name': {'type': 'string'},
        'trade_date': {'type': 'datetime'},
        'buy_or_sale': {'type': 'number'},
        'trade_price': {'type': 'number'},
        'trade_cost': {'type': 'number'},
        'trade_money': {'type': 'number'},
        'trade_amount': {'type': 'number'},
    },
}

position = {
    'item_title': 'position',
    'url': 'portfolios/<regex("[a-f0-9]{24}"):portfolios>/position',
    'schema': {
        '__user_id__': {
            # when soft delete and auth field enable meanwhile, database schema must add auth field,
            # case when eve soft delete resource and it deepcopy the resource to marked_document
            # which dependent schema. if schema have no auth field, the marked_document also have no
            # auth field, finally mongodb store the deleted resource which have no auth field. It make
            # eve cannot get the deleted resource cause it enable the auth field.
            'type': 'objectid',
        },
        'portfolios': {
            'type': 'objectid',
            'data_relation': {
                 'resource': 'portfolios',
                 'field': '_id',
                 'embeddable': True
             },
        },
        'risk_id': {'type': 'objectid'},
        'code': {'type': 'string'},
        'name': {'type': 'string'},
        'price': {'type': 'number'},
        'stop_price': {'type': 'number'},
        'cost_price': {'type': 'number'},
        'market_value': {'type': 'number'},
        'amount': {'type': 'number'},
        'profit_or_loss': {'type': 'number'},
        'profit_or_loss_ratio': {'type': 'number'},
        'is_should_sale': {'type': 'boolean'},
        'position_ratio': {'type': 'number'},
    },
}

net_asset_value = {
    'item_title': 'net_asset_value',
    'url': 'portfolios/<regex("[a-f0-9]{24}"):portfolios>/net_asset_value',
    'schema': {
        '__user_id__': {
            # when soft delete and auth field enable meanwhile, database schema must add auth field,
            # case when eve soft delete resource and it deepcopy the resource to marked_document
            # which dependent schema. if schema have no auth field, the marked_document also have no
            # auth field, finally mongodb store the deleted resource which have no auth field. It make
            # eve cannot get the deleted resource cause it enable the auth field.
            'type': 'objectid',
        },
        'portfolios': {
            'type': 'objectid',
            'data_relation': {
                 'resource': 'portfolios',
                 'field': '_id',
                 'embeddable': True
             },
        },
        'trade_date': {'type': 'datetime'},
        'portfolio_net_value': {'type': 'number'},
        'portfolio_net_amount': {'type': 'number'},
        'portfolio_market_value': {'type': 'number'},
        'portfolio_position_value': {'type': 'number'},
        'portfolio_avaliable_cash': {'type': 'number'},
        'portfolio_buy_cost': {'type': 'number'},
        'portfolio_cash_transfer': {'type': 'number'},
        'portfolio_amount_change': {'type': 'number'},
        'portfolio_day_change': {'type': 'number'},
        'portfolio_net_retreat_change': {'type': 'number'},
        'portfolio_net_retreat_day': {'type': 'number'},
        'zz500_index': {'type': 'number'},
        'zz500_index_net': {'type': 'number'},
        'hs300_index': {'type': 'number'},
        'hs300_index_net': {'type': 'number'},
        'portfolio_trad_count': {'type': 'number'},
    },
}

position_history = {
    'item_title': 'position_history',
    'url': 'portfolios/<regex("[a-f0-9]{24}"):portfolios>/position_history',
    'schema': {
        '__user_id__': {
            # when soft delete and auth field enable meanwhile, database schema must add auth field,
            # case when eve soft delete resource and it deepcopy the resource to marked_document
            # which dependent schema. if schema have no auth field, the marked_document also have no
            # auth field, finally mongodb store the deleted resource which have no auth field. It make
            # eve cannot get the deleted resource cause it enable the auth field.
            'type': 'objectid',
        },
        'portfolios': {
            'type': 'objectid',
            'data_relation': {
                 'resource': 'portfolios',
                 'field': '_id',
                 'embeddable': True
             },
        },
        'trade_date': {'type': 'datetime'},
        'code': {'type': 'string'},
        'name': {'type': 'string'},
        'position_amount': {'type': 'number'},
        'close_price': {'type': 'number'},
        'market_value': {'type': 'number'},
    },
}

products = {
    'item_title': 'products',
    'schema': {
        '__user_id__': {
            # when soft delete and auth field enable meanwhile, database schema must add auth field,
            # case when eve soft delete resource and it deepcopy the resource to marked_document
            # which dependent schema. if schema have no auth field, the marked_document also have no
            # auth field, finally mongodb store the deleted resource which have no auth field. It make
            # eve cannot get the deleted resource cause it enable the auth field.
            'type': 'objectid',
        },
        'name': {'type': 'string'},
        'img': {'type': 'string'},
        'url': {'type': 'string'},
        'description': {'type': 'string'},
        'content': {
            'type': 'dict',
            'schema': {
                'order': {'type': 'number'},
                'title': {'type': 'string'},
                'img': {'type': 'string'},
                'is_public': {'type': 'boolean'},
                'article_url': {'type': 'string'},
            },
        },
    },
}

upload = {
    'item_title': 'upload',
    'auth_field': '',
    'resource_methods': ['POST'],
    'item_methods': ['GET'],
    'schema': {
        'file': {
            'type': 'media',
        }
    }
}

# The DOMAIN dict explains which resources will be available and how they will
# be accessible to the API consumer.
DOMAIN = {
    'users': users,
    'portfolios': portfolios,
    'risk_manager': risk_manager,
    'cashflow_history': cashflow_history,
    'trade_history': trade_history,
    'position': position,
    'net_asset_value': net_asset_value,
    'position_history': position_history,
    'products': products,
    'upload': upload,
}