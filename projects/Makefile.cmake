cmake_ver=3.0.0
cmake_=cmake-$(cmake_ver)
projects+=$(cmake_)
names+=cmake

$(eval $(call standard_x,$(cmake_)))

cmaketoolchain=sol-$(sys_rel)-$(arch)-toolchain.cmake
.PRECIOUS: $(installroot)/$(arch)/$(cmaketoolchain)

$(installroot)/$(arch)/$(cmaketoolchain): patches/sol-VER-ARCH-toolchain.cmake
	mkdir -p $(@D)
	cat $< | sed \
		-e 's#%VER%#5.$(sys_rel)#g' \
		-e 's#%ARCH%#$(arch)#g' \
		-e 's#%TARGET%#$(target)#g' \
		> $@

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
install/$(arch)/$(cmake_)/._.install: $(installroot)/$(arch)/$(cmaketoolchain)

# ENTRY
cmakeenv: $(installroot)/$(arch)/$(cmaketoolchain)
	mkdir -p $(installroot)/$(arch)
	cat patches/sol-VER-ARCH-toolchain.cmake | sed \
		-e 's#%VER%#5.$(sys_rel)#g' \
		-e 's#%ARCH%#$(arch)#g' \
		-e 's#%TARGET%#$(target)#g' \
		> $<

	@echo $@ done

compiler: cmake

cmake: install-$(cmake_)
	@echo $@ done

# vim: set filetype=make :
