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
#  The general variables that may be modified from the environment. The most
#  important is the arch changes whether a native compiler or a cross-compiler
#  is built.


arch=i386
# -----------------------------------------------------------------------------
# These are the projects we are currently building. Where possible, try to
# follow the $project-$ver format, if not, use the boost example.

projects=
# -----------------------------------------------------------------------------
#  These are arch dependent definitions for native and cross compilers.
#  These should be moved to their own files, and included with
#  `include Makefile.$(arch)` if ever the number of definitions increases
#  further or any generic makefile rules are added for one of the platforms.
#  Similarly, add `include Makefile.$(sys_rel)`
#  and `include Makefile.$(arch).$(sys_rel)` if necessary.

define mytarget
$(if $(findstring sparc,$(1)),sparc-sun-solaris,i386-pc-solaris)$(solaris_version)
endef

installroot=/opt/pl-build-tools
prefix=$(installroot)/$(arch)
target=$(call mytarget,$(arch))
ifeq (sparc,${arch})
	sysroot=--with-sysroot=$(prefix)/sysroot
else
	sysroot=
endif
# -----------------------------------------------------------------------------
# The URL from where we get most of our sources.
sourceurl=http://enterprise.delivery.puppetlabs.net/sources/solaris
toolurl=https://pl-build-tools.delivery.puppetlabs.net/solaris
# -----------------------------------------------------------------------------
#  A few internal definitions. sys_rel decides whether
#  we are building solaris 10 or solaris 11. Note that if we set sys_rel
#  to 11 on a solaris 10 machine, gcc generates a cross compiler,
#  (and v.v. for s11).

sys_rel:=$(subst 5.,,$(shell uname -r))
solaris_version=2.$(sys_rel)

# how we want to get our compiler suite?
# use `gmake getcompilers=fetch __` to get it from the precompiled tarballs in
# remote repo. Use `gmake getcompilers=make __` to make use of locally
# compiled suite.

getcompilers:=fetch
export getcompilers

# The source/ directory ideally should not contain arch dependent files since
# it is used mostly for extracting sources. On the other hand, our builds have
# separate directories for each $arch
builds=$(addprefix build/$(arch)/,$(projects)) 
installs=$(addprefix install/$(arch)/,$(projects)) 
source=$(addprefix source/,$(projects))

# our touch files, which indicate that specific actions have completed
# without errors.
make_=$(addsuffix /._.make,$(builds))
get_=$(addsuffix .tar.gz,$(addprefix source/,$(projects)))
toolchain_=$(addsuffix ._.cmakeenv, source/$(arch)/)
patch_=$(addsuffix /._.patch,$(builds))
config_=$(addsuffix /._.config,$(builds))
checkout_=$(addsuffix /._.checkout,$(builds))
install_=$(addsuffix /._.install,$(installs))

# Asking make not to delete any of our intermediate touch files.
.PRECIOUS: $(make_) $(get_) $(patch_) $(config_) $(install_) \
	$(checkout_) $(toolchain_) 
# -----------------------------------------------------------------------------
ar=/usr/ccs/bin/ar
tar=/usr/sfw/bin/gtar
gzip=/bin/gzip
bzip2=/bin/bzip2
patch=/bin/gpatch
rsync=/bin/rsync
wget=wget -q -c --no-check-certificate
git=/opt/csw/bin/git

as=$(prefix)/$(target)/bin/as
ld=$(prefix)/$(target)/bin/ld
cmake=$(installroot)/i386/bin/cmake
# -----------------------------------------------------------------------------
# $mydirs, and the make rule make sure that our directories are created before
# they are needed. To make use of this, add the directory here, and in the
# target, use `<target>: | <dirname>` incantation to ensure that the directory
# exists. (Notice the use of '|' to ensure that our targets do not get rebuilt
# unnecessarily)

sysdirs=$(installroot)/$(arch)/sysroot
mydirs=source build install $(source) $(builds) $(installs) \
			 build/$(arch)  source/$(arch) \
			 source/$(arch)/root $(sysdirs) \
			 source/cfacter build/$(arch)/cfacter
# -----------------------------------------------------------------------------
# some trickery to use array path elements
e:=
space:=$(e) $(e)
path=$(prefix)/bin \
		 $(prefix)/$(target)/bin \
		 $(installroot)/$(arch)/bin \
		 /usr/ccs/bin \
		 /usr/gnu/bin \
		 /usr/bin \
		 /bin \
		 /sbin \
		 /usr/sbin \
		 /usr/sfw/bin \
		 /usr/perl5/5.8.4/bin

# ensure that the path is visible to our build as a shell environment variable.
export PATH:=$(subst $(space),:,$(path))
export BOOST_ROOT:=$(installroot)/boost_$(boost_ver)
export YAMLCPP_ROOT=/opt/pl-build
# -----------------------------------------------------------------------------

# ENTRY
all:
	@echo "usage:\tsudo $(MAKE) prepare"
	@echo "\t$(MAKE) arch=$(arch) cfacter"
	@echo
	@echo "remove:\tsudo $(MAKE) uninstall"


# -----------------------------------------------------------------------------
#  Generic definitions, override them to implement any specific behavior.

