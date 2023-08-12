* dates on castles' and arch.sites' names
* what's this line
  http://127.0.0.1:6789/osm-carto/#11/46.8785/9.2285
* playgroung equipment https://github.com/gravitystorm/openstreetmap-carto/pull/3161/
* unpaved highway areas
* http://127.0.0.1:6789/osm-carto/#10/45.9387/6.6193 valley/etc names
* icons from ZL17 must be dots from ZL 16 or before
* man_made=cross + man_made=summit_cross + summit:cross=yes

* http://diablo:6789/osm-carto/#16/48.8733/2.4459

* Chambery label changes ZL 11 -> 12

* landcover/landuse
  * dark grey reservoirs http://192.168.84.99:6789/osm-carto/#14/43.4545/6.2140
  * remake scrub and leaveless symbol/pattern
  * salt_pond text halo

* review:
  * https://github.com/gravitystorm/openstreetmap-carto/commit/008f155c5b3818f4fc2f7d71c88bca5958fc860f

* contours:
  * http://192.168.84.99:6789/osm-carto/#13/44.2539/6.9334
  * http://192.168.84.99:6789/osm-carto/#12/44.2539/6.9334
  * http://192.168.84.99:6789/osm-carto/#11/44.2539/6.9334

* remove caves and peaks w/o names
  * bug? https://github.com/mapnik/mapnik/issues/4210

* differentiate ruin areas from tourist attractions
* https://wiki.openstreetmap.org/wiki/Historical_Objects/Map_Properties
* http://192.168.84.99:6789/osm-carto/#12/43.3032/5.3818 a jumble
* statue, obelisk, monument from @nice?
* http://diablo:6789/osm-carto/#16/48.8733/2.4459
* marshes have no grass: https://www.openstreetmap.org/way/232559153#map=14/46.8787/9.2437

* fix contour 0, no smooth?
* darker shopping color
* leafless
* don't show landuse until ZL13 or more
* make crosses HP against peaks
* man_made=cross + man_made=summit_cross + summit:cross=yes
* finish places texts
* Stop rendering extreme mountain paths without giving indication of difficulty
  https://github.com/gravitystorm/openstreetmap-carto/issues/1500
* fix tunnel road names
* find out city pattern in old maps, apply to populated places.
* review names for stupid things like picnic_table
* enable wetlands bg
* check cyclable for lowest ZL for cyclable roads
* contour lines as darken or similar.
    * not possible due to several bugs in mapnik
* wider bridges
  * this requires a big rework because bridge casings grow inward
* st_dump(st_linemerge(st_approximatemedialaxis(st_simplifypreservetopology(st_multi(st_buildarea(st_buffer(st_collect(way), 50))),20)))))
  for generalizing parallel roads
  see https://sk53-osm.blogspot.com/2018/04/linear-or-1d-maps-from-openstreetmap.html

* (private?) living_street ZL13 http://127.0.0.1:6789/osm-carto/#13/43.5466/6.9168
* ZL 8

* things to see from afar if they're low density:
  * pharmacy
    306 860 amenity=pharmacy
    111 180 healthcare=pharmacy
     32 763 shop=chemist

  * clinic
    133 763 amenity=clinic
     46 795 healthcare=clinic

  * hospital
    194 165 amenity=hospital
     97 378 building=hospital
     56 956 healthcare=hospital

  * police
    129 374 amenity=police

  * car_repair
    185 452 shop=car_repair
      8 983 building:use=car_repair
        784 building=car_repair

    24 108 shop=tyres
     5 587 service=tyres

    beware!
       305 service=repair;tyres

  * drinking water
    223 873 amenity=drinking_water

  * toilets
    313 960 amenity=toilets
     11 408 building=toilets
      1 626 room=toilets

* zoom in in places with these:
  * restaurant    1 308 997
  * cafe            512 267
  *

* bus lines
  * make text halos ~transparent on subways ZL13
  * darker trams et al (find all)

