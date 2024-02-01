#!/usr/bin/env bash
scp -r ./v1/* root@improve365.cn:/data/var/www/i365/api/py/v1/
ssh root@improve365.cn "service uwsgi restart"