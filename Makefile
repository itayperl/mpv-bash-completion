VERSION = 0.5
INFIX = $(shell mpv --version | head -n1 | cut -d' ' -f2 | cut -d- -f1)
MYCOMP = mpv_$(INFIX)-completion_$(VERSION).sh

all: $(MYCOMP)

$(MYCOMP): gen.sh
	./$< > $@

.PHONY:deb
deb: $(MYCOMP)
	cp $(MYCOMP) ./mpv
	sudo checkinstall \
		-D \
		--pkgname mpv-bash-completion \
		--pkgversion $(VERSION) \
		-A all \
		--pkgsource "https://github.com/2ion/mpv-bash-completion" \
		--pkglicense GPL-3 \
		--pkgrelease 1 \
		--nodoc \
		--install \
	 	make -f Makefile.checkinstall install 
		rm -f ./mpv
