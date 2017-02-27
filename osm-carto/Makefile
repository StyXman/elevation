# osm-carto/Makefile

.PHONY: symbols-prepare
.DELETE_ON_ERROR:

OSM_CARTO_VERSION=8f0d7f0afa8851ab9ee59b88f32cd215ea06144c
#v3.1.0

all:

# cqa is a shorthand for checkout quilt apply
prepare: cqa download-data symbols-prepare

cqa:
# this is in case we're using a dirty quilt set
	rm -f .pc/applied-patches
	git reset --hard $(OSM_CARTO_VERSION)
	quilt push -va
	touch cqa

all.diff:
	git diff > $@

download-data:
	./scripts/get-shapefiles.py
	touch download-data

symbols-prepare:
	make -C symbols prepare
