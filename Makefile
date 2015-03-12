VERSION = 0.15
PKGRELEASE = 2
INFIX = $(shell mpv --version | head -n1 | cut -d' ' -f2)
MYCOMP = mpv_$(INFIX)-completion_$(VERSION).sh

all: $(MYCOMP)

$(MYCOMP): gen.sh $(shell which mpv)
	./$< > $@
	@echo -n "Checking the syntax of the generated file ... "
	@bash -n $@ && echo OK || echo ERROR

dist: $(MYCOMP)
	@xz $<

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
		--pkgrelease $(PKGRELEASE) \
		--nodoc \
		--install \
	 	make -f Makefile.checkinstall install 
		rm -f ./mpv

clean:
	rm -f ./*.deb *.tgz
