#! /usr/bin/env python3

import sys
import math

import rasterio
import pyproj
import numpy

# RuntimeWarning: overflow encountered in multiply
numpy.seterr(all='raise')

args = sys.argv[1:]

if args[0] in ('-s', '--slow'):
    fast = False
    args.pop(0)
else:
    fast = True

in_file = rasterio.open(args[0])
band = in_file.read(1)  # yes, we assume only one band

out_data = []
slow = 0

# src_proj = pyproj.Proj(init=f"epsg:{in_file.crs.to_epsg()}")
# latlon = pyproj.Proj(init='epsg:4326')

# WebMercator
transformer = pyproj.Transformer.from_crs(in_file.crs, 'epsg:4326')

# TODO: launch a thread pool and process one line per thread
# or do what I do around this and launch several in parallel

# scan every line in the input
for row in range(in_file.height):
    if (row % 10) == 0:
        # print(f"{row}/{in_file.height}")
        pass

    # be careful because the distance between lines is not necessarily constant
    # but rasterio should take care of that for us, so we trust it
    line = band[row]

    if fast:
        _, x = in_file.xy(row, 0)
        lat, _ = transformer.transform(0, x)
        coef = 1 / math.cos(math.radians(lat))
        if (row % 10) == 0:
            # print(f"{lat}, {coef}")
            pass

        # print(f"{lat}, {coef}")
        if all(numpy.isinf(line)):
            continue

        try:
            line *= coef
        except numpy.core._exceptions._UFuncOutputCastingError:
            # line is probably of int type, and can't multiply with float and store int again
            # so we have to do all that by hand
            line = numpy.array(line, dtype=float)
            line *= coef
        except FloatingPointError:
            # print(f"{coef}: {line}")
            # raise

            # TODO: handle other NoData values!

            # some NoData values are -inf, and if any is present the above multiplication fails
            # so go pixel by pixel and check before multiplying
            slow += 1

            for col in range(in_file.width):
                if not numpy.isinf(line[col]):
                    line[col] *= coef

    else:
        # in fact, it can be arbitrarily more complex
        # EU-DEM does not provide 'nice' 1x1 rectangular tiles,
        # they use a specific projection that become 'arcs' in anything rectangular

        # so, pixel by pixel too
        for col in range(in_file.width):
            # rasterio does not say where do the coords returned fall in the pixel
            # but at 30m tops, we don't care
            # I don't understand why x is the second item
            y, x = in_file.xy(row, col)

            # convert back to latlon, but transform() returns lon, lat!
            # _, lat = pyproj.transform(src_proj, latlon, 0, x)
            # _, lat = transformer.transform(0, x)
            lat, _ = transformer.transform(y, x)

            # calculate a compensation value based on the lat of the center of the line
            # real widths are pixel_six * cos(lat), we compensate by the inverse of that
            coef = 1 / math.cos(math.radians(lat))
            # print(f"row: {row}; col: {col}; x: {x}; lat: {lat}; coef: {coef}")

            # multiply the pixel by that
            line[col] *= coef

    # print(line[:10])
    # print(compensated_line[:10])

    out_data.append(line)

if fast and slow > 0:
    print(f"{slow}/{in_file.height} slow rows")

# save in a new file.
out_file = rasterio.open(args[1], 'w', driver='GTiff',
                         height=in_file.height, width=in_file.width,
                         count=1, dtype=in_file.dtypes[0],
                         crs=in_file.crs, transform=in_file.transform,
                         bigtiff=True, tiled=True, compress='LZMA', lzma_preset=9)

out_file.write(numpy.asarray(out_data, in_file.dtypes[0]), 1)
