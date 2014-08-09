INFIX = $(shell mpv --version | head -n1 | cut -d' ' -f2)
MYCOMP = mpv_$(INFIX).completion.sh

all: $(MYCOMP)

$(MYCOMP):
	./gen.sh > $@

deb: $(MYCOMP)
	cp $(MYCOMP) ./mpv
	sudo checkinstall -D --pkgname mpv-bash-completion --pkgversion $(shell git describe --tags) -A all --pkgsource https://github.com/2ion/mpv-bash-completion --pkglicense GPL-3 make -f Makefile.install install
	rm -f ./mpv
