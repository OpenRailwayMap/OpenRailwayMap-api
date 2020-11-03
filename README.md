**This is experimental code. It is not ready for production yet.**

# OpenRailwayMap API

This is a reimplementation of the OpenRailwayMap API in Python with performance as main development goal.
Its public REST API is not exactly the same as the old PHP implementation but it should do the job good enough
it serves to the website www.openrailwaymap.org.

## Features

* Facility search
  * Search facilities (stations, halts, tram stops, yards, sidings, crossovers) including disused, abandoned,
    razed and proposed ones and those under construction by name or reference.
  * Fulltext search using PostgreSQL's full text search.
  * Fast (< 100 ms per request)
* Mileage search: Search the combination of line number and mileage.

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

## Setup

### Dependencies and Deployment

This API runs as a Python WSGI application. You need a WSGI server and a web server. For development
purposes, you can just run `python3 api.py serve`.

Dependencies:

* Python 3
* [Werkzeug](https://werkzeug.palletsprojects.com/)
* [Psycopg2](https://www.psycopg.org/docs/)

### Installation

Install the dependencies listed above:

```shell
apt install python3-werkzeug python3-psycopg2
```

If you want to deploy it on a server (not just run in development mode locally):

```shell
apt install apache2 libapache2-mod-wsgi-py3
```

Import OpenStreetMap data as described in the map style setup guide. You have to follow the following sections only:

* Dependencies (Kosmtik, Nik4 and PyYAML are not required)
* Database Setup
* Load OSM Data into the Database

Create database views:

```shell
sudo -u osmimport psql -d gis -f prepare.sql
sudo -u osmimport psql -d gis -f prepare_milestone.sql

Create a database user for the user running the API (either the user running Apache – often called www-data or httpd – or your user account in dev mode) and grant read permissions to this user:

```shell
createuser $USERNAME
sudo -u postgres psql -d gis -c "GRANT SELECT ON TABLES IN SCHEMA PUBLIC TO $USERNAME;"
```

## License

This project is licensed under the terms of GPLv2 or newer. You can find a copy of version 3 of the license in the [COPYING](COPYING) file.
