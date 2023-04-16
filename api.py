#! /usr/bin/env python3
# SPDX-License-Identifier: GPL-2.0-or-later

import psycopg2
import psycopg2.extras
import json
import sys
from werkzeug.exceptions import HTTPException, NotFound
from werkzeug.routing import Map, Rule
from werkzeug.wrappers import Request, Response
from openrailwaymap_api.facility_api import FacilityAPI
from openrailwaymap_api.milestone_api import MilestoneAPI

def connect_db():
    conn = psycopg2.connect('dbname=gis')
    psycopg2.extras.register_hstore(conn)
    return conn

class OpenRailwayMapAPI:

    db_conn = connect_db()

    def __init__(self):
        self.url_map = Map([
            Rule('/facility', endpoint=FacilityAPI, methods=('GET',)),
            Rule('/milestone', endpoint=MilestoneAPI, methods=('GET',)),
        ])

    def dispatch_request(self, environ, start_response):
        request = Request(environ)
        urls = self.url_map.bind_to_environ(environ)
        response = None
        try:
            endpoint, args = urls.match()
            response = endpoint(self.db_conn)(request.args)
        except HTTPException as e:
            response = e(environ, start_response)
#        except Exception as e:
#            response = Response(json.dumps({'status': 'error', 'msg': 'Other exception', 'detail': str(e)}), status=500, mimetype='application/json')
        finally:
            if not response:
                self.db_conn.close()
                self.db_conn = connect_db()
        return response

    def wsgi_app(self, environ, start_response):
        request = Request(environ)
        response = self.dispatch_request(request)
        return response(environ, start_response)


def application(environ, start_response):
    openrailwaymap_api = OpenRailwayMapAPI()
    response = openrailwaymap_api.dispatch_request(environ, start_response)
    return response(environ, start_response)


if __name__ == '__main__':
    openrailwaymap_api = OpenRailwayMapAPI()
    if len(sys.argv) == 2 and sys.argv[1] == 'serve':
        from werkzeug.serving import run_simple
        run_simple('127.0.0.1', 5000, application, use_debugger=True, use_reloader=True)
    else:
        sys.stderr.write('ERROR: Missing argument \'serve\'. Cannot start in standalone development mode this way.\n')
        exit(1)
