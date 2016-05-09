.PHONY: prepare

all: preview.png

preview.png:
	ln -svf 10/531/373.png $@

prepare:
	@for i in $$(seq 0 19); do \
	    src=$(DATA_DIR)/Elevation/$$i; \
	    if [ -d $$src ]; then \
	        ln -svf $$src .; \
	    fi \
	done


tile-clean:
	rm -rf $$(seq 0 19)
