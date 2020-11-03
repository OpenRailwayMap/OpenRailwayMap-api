-- SPDX-License-Identifier: GPL-2.0-or-later
CREATE EXTENSION IF NOT EXISTS unaccent;

CREATE OR REPLACE VIEW openrailwaymap_ref AS
  SELECT
      osm_id,
      name,
      tags,
      railway,
      ref,
      way AS geom
    FROM planet_osm_point
    WHERE
      railway IN ('station', 'halt', 'tram_stop', 'service_station', 'yard', 'junction', 'spur_junction', 'crossover', 'site', 'tram_stop')
      OR tags->'disused:railway' IN ('station', 'halt', 'tram_stop', 'service_station', 'yard', 'junction', 'spur_junction', 'crossover', 'site', 'tram_stop')
      OR tags->'abandoned:railway' IN ('station', 'halt', 'tram_stop', 'service_station', 'yard', 'junction', 'spur_junction', 'crossover', 'site', 'tram_stop')
      OR tags->'proposed:railway' IN ('station', 'halt', 'tram_stop', 'service_station', 'yard', 'junction', 'spur_junction', 'crossover', 'site', 'tram_stop')
      OR tags->'razed:railway' IN ('station', 'halt', 'tram_stop', 'service_station', 'yard', 'junction', 'spur_junction', 'crossover', 'site', 'tram_stop');

CREATE INDEX IF NOT EXISTS openrailwaymap_ref_railway_ref_idx
  ON planet_osm_point
  USING BTREE((tags->'railway:ref'))
  WHERE
    railway IN ('station', 'halt', 'tram_stop', 'service_station', 'yard', 'junction', 'spur_junction', 'crossover', 'site', 'tram_stop')
    OR tags->'disused:railway' IN ('station', 'halt', 'tram_stop', 'service_station', 'yard', 'junction', 'spur_junction', 'crossover', 'site', 'tram_stop')
    OR tags->'abandoned:railway' IN ('station', 'halt', 'tram_stop', 'service_station', 'yard', 'junction', 'spur_junction', 'crossover', 'site', 'tram_stop')
    OR tags->'proposed:railway' IN ('station', 'halt', 'tram_stop', 'service_station', 'yard', 'junction', 'spur_junction', 'crossover', 'site', 'tram_stop')
    OR tags->'razed:railway' IN ('station', 'halt', 'tram_stop', 'service_station', 'yard', 'junction', 'spur_junction', 'crossover', 'site', 'tram_stop');

CREATE MATERIALIZED VIEW IF NOT EXISTS openrailwaymap_facilities_for_search AS
  SELECT
      osm_id,
      to_tsvector('simple', unaccent(value)) AS terms,
      name,
      tags,
      railway,
      ref,
      geom
    FROM (
      SELECT DISTINCT ON (osm_id, key, value, tags, name, railway, ref, geom)
          osm_id,
          (each(updated_tags)).key AS key,
          (each(updated_tags)).value AS value,
          tags,
          name,
          railway,
          ref,
          geom
        FROM (
          SELECT
              osm_id,
              CASE
                WHEN name IS NOT NULL THEN tags || hstore('name', name)
                ELSE tags
              END AS updated_tags,
              name,
              tags,
              railway,
              ref,
              way AS geom
            FROM planet_osm_point
            WHERE
              railway IN ('station', 'halt', 'tram_stop', 'service_station', 'yard', 'junction', 'spur_junction', 'crossover', 'site', 'tram_stop')
              OR tags->'disused:railway' IN ('station', 'halt', 'tram_stop', 'service_station', 'yard', 'junction', 'spur_junction', 'crossover', 'site', 'tram_stop')
              OR tags->'abandoned:railway' IN ('station', 'halt', 'tram_stop', 'service_station', 'yard', 'junction', 'spur_junction', 'crossover', 'site', 'tram_stop')
              OR tags->'proposed:railway' IN ('station', 'halt', 'tram_stop', 'service_station', 'yard', 'junction', 'spur_junction', 'crossover', 'site', 'tram_stop')
              OR tags->'razed:railway' IN ('station', 'halt', 'tram_stop', 'service_station', 'yard', 'junction', 'spur_junction', 'crossover', 'site', 'tram_stop')
          ) AS organised
      ) AS duplicated
    WHERE
      key = 'name'
      OR key = 'alt_name'
      OR key = 'short_name'
      OR key = 'long_name'
      OR key = 'official_name'
      OR key = 'old_name'
      OR key LIKE 'name:%'
      OR key LIKE 'alt_name:%'
      OR key LIKE 'short_name:%'
      OR key LIKE 'long_name:%'
      OR key LIKE 'official_name:%'
      OR key LIKE 'old_name:%';

CREATE INDEX IF NOT EXISTS openrailwaymap_facilities_name_index ON openrailwaymap_facilities_for_search USING gin(terms);
