# -*- coding: utf-8 -*-

import requests
import json
import random

ENTRY_POINT = 'http://127.0.0.1:5000'


def post_people():
    people = [
        {},
    ]

    r = perform_post('people', json.dumps(people))
    print "'people' posted", r.status_code

    valids = []
    if r.status_code == 201:
        response = r.json()
        if response['_status'] == 'OK':
            for person in response['_items']:
                if person['_status'] == "OK":
                    valids.append(person['_id'])

    return valids


def post_works(ids):
    works = []
    for i in range(28):
        works.append(
            {
                'title': 'Book Title #%d' % i,
                'description': 'Description #%d' % i,
                'owner': random.choice(ids),
            }
        )

    r = perform_post('works', json.dumps(works))
    print "'works' posted", r.status_code


def perform_post(resource, data):
    headers = {'Content-Type': 'application/json'}
    return requests.post(endpoint(resource), data, headers=headers)


def delete():
    r = perform_delete('people')
    print "'people' deleted", r.status_code
    r = perform_delete('works')
    print "'works' deleted", r.status_code


def perform_delete(resource):
    return requests.delete(endpoint(resource))


def endpoint(resource):
    return '%s/%s/' % (ENTRY_POINT, resource)


def get():
    r = requests.get('http://eve-demo.herokuapp.com')
    print r.json

if __name__ == '__main__':
    delete()
    ids = post_people()
    post_works(ids)