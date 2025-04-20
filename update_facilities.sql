-- SPDX-License-Identifier: GPL-2.0-or-later
-- Flush data updates to the materialized views.

REFRESH MATERIALIZED VIEW CONCURRENTLY openrailwaymap_ref;
REFRESH MATERIALIZED VIEW CONCURRENTLY openrailwaymap_facilities_for_search;
