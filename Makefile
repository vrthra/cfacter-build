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

# compiler suite
include Makefile.binutils
include Makefile.gcc
include Makefile.cmak

# Dependencies
include Makefile.boost
include Makefile.yamlcpp

# Our toolchain that uses compiler suite
include Makefile.toolchain

# CFacter tha tuses dependencies
include Makefile.facter

# ENTRY
get: $(get_)
	@echo $@ done

checkout: $(checkout_)
	@echo $@ done

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

