# osm-carto/Makefile

.PHONY: symbols-prepare
.DELETE_ON_ERROR:

OSM_CARTO_VERSION=04f6d1bd3c6bbe0d8e2b8016836a24ccdab974a4
#v2.39.0

all: project.mml

project.mml: project.yaml
	./scripts/yaml2mml.py

# cqa is a shorthand for checkout quilt apply
prepare: cqa symbols-prepare all

cqa:
# this is in case we're using a dirty quilt set
	rm -f .pc/applied-patches
	git reset --hard $(OSM_CARTO_VERSION)
	quilt push -va
	touch cqa

symbols-prepare:
	make -C symbols prepare
