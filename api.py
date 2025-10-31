#! /usr/bin/env python3
# SPDX-License-Identifier: GPL-2.0-or-later

import argparse
import psycopg2
import psycopg2.extras
import json
import sys
from werkzeug.exceptions import HTTPException, NotFound, InternalServerError
from werkzeug.routing import Map, Rule
from werkzeug.wrappers import Request, Response
from openrailwaymap_api.facility_api import FacilityAPI
from openrailwaymap_api.milestone_api import MilestoneAPI

cors = None

def connect_db():
    conn = psycopg2.connect('dbname=gis')
    psycopg2.extras.register_hstore(conn)
    return conn

class OpenRailwayMapAPI:

    db_conn = connect_db()

    def __init__(self, **kwargs):
        self.url_map = Map([
            Rule('/facility', endpoint=FacilityAPI, methods=('GET',)),
            Rule('/milestone', endpoint=MilestoneAPI, methods=('GET',)),
        ])
        self.cors = kwargs.get('cors')

    def ensure_db_connection_alive(self):
        if self.db_conn.closed != 0:
            self.db_conn = connect_db()

    def dispatch_request(self, environ, start_response):
        request = Request(environ)
        urls = self.url_map.bind_to_environ(environ)
        response = None
        try:
            endpoint, args = urls.match()
            self.ensure_db_connection_alive()
            response = endpoint(self.db_conn)(request.args)
        except HTTPException as e:
            return e
        except Exception as e:
            sys.stderr.write('{}\n'.format(e))
            return InternalServerError()
        finally:
            if not response:
                self.db_conn.close()
                self.db_conn = connect_db()
        if self.cors is not None:
            response.headers['Access-Control-Allow-Origin'] = str(self.cors)
        return response

    def wsgi_app(self, environ, start_response):
        request = Request(environ)
        response = self.dispatch_request(request)
        return response(environ, start_response)


def application(environ, start_response):
    openrailwaymap_api = OpenRailwayMapAPI(cors=cors)
    response = openrailwaymap_api.dispatch_request(environ, start_response)
    return response(environ, start_response)


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='OpenRailwayMap API development mode. Do not run this command for production but use an WSGI server instead.')
    parser.add_argument('-c', '--cors', type=str, help='Value for HTTP header "Access-Control-Allow-Origin" if one should be set.')
    parser.add_argument('-p', '--port', type=int, default=5000, help='HTTP port to listen at, defaults to 5000.')
    args = parser.parse_args()
    cors = args.cors
    openrailwaymap_api = OpenRailwayMapAPI()
    from werkzeug.serving import run_simple
    run_simple('127.0.0.1', args.port, application, use_debugger=True, use_reloader=True)
