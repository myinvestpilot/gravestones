# -*- coding: utf-8 -*-
from eve.auth import BasicAuth
from flask import request
from redis import StrictRedis
from flask_sentinel.core import mongo
from flask import current_app as app


class BearerAuth(BasicAuth):
    """ Overrides Eve's built-in basic authorization scheme and uses Redis to
    validate bearer token
    """
    def __init__(self):
        super(BearerAuth, self).__init__()
        self.redis = StrictRedis()

    def check_auth(self, token, allowed_roles, resource, method):
        """ Check if API request is authorized.
        Examines token in header and checks Redis cache to see if token is
        valid. If so, request is allowed.
        :param token: OAuth 2.0 access token submitted.
        :param allowed_roles: Allowed user roles.
        :param resource: Resource being requested.
        :param method: HTTP method being executed (POST, GET, etc.)
        """
        if token:
            # token_dic = mongo.db.tokens.find_one({"access_token": token})
            token_dic = app.data.driver.db.tokens.find_one({"access_token": token})
            if token_dic:
                self.set_request_auth_value(token_dic['user_id'])
                return token and self.redis.get(token)
        return False

    def authorized(self, allowed_roles, resource, method):
        """ Validates the the current request is allowed to pass through.
        :param allowed_roles: allowed roles for the current request, can be a
                              string or a list of roles.
        :param resource: resource being requested.
        """
        try:
            token = request.headers.get('Authorization').split(' ')[1]
        except:
            token = None
        return self.check_auth(token, allowed_roles, resource, method)