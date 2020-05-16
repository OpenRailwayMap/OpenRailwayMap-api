**This is experimental code. It is not ready for production yet.**

# OpenRailwayMap API

This is a reimplementation of the OpenRailwayMap API in Python with performance as main development goal.
Its public REST API is not exactly the same as the old PHP implementation but it should do the job good enough
it serves to the website www.openrailwaymap.org.

## Features

* Facility search
  * Search facilities (stations, halts, tram stops, yards, sidings, crossovers) including disused, abandoned,
    razed and proposed ones and those under construction.
  * Fulltext search using PostgreSQL's full text search.
  * Fast (< 100 ms per request)

## Delevopment goals

The code of this application should be easy to read and it should be fast. We avoid unnecessary overhead
and aim to make as much use as possible of indexes in the database.

## API

### Facilities

URL: `/facility?<PARAMETERS>`

Parameters:

* `q=<string>`: search term (will be looked up in all `name=*` tags and `railway:ref=*`.
* `name=<string>`: search term (name search only)
* `ref=<string>`: serach by official facility reference number/code only
* `limit=<integer>`: maximum number of results, optional, defaults to 20

You must only use one of the arguments `q`, `name` and `ref`.

### Milestones

This API returns milestones and other railway features with a `railway:position=*` or `railway:position:excat=*` tag
if they are located on a track with a reference number. The API will return the two closest features within a
maximum distance of 10 kilometers. The presence of an `operator=*` tag on the tracks is honoured, it will be used to
distinguish reference numbers used by different infrastructure operators and/or in different countries.

The API only takes tracks without `service=*` (this condition does not apply to tracks with
`usage=industrial/military/test`) into account.

URL: `/milestone?<PARAMTERS>`

Parameters:

* `ref=<string>`: reference number of the railway route the mileage refers to (in this case, route meas lines as infrastructure, not the services using the tracks), mandatory
* `position=<float>`: position (can be negative), mandatory
* `limit=<integer>`: maximum number of results, optional, defaults to 20, must not exceed 200

## Dependencies and Deployment

This API runs as a Python WSGI application. You need a WSGI server and a web server. For development
purposes, you can just run `python3 api.py serve`.

Dependencies:

* Python 3
* [Werkzeug](https://werkzeug.palletsprojects.com/)
* [Psycopg2](https://www.psycopg.org/docs/)
* a PostgreSQL database imported as specified for the [map styles](https://github.com/OpenRailwayMap/OpenRailwayMap-CartoCSS/blob/master/SETUP.md)
* the SQL script `prepare.sql` and `prepare_milestone.sql` run against the database

## License

This project is licensed under the terms of GPLv2 or newer. You can find a copy of version 3 of the
