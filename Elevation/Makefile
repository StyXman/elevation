.PHONY: prepare

all: preview.png

preview.png:
	ln -svf 10/531/373.png $@

prepare:
	@for i in $(seq 0 19); do \
	    src=$(DATA_DIR)/Elevation/$i; \
	    if [ -d $$src ]; then \
	        ln -svf $$src .; \
	    fi \
	done


tile-clean:
	rm -rf 0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18
