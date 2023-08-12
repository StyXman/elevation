# Makefile

OSM_CARTO_VERSION=5.7.0

.PHONY: osm-carto-prepare Elevation-prepare data-height-prepare clean

all: Elevation.xml Elevation.diff

diff: Elevation.diff

Elevation.diff: osm-carto/project.mml osm-carto/*.mss
	cd osm-carto; git diff -w v$(OSM_CARTO_VERSION) > ../Elevation.diff

Elevation.xml: osm-carto/project.mml osm-carto/style/*.mss
	make -C osm-carto
	if ! time ./node_modules/.bin/carto $< > $@; then rm -f $@; false; fi

# it works like this
# git clone complaints when you try to checkout to an exiting directory
# so we have to do some juggling to make it work
# but not to do it over and over again (and land in inconsistent states)
# we avoid doing it if osm-carto-checkout is up to date
# classic timestamp trick
prepare: osm-carto-checkout osm-carto-prepare Elevation-prepare data-height-prepare symbols

osm-carto-checkout:
	mv osm-carto tmp
	git clone https://github.com/gravitystorm/openstreetmap-carto.git osm-carto
	mv tmp/.pc tmp/patches tmp/Makefile tmp/.kateconfig osm-carto/
	mv tmp/symbols/Makefile tmp/symbols/local osm-carto/symbols/
	rm -rf tmp
	touch osm-carto-checkout

osm-carto-prepare:
	make -C osm-carto prepare

Elevation-prepare:
	make -C Elevation prepare DATA_DIR=$(DATA_DIR)

data-height-prepare:
	make -C data/height prepare DATA_DIR=$(DATA_DIR)

symbols:
	ln -svf osm-carto/symbols .

clean:
	rm -f osm-carto-checkout
