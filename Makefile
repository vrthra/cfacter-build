# =============================================================================
# This makefile is setup to build cfacter first building the
# cross-compiler suite (binutils, cross-compilers, cmake) followed by
# cfacter dependencies (boost, yaml, openssl)
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
#	 		  ...  < source/%/._.sync  # not a standard target, Used for places where
#	 		                           # we need source in buld/$arch/%
#	 			< source/%/._.config
#	 				< source/%/._.make
#	 					< source/%/._.install
# =============================================================================
# Global definitions.
include Makefile.global
# -----------------------------------------------------------------------------

# ENTRY
all:
	@echo "usage:"
	@echo "sudo	$(MAKE) prepare -- creates the $(installroot), and gives us complete permissions"
	@echo "	$(MAKE) arch=$(arch) build"
	@echo "remove:"
	@echo "	$(MAKE) clean -- cleans build/ and install/ , does not touch source/"
	@echo "sudo	$(MAKE) clobber -- removes the $(installroot)"


# ENTRY
# Clean out our builds
clean:
	rm -rf build install source

# ENTRY
# Clean out the installed packages. Unfortunately, we also need to
# redo the headers 
clobber:
	rm -rf $(installroot)

prepare-10:
	@echo

prepare-11:
	-pkg install developer/gcc-45
	-pkg install system/header

# ENTRY
# This is to be the only command that requires `sudo` or root.
# Use `sudo gmake prepare` to invoke.
prepare: prepare-$(sys_rel)
	rm -rf $(installroot)
	mkdir -p $(installroot)
	chmod 777 $(installroot)

# Project specific makefiles
# Use the generic as a template for new projects
include projects/Makefile.generic

# compiler suite
include projects/Makefile.binutils
include projects/Makefile.gcc
include projects/Makefile.cmake

# Dependencies
include projects/Makefile.boost
include projects/Makefile.yamlcpp
include projects/Makefile.openssl

# Our toolchain that uses compiler suite
include Makefile.toolchain

# CFacter tha tuses dependencies
include projects/Makefile.cfacter

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

build: build-$(arch)

depends:
	@echo $@ done

build-sparc:
	$(MAKE) arch=i386 toolchain getcompilers=$(getcompilers) $(s)
	$(MAKE) arch=sparc toolchain getcompilers=$(getcompilers) $(s)
	$(MAKE) arch=sparc depends $(s)
	$(MAKE) arch=sparc cfacter $(s)

build-i386:
	$(MAKE) arch=i386 toolchain getcompilers=$(getcompilers) $(s)
	$(MAKE) arch=i386 depends $(s)
	$(MAKE) arch=i386 cfacter $(s)

$(mydirs): ; /bin/mkdir -p $@

# Asking make not to delete any of our intermediate touch files.
.PRECIOUS: $(get_) $(checkout_) $(patch_) \
	         $(config_) $(make_) $(install_)
