cmake_ver=3.0.0
cmake_=cmake-$(cmake_ver)
projects+=$(cmake_)

$(eval $(call standard_x,$(cmake_)))

build/$(arch)/$(cmake_)/._.config: install/$(arch)/gcc-$(gcc_ver)/._.install

build/i386/$(cmake_)/._.config: source/$(cmake_)/._.patch
	(cd $(@D) && env \
		CC=$(prefix)/bin/$(target)-gcc \
		CXX=$(prefix)/bin/$(target)-g++ \
		CFLAGS="-I$(prefix)/include" \
		LD_LIBRARY_PATH="$(prefix)/lib" \
		LDFLAGS="-L$(prefix)/lib -R$(prefix)/lib" \
		$(rootdir)/source/$(cmake_)/bootstrap \
			--prefix=$(prefix) \
			--datadir=/share/cmake \
			--docdir=/share/doc/$(cmake_) \
			--mandir=/share/man \
			--verbose \
	) $(t) $@.log
	touch $@

# DUMMY
install/sparc/$(cmake_)/._.install:
	touch $@

cmake: install/$(arch)/$(cmake_)/._.install
	@echo $@ done

# vim: set filetype=make :
