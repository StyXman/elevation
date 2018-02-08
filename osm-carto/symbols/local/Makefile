all: forest-mixed.png forest-broad.png forest-needle.png grass.png grass2.png

# see : https://github.com/gravitystorm/openstreetmap-carto/blob/master/symbols/generating_patterns/bare_ground.md

%.png: %.svg
	inkscape --export-png $@ $<
