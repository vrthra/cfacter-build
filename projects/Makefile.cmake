cmake_ver=3.0.0
cmake_=cmake-$(cmake_ver)
projects+=$(cmake_)
names+=cmake

$(eval $(call standard_x,$(cmake_)))

cmaketoolchain=sol-$(sys_rel)-$(arch)-toolchain.cmake
.PRECIOUS: $(installroot)/$(arch)/$(cmaketoolchain)

$(installroot)/$(arch)/$(cmaketoolchain): patches/$(cmaketoolchain) | $(installroot)/$(arch)
	cp $< $@

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
install/sparc/$(cmake_)/._.install: $(installroot)/$(arch)/$(cmaketoolchain)
	touch $@

# ENTRY
cmakeenv: $(installroot)/$(arch)/$(cmaketoolchain)
	@echo $@ done

compiler: cmake

cmake: install-$(cmake_)
	@echo $@ done

# vim: set filetype=make :
