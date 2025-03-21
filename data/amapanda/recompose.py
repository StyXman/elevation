#! /usr/bin/env python3

import csv
from dataclasses import dataclass
import math
# I thought I would generate a shapefile, but then I was thinking of storing the segments in a DB
# so I can update their full_size when creating a new segment. then I realized that not only this would require
# double the space, sqlite has support for GIS data and indexes
import sqlite3
import sys
import threading

from shapely import from_wkt, LineString, to_wkb, to_wkt

# TODO: split in functions so the heavy stuff can be done in //

# EPSGs
WebMerc = 3857
LonLat = 4326

db = sqlite3.connect('amapanda.sqlt')
db.enable_load_extension(True)
cursor = db.cursor()

cursor.execute('''SELECT load_extension('mod_spatialite');''')
cursor.execute('''SELECT InitSpatialMetaData();''')
db.commit()

cursor.execute('''DROP TABLE IF EXISTS "rivers";''')
db.commit()


cursor.execute('''CREATE TABLE "rivers" (
    "id"      INTEGER,
    "size"    INTEGER
    -- "way"     GEOMETRY  -- this one is add by hand later
)''')
cursor.execute(f"""SELECT AddGeometryColumn('rivers', 'way', {LonLat}, 'LINESTRING', 'XY');""")  # 2D
db.commit()


@dataclass
class River:
    id: int
    # we want both the size of this segment but also the fiull size of the whole river
    # so we can select rivers by final size, but also its segments of smaller size
    size: int
    full_size: int
    points: list[tuple[int, int]]

    def save(self):
        # TODO: convert to WebMerc!
        # line_string = to_wkb(LineString(self.points), hex=True, output_dimension=2)
        line_string = to_wkt(LineString(self.points), output_dimension=2)
        cursor.execute(f"""INSERT INTO rivers VALUES (?, ?, GeomFromText(?, {LonLat}));""", (self.id, self.size, line_string))


current = None
count = 0

for data in csv.DictReader(sys.stdin):
    try:
        river_id = int(data['end_nid'])
        line = from_wkt(data['geom'])
        from_upstream_m = float(data['from_upstream_m'])
        if from_upstream_m >= 10:
            size = math.log(from_upstream_m, 10)
        else:
            size = 1

        # too small, don't want it
        if size < 6:
            continue

        # start_lon, start_lat, end_lon, end_lat = line.coords
        # print(f"{river_id=}, {size=}")

        if current is not None:
            if river_id == current.id:
                # shapely does not have a way to extend LineStrings
                # except by creating a MultiLineString first and the use line_merge()
                # and LS.coords is a tuple, so if we want to extent it by hand
                # we first have to expand it, then add, the recompose, which can be expensive

                # so, the type has a list .... of points
                # which means now we have to either detect which one is the new one
                # or assume some invariant on the data, as we do with distance

                # assert current

                # if the size has changed, or itś an unconnected segment, we need to do a lot of work
                if size > current.size or tuple(line.coords[0]) != current.points[-1]:
                    # store the river as it is
                    current.save()
                    # print(f"Segment {current.id=} {current.size=} finished.")
                    # create a new river
                    current = River(river_id, size, size, [ tuple(line.coords[0]), tuple(line.coords[1]) ])
                    # print(f"Starting segment {current.id=} {current.size=}.")
                    # TODO: update other segments with the same river_id tih the new full_size
                else:
                    # just add the new point to the current river
                    new_point = tuple(line.coords[1])
                    current.points.append(new_point)
            else:
                # store the river as it is
                current.save()
                # print(f"Segment {current.id=} {current.size=} finished.")
                current = River(river_id, size, size, [ tuple(line.coords[0]), tuple(line.coords[1]) ])
                # print(f"Starting segment {current.id=} {current.size=}.")
                # TODO: update other segments with the same river_id tih the new full_size
        else:
            current = River(river_id, size, size, [ tuple(line.coords[0]), tuple(line.coords[1]) ])
            # print(f"Starting segment {current.id=} {current.size=}.")

        count += 1

        if count % 1024 == 0:
            db.commit()
    except Exception as e:
        print(f"{data=} failed because {e=}")
        raise

# SELECT load_extension('spatialite_dynamic_library_name');
# SELECT load_extension('mod_spatialite');

db.commit()

cursor.execute( '''SELECT CreateSpatialIndex('rivers', 'way');''')
db.commit()

db.close()