source/%.tar.gz: | source
	$(wget) -P source/ $(sourceurl)/$*.tar.gz

source/%/._.checkout: | source/%.tar.gz build/$(arch)/%
	cat source/$*.tar.gz | (cd source/ && $(gzip) -dc | $(tar) -xf - )
	touch $@

# ENTRY
# use `gmake arch=sparc headers` just extract the headers. The following rules
headers: build/$(arch) build/$(arch)/._.headers
	@echo $@ done

# by default we dont have any patches, so override it for projects that have
# it.
source/%/._.patch: | source/%/._.checkout
	touch $@

# we cant predict the options to be passed to config, so we only have
# a skeletal rule here. Override them for specific projects.
build/$(arch)/%/._.config: | source/%/._.patch
	touch $@

# In general make should be just make
build/$(arch)/%/._.make: | build/$(arch)/%/._.config
	cd build/$(arch)/$*/ && $(MAKE) > .x.make.log
	touch $@

# And make install should work.
install/$(arch)/%/._.install: | build/$(arch)/%/._.make install/$(arch)/%
	cd build/$(arch)/$*/ && $(MAKE) install > .x.install.log
	touch $@

# ENTRY
cmakeenv: $(installroot)/$(arch)/sol-$(sys_rel)-$(arch)-toolchain.cmake 
	@echo $@ done

.PRECIOUS: $(installroot)/$(arch)/sol-$(sys_rel)-$(arch)-toolchain.cmake

$(installroot)/$(arch)/sol-$(sys_rel)-$(arch)-toolchain.cmake: source/sol-$(sys_rel)-$(arch)-toolchain.cmake | $(installroot)/$(arch)
	cp source/sol-$(sys_rel)-$(arch)-toolchain.cmake $(installroot)/$(arch)/

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

# extract the headers
build/%/._.headers: | source/%.sysroot.tar.gz $(installroot)/%/sysroot
	cat source/$*.sysroot.tar.gz | (cd $(installroot)/$*/sysroot && $(gzip) -dc | $(tar) -xf - )
	touch $@

include Makefile.binutils
include Makefile.gcc
include Makefile.cmak
include Makefile.boost
include Makefile.yamlcpp

# ENTRY
# We use the native cmake to build our cross-compiler, which unfortunately
# means that we have to build the native toolchain aswell
make-toolchain-%: install/i386/cmake-$(cmake_ver)/._.install install/%/gcc-$(gcc_ver)/._.install
	@echo $@ done

update-toolchain:
	(cd /opt/ && $(tar) -cf - pl-build/i386 ) | $(gzip) -c > source/sol-$(sys_rel)-i386-compiler.tar.gz
	(cd /opt/ && $(tar) -cf - pl-build/sparc ) | $(gzip) -c > source/sol-$(sys_rel)-sparc-compiler.tar.gz
	(cd /opt/ && $(tar) -cf - pl-build ) | $(gzip) -c > source/sol-$(sys_rel)-i386-sparc-compilers.tar.gz

source/sol-$(sys_rel)-$(arch)-compiler.tar.gz: | source
	$(wget) -P source/ $(toolurl)/$(sys_rel)/sol-$(sys_rel)-$(arch)-compiler.tar.gz

$(installroot)/$(arch)/bin/$(target)-gcc: | source/sol-$(sys_rel)-$(arch)-compiler.tar.gz
	@echo start $@
	cat source/sol-$(sys_rel)-$(arch)-compiler.tar.gz | (cd /opt/ && $(gzip) -dc | $(tar) -xf - )
	@echo done $@

fetch-toolchain-i386: | $(installroot)/i386/bin/$(call mytarget,i386)-gcc
	@echo done $@

fetch-toolchain-sparc: | $(installroot)/sparc/bin/$(call mytarget,sparc)-gcc
	@echo done $@

# fetch-toolchain-$arch && make-toolchain-$arch
install-toolchain-$(arch): $(getcompilers)-toolchain-$(arch)
	@echo $@ done

toolchain: install-toolchain-$(arch)

source/cfacter/.git: | source source/cfacter
	$(git) clone git@github.com:puppetlabs/cfacter.git source/cfacter/


build/$(arch)/cfacter/._.config: | source/cfacter/.git build/$(arch)/cfacter
	cd build/$(arch)/cfacter && $(cmake) ../../../source/cfacter

#build/$(arch)/cfacter/._.make: build/$(arch)/cfacter/._.config
#	cd build/$(arch)/cfacter && $(gmake)

facter-i386: | build/$(arch)/cfacter/._.make

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

cfacter-sparc:
	$(MAKE) arch=i386 toolchain getcompilers=$(getcompilers)
	$(MAKE) arch=i386 cmakeenv
	$(MAKE) arch=sparc toolchain getcompilers=$(getcompilers)
	$(MAKE) arch=sparc cmakeenv
	$(MAKE) arch=i386 deps
	$(MAKE) arch=i386 facter

cfacter-i386:
	$(MAKE) arch=i386 toolchain getcompilers=$(getcompilers)
	$(MAKE) arch=i386 cmakeenv
	$(MAKE) arch=i386 deps
	$(MAKE) arch=i386 facter



$(mydirs): ; /bin/mkdir -p $@
