# =============================================================================
# This makefile is setup to build cfacter first building the
# cross-compiler suite (binutils, cross-compilers, cmake) followed by
# cfacter dependencies (boost, yaml, openssl)
# deprecated: (apachelogcxx, re2)
# Threaded dependendencies are setup loosely following the opensolaris package
# maintainer best practices. Our directory structure is as follows
#
# ./
# ./source
# ./source/${arch:sparc,i386}.sysroot.tar.gz        -- contains sysroot headers
# ./source/<patches>
# ./source/$project_$version.tar.gz
# ./source/$project_$version/								-- generated from tar.gz
# ./build
# ./build/${arch:sparc,i386}
# ./build/${arch:sparc,i386}/$project_$version/
#
# The general steps (along with dependencies) are as follows (< needs)
#
# source/%.tar.gz
# 	< source/%/._.checkout
#	 		< source/%/._.patch
#	 			< source/%/._.config
#	 				< source/%/._.make
#	 					< source/%/._.install
# =============================================================================
# Global definitions.
include Makefile.global
# -----------------------------------------------------------------------------
# Asking make not to delete any of our intermediate touch files.
.PRECIOUS: $(get_) $(checkout_) $(patch_) \
	         $(config_) $(make_) $(install_) \
	         $(toolchain_) 

# ENTRY
all:
	@echo "usage:\tsudo $(MAKE) prepare"
	@echo "\t$(MAKE) arch=$(arch) cfacter"
	@echo
	@echo "remove:\tsudo $(MAKE) uninstall"


# ENTRY
# Clean out our builds. Note that we dont touch our sources which should not
# be dirty.
clean:
	rm -rf build/$(arch)

# ENTRY
# Clean out the installed packages. Unfortunately, we also need to
# redo the headers 
clobber:
	rm -rf $(installroot)

prepare-10:
	@echo

prepare-11:
	pkg install developer/gcc-45
	pkg install system/header

# ENTRY
# This is to be the only command that requires `sudo` or root.
# Use `sudo gmake prepare` to invoke.
prepare: prepare-$(sys_rel)
	rm -rf $(installroot)
	mkdir -p $(installroot)
	chmod 777 $(installroot)

# Project specific makefiles
# Use the generic as a template for new projects
include Makefile.generic

include Makefile.binutils
include Makefile.gcc
include Makefile.cmak
include Makefile.boost
include Makefile.yamlcpp

.PRECIOUS: $(installroot)/$(arch)/sol-$(sys_rel)-$(arch)-toolchain.cmake

$(installroot)/$(arch)/sol-$(sys_rel)-$(arch)-toolchain.cmake: source/sol-$(sys_rel)-$(arch)-toolchain.cmake | $(installroot)/$(arch)
	cp source/sol-$(sys_rel)-$(arch)-toolchain.cmake $(installroot)/$(arch)/

# ENTRY
# We use the native cmake to build our cross-compiler, which unfortunately
# means that we have to build the native toolchain aswell
make-toolchain-%: install/i386/cmake-$(cmake_ver)/._.install install/%/gcc-$(gcc_ver)/._.install
	@echo $@ done

update-toolchain:
	(cd /opt/ && $(tar) -cf - $(installlabel)/i386 ) | $(gzip) -c > source/sol-$(sys_rel)-i386-compiler.tar.gz
	(cd /opt/ && $(tar) -cf - $(installlabel)/sparc ) | $(gzip) -c > source/sol-$(sys_rel)-sparc-compiler.tar.gz
	(cd /opt/ && $(tar) -cf - $(installlabel) ) | $(gzip) -c > source/sol-$(sys_rel)-i386-sparc-compilers.tar.gz

source/sol-$(sys_rel)-$(arch)-compiler.tar.gz: | source
	$(wget) -P source/ $(toolurl)/$(sys_rel)/sol-$(sys_rel)-$(arch)-compiler.tar.gz

$(installroot)/$(arch)/bin/$(target)-gcc: | source/sol-$(sys_rel)-$(arch)-compiler.tar.gz
	@echo start $@
	cat source/sol-$(sys_rel)-$(arch)-compiler.tar.gz | (cd /opt/ && $(gzip) -dc | $(tar) -xf - )
	@echo done $@

fetch-toolchain-%: | $(installroot)/%/bin/$(call mytarget,%)-gcc
	@echo done $@

# ENTRY
cmakeenv: $(installroot)/$(arch)/sol-$(sys_rel)-$(arch)-toolchain.cmake 
	@echo $@ done

# fetch-toolchain-$arch && make-toolchain-$arch
install-toolchain-$(arch): $(getcompilers)-toolchain-$(arch)
	$(MAKE) arch=$(arch) cmakeenv
	@echo $@ done

toolchain: install-toolchain-$(arch)

source/cfacter/.git: | source source/cfacter
	$(git) clone git@github.com:puppetlabs/cfacter.git source/cfacter/


build/$(arch)/cfacter/._.config: | source/cfacter/.git build/$(arch)/cfacter
	cd build/$(arch)/cfacter && $(cmake) ../../../source/cfacter

#build/$(arch)/cfacter/._.make: build/$(arch)/cfacter/._.config
#	cd build/$(arch)/cfacter && $(gmake)

facter-i386: build/$(arch)/cfacter/._.make

facter: facter-$(arch) 

# ENTRY
uninstall: clobber
	rm -f install/sparc/._.hinstall source/boost_$(boost_ver)/._.hinstall  install/$(arch)/cmake-$(cmake_ver)/._.install install/$(arch)/gcc-$(gcc_ver)/._.install

# ENTRY
# To compile native cfacter, we can just build the native cross-compiler
# toolchain. However, to build the cross compiled sparc cfacter, we need to
# build the native toolchain first, getting us the native cmake, and build the
# cross compiled toolchain, and finally use both together to produce our
# cross-compiled cfacter

cfacter: cfacter-$(arch)

deps: boost yaml-cpp
	@echo $@ done

# being lazy again. I promice to make them follow the dependencies correctly
# later.
cfacter-sparc:
	$(MAKE) arch=i386 toolchain getcompilers=$(getcompilers)
	$(MAKE) arch=sparc toolchain getcompilers=$(getcompilers)
	$(MAKE) arch=sparc deps
	$(MAKE) arch=sparc facter

cfacter-i386:
	$(MAKE) arch=i386 toolchain getcompilers=$(getcompilers)
	$(MAKE) arch=i386 deps
	$(MAKE) arch=i386 facter

$(mydirs): ; /bin/mkdir -p $@

