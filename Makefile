.PHONY: osm-carto-prepare clean

all: openstreetmap-carto.xml
	# $(MAKE) -C data/osm
	# $(MAKE) -C data/height
	# $(MAKE) -C tilemill/project/osm-tilemill
	# $(MAKE) -C mapnik-stylesheets

openstreetmap-carto.xml: osm-carto/project.mml osm-carto/*.mss
	make -C osm-carto
	carto $< | sed -e 's/minzoom/minimum-scale-denominator/g; s/maxzoom/maximum-scale-denominator/g;' > $@

# it works like this
# git clone complaints when you try to checkout to an exiting directory
# so we have to do some juggling to make it work
# but not to do it over and over again (and land in inconsistent states)
# we avoid doing it if osm-carto-checkout is up to date
# classic timestamp trick
prepare: osm-carto-checkout osm-carto-prepare

osm-carto-checkout:
	mv osm-carto tmp
	git clone https://github.com/gravitystorm/openstreetmap-carto.git osm-carto
	mv tmp/.pc tmp/patches tmp/Makefile tmp/.kateconfig osm-carto/
	rm -rf tmp
	touch osm-carto-checkout

osm-carto-prepare:
	make -C osm-carto prepare

clean:
	rm -f osm-carto-checkout
