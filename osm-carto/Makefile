OSM_CARTO_VERSION=04f6d1bd3c6bbe0d8e2b8016836a24ccdab974a4
#v2.39.0

project.mml: project.yaml
	./scripts/yaml2mml.py $< > $@

prepare:
	git checkout $(OSM_CARTO_VERSION)
# this is in case we're using a dirty quilt set
	rm .pc/applied-patches
	quilt push -va
