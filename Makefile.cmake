cmake_ver=3.0.0
cmake_=cmake-$(cmake_ver)
projects+=$(cmake_)

$(eval $(call standard_x,$(cmake_)))

build/$(arch)/$(cmake_)/._.config: install/$(arch)/gcc-$(gcc_ver)/._.install

build/i386/$(cmake_)/._.config: source/$(cmake_)/._.patch | ./build/i386/$(cmake_)
	(cd $(rootdir)/build/i386/$(cmake_) && env \
		CC=$(prefix)/bin/$(target)-gcc \
		CXX=$(prefix)/bin/$(target)-g++ \
		MAKE=$(MAKE) \
		CFLAGS="-I$(prefix)/include" \
		LD_LIBRARY_PATH="$(prefix)/lib" \
		LDFLAGS="-L$(prefix)/lib -R$(prefix)/lib" \
		$(rootdir)/source/$(cmake_)/bootstrap \
			--prefix=$(prefix) \
			--datadir=/share/cmake \
			--docdir=/share/doc/$(cmake_) \
			--mandir=/share/man \
			--verbose \
	) $(t)> $@.log
	touch $@

build/sparc/$(cmake_)/._.config: source/$(cmake_)/._.patch | ./build/$(arch)/$(cmake_)
	echo "Can not build cmake for sparc" && exit 1

cmake: install/$(arch)/cmake-$(cmake_ver)/._.install
	@echo $@ done

# vim: set filetype=make :
