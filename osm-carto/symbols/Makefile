local_symbols=castle.svg fort.svg
osmic_symbols=castle-defensive-14.svg castle-manor-14.svg castle-stately-14.svg castle-fortress-14.svg castle-palace-14.svg

all: $(local_symbols) $(osmic_symbols)

%.svg:
	@for dir in ../../symbols/local ../../symbols/osmic/tourism; do \
	    if [ -f $$dir/$@ ]; then \
	        ln -sv $$dir/$@ .; \
	        break; \
	    fi; \
	done
