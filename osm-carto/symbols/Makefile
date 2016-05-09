# osm-carto/symbols/Makefile

local_symbols=castle.svg fort.svg
osmic_symbols=castle-defensive-14.svg castle-manor-14.svg castle-stately-14.svg castle-fortress-14.svg castle-palace-14.svg

prepare: deps $(local_symbols) $(osmic_symbols)

%.svg:
	@for dir in local osmic/tourism; do \
	    if [ -f $$dir/$@ ]; then \
	        ln -svf $$dir/$@ .; \
	        break; \
	    fi; \
	done

deps: osmic

# osmic, for castle symbols
osmic:
	git clone https://github.com/nebulon42/osmic.git
