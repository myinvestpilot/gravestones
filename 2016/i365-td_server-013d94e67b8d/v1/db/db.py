# Config DB Schema
users = {
    'item_title': 'users',

    'additional_lookup': {
        'url': 'regex("[\w]+")',
        'field': 'username',
    },

    'public_methods': ['POST'],

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
            'allowed': ['user', 'admin'],
        },
        'password': {
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
                    'products_id': {
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
        }
    }
}

portfolios = {
    'item_title': 'portfolios',
    'public_methods': ['GET'],
    'public_item_methods': ['GET'],
    #'authentication': RolesTokenAuth,
    'schema': {
        'name': {
            'type': 'string',
            'minlength': 1,
            'maxlength': 10,
            'required': True,
        },
        'user_id': {
            'type': 'objectid',
            'data_relation': {
                 'resource': 'users',
                 'field': '_id',
                 'embeddable': True
             },
        },
        'is_public': {'type': 'boolean'},
        'portfolio_risk_money': {'type': 'number'},
        'portfolio_risk_ratio': {'type': 'number'},
        'portfolio_floating_profit_loss': {'type': 'number'},
        'portfolio_win_ratio': {'type': 'number'},
        'portfolio_profit_loss_ratio': {'type': 'number'},
        'portfolio_market_value': {'type': 'number'},
        'portfolio_return_ratio': {'type': 'number'},
        'portfolio_return_ratio_year': {'type': 'number'},
        'portfolio_initial_money': {'type': 'number'},
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
    }
}

risk_manager = {
    'item_title': 'risk_manager',
    'schema': {
        'portfolio_id': {
            'type': 'objectid',
            'data_relation': {
                 'resource': 'portfolios',
                 'field': '_id',
                 'embeddable': True
             },
        },
        'buy': {
            'type': 'dict',
            'schema': {
                'code': {'type': 'string'},
                'amount': {'type': 'number'},
                'stop_price': {'type': 'number'},
                'target_price': {'type': 'number'},
                'trade_buy_date': {'type': 'datetime'},
                'trade_buy_price': {'type': 'number'},
                'trade_buy_comment': {'type': 'string'},
                'buy_kbar_img': {'type': 'media'},
            }
        },
        'sale': {
            'type': 'dict',
            'schema': {
                'trade_sale_date': {'type': 'datetime'},
                'trade_sale_price': {'type': 'number'},
                'trade_sale_comment': {'type': 'string'},
                'sale_kbar_img': {'type': 'media'},
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
                'risk_cost_money': {'type': 'number'},
                'target_profit': {'type': 'number'},
                'up_buy_amount': {'type': 'number'},
                'market_value': {'type': 'number'},
                'stop_ratio': {'type': 'number'},
                'risk_reward_ratio': {'type': 'number'},
                'trade_buy_score': {'type': 'number'},
                'trade_buy_high_price': {'type': 'number'},
                'trade_buy_low_price': {'type': 'number'},
                'buy_commission_cost': {'type': 'number'},
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
                'sale_commission_cost': {'type': 'number'},
                'sale_fee_cost': {'type': 'number'},
                'trade_kbar_img': {'type': 'media'},
            },
            'dependencies': ['buy', 'sale']
        },
    }
}

cashflow_history = {
    'item_title': 'cashflow_history',
    'schema': {
        'portfolio_id': {
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
    'schema': {
        'portfolio_id': {
            'type': 'objectid',
            'data_relation': {
                 'resource': 'portfolios',
                 'field': '_id',
                 'embeddable': True
             },
        },
        'code': {'type': 'string'},
        'name': {'type': 'string'},
        'trade_date': {'type': 'datetime'},
        'buy_or_sale': {'type': 'boolean'},
        'trade_price': {'type': 'number'},
        'trade_cost': {'type': 'number'},
        'trade_money': {'type': 'number'},
        'trade_amount': {'type': 'number'},
    },
}

position = {
    'item_title': 'trade_history',
    'schema': {
        'portfolio_id': {
            'type': 'objectid',
            'data_relation': {
                 'resource': 'portfolios',
                 'field': '_id',
                 'embeddable': True
             },
        },
        'code': {'type': 'string'},
        'name': {'type': 'string'},
        'price': {'type': 'number'},
        'stop_price': {'type': 'number'},
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
    'schema': {
        'portfolio_id': {
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
    },
}

position_history = {
    'item_title': 'position_history',
    'schema': {
        'portfolio_id': {
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
        'name': {'type': 'string'},
        'img': {'type': 'string'},
        'url': {'type': 'string'},
        'description': {'type': 'string'},
        'content': {
            'type': 'dict',
            'schema': {
                'order': {'type': 'number'},
                'title': {'type': 'string'},
                'img': {'type': 'media'},
                'is_public': {'type': 'boolean'},
                'article_url': {'type': 'string'},
            },
        },
    },
}