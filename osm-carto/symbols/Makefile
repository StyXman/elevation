# osm-carto/symbols/Makefile

local_symbols=castle.svg fort.svg cliff_mdione.png cliff2_mdione.png arete.svg ridge.svg forest-mixed.png forest-broad.png forest-needle.png grass2.png scrub_mdione.png
osmic_symbols=castle-defensive-14.svg castle-manor-14.svg castle-stately-14.svg castle-fortress-14.svg castle-palace-14.svg
maki_0.5_symbols=fuel-24.png london-underground-18.png parking-24.png
jeisenbe_symbols=water_intermittent.png

prepare: deps $(local_symbols) $(osmic_symbols) $(maki_0.5_symbols) $(jeisenbe_symbols)

%:
	@for dir in local osmic/tourism maki-0.5 jeisenbe; do \
	    if [ -f $$dir/$@ ]; then \
	        ln -svf $$dir/$@ .; \
	        break; \
	    fi; \
	done

deps: osmic

# osmic, for castle symbols
osmic:
	git clone https://github.com/nebulon42/osmic.git