* finish places texts
* fix tunnel road names
* vallons/bois names too prominent.
* contour lines as darken or similar.
* review landcover-flat, make it terrain aware again
* simplify coastline for ZL <= 6
* calculate casing colors so they're not calculated all the time
* thicker for phone?
* lowzooms: specific rivers/lakes for rendering
  * natural earth vs imagico
* sync riverbanks thickness with river casing
* find out city pattern in old maps, apply to populated places.
* farmland, vineyeard, orchard
* intermittent waterways too prominent, make casing intermittent too
* borders for lakes in z0-z8
* pines grow up to 5000m. check terrain colors against forest or similar.

* fix roads as line too dark: DONE? Nope ZL12
 * ZL12, make tertiary more prominent by just enthicken the line, no white center
 * ZL13-14: residential, etc are still lines, if possible less prominent

* review names for stupid things like picnic_table
* partially revert b066af54f61b02685edb5db4191c5fbc3617eb5d
* comment more the tags that are removed so I can resolve conflicts more easily

* verify disabled parking spaces
* watermills

* ice/winter road
gis=# select highway, count(highway) from planet_osm_line where tags->'ice_road' = 'yes' and highway is not null group by highway;
   highway    | count
--------------+-------
 cycleway     |     1
 footway      |     7
 ice_road     |     1
 path         |   263
 residential  |     3
 road         |     4
 seasonal     |    18
 secondary    |     5
 service      |    10
 tertiary     |    17
 track        |    77
 unclassified |    58
 yes          |     1

gis=# select highway, count(highway) from planet_osm_line where tags->'winter_road' = 'yes' and highway is not null group by highway;
   highway    | count
--------------+-------
 construction |    34
 footway      |    11
 path         |    83
 residential  |     4
 road         |    12
 service      |     3
 tertiary     |     2
 track        |    82
 unclassified |    24

* https://api.mapbox.com/styles/v1/mapbox/outdoors-v9.html?title=true&access_token=pk.eyJ1IjoibWFwYm94IiwiYSI6ImNpejY4M29iazA2Z2gycXA4N2pmbDZmangifQ.-g_vE53SD2WrJ6tFX7QHmA#6/43.045/5.811
  * label density

* http://mtbmap.cz/#zoom=15&lat=49.27364&lon=16.54532 private road
* ski https://www.xctrails.org/map/map.html?type=xc
* canal tunnels

* ocean border ZL3
* ZL 4-6: cities less prominent, countries in CAPS too
* ZL12 is terrible in big cities
* push sidings later: almost done, see TODOs
* ZL 8


             line-casing
Mayor roads
motorway
trunk
primary         8-12
secondary       9-12
minor roads for different zoom levels
tertiary       10-12
road           10-14  # also unclassified
residential    12-13
service        13-14
living_street    -13

unpaved
               8    9    10   11   12   13   14    15    16
* primary      done done done done done done done  done  done
* secondary         done done done done done done  done  done
* tertiary               done done done done done  done  done
* road                   done done done done weird weird done  # GREY
* residential/unclassified         done done done  done  done
* service                               done weird wierd done
* living street                         done done  done  done  # GREY

jeisenbe <42757252+jeisenbe@users.noreply.github.com>  2019-02-06 02:26:48
jeisenbe <joseph.eisenberg@gmail.com>  2019-01-22 13:28:09
jeisenbe <42757252+jeisenbe@users.noreply.github.com>  2019-01-12 12:31:11
Adamant36 <amendenhall@live.com>  2019-01-02 23:13:53
Paul Norman <penorman@mac.com>  2016-02-28 13:12:38
imagico <git@imagico.de>  2015-08-26 15:09:24
ocean outline math1985 <info@matthijsmelissen.nl>  2018-02-11 20:57:13

map_utils:
* implement geopackage
  http://www.geopackage.org/spec/
* optimize pngs
* read metadata.json
* select ST_AsText(ST_Transform(way, 4326))
  from planet_osm_polygon
  where way && ST_Transform(ST_GeomFromText('POLYGON((7 43, 7.5 43, 7.5 44.5, 7 44.5, 7 43))', 4326), 3857)
    and landuse in ('retail', 'commercial', 'college', 'hospital', 'industrial', 'residential');
