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
# ./source/${arch:sparc,i386}/root          -- contains sysroot headers
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
binutils_ver=2.23.2
gcc_ver=4.8.2
cmake_ver=3.0.0
boost_ver=1_55_0
yaml_ver=0.5.1
# -----------------------------------------------------------------------------
# These are the projects we are currently building. Where possible, try to
# follow the $project-$ver format, if not, use the boost example.

myprojects=binutils gcc cmake
myversions=$(binutils_ver) $(gcc_ver) $(cmake_ver)
projects=$(join $(addsuffix -,$(myprojects)),$(myversions)) boost_$(boost_ver)
# -----------------------------------------------------------------------------
#  These are arch dependent definitions for native and cross compilers.
#  These should be moved to their own files, and included with
#  `include Makefile.$(arch)` if ever the number of definitions increases
#  further or any generic makefile rules are added for one of the platforms.
#  Similarly, add `include Makefile.$(sys_rel)`
#  and `include Makefile.$(arch).$(sys_rel)` if necessary.

prefix=/opt/gcc-$(arch)
ifeq (sparc,${arch})
	target=sparc-sun-solaris$(solaris_version)
	sysroot=--with-sysroot=$(prefix)/sysroot
endif
ifeq (i386,${arch})
	target=i386-pc-solaris$(solaris_version)
	sysroot=
endif
# -----------------------------------------------------------------------------
# The URL from where we get most of our sources.
sourceurl=http://enterprise.delivery.puppetlabs.net/sources/solaris
# -----------------------------------------------------------------------------
#  A few internal definitions. sys_rel decides whether
#  we are building solaris 10 or solaris 11. Note that if we set sys_rel
#  to 11 on a solaris 10 machine, gcc generates a cross compiler,
#  (and v.v. for s11).

sys_rel:=$(subst 5.,,$(shell uname -r))
solaris_version=2.$(sys_rel)

# The source/ directory ideally should not contain arch dependent files since
# it is used mostly for extracting sources (an exception is the headers which
# are arch dependent but still sources). On the other hand, our builds have
# separate directories for each $arch
builds=$(addprefix build/$(arch)/,$(projects)) 
source=$(addprefix source/,$(projects))

# our touch files, which indicate that specific actions have completed
# without errors.
make_=$(addsuffix /._.make,$(builds))
get_=$(addsuffix .tar.gz,$(addprefix source/,$(projects)))
toolchain_=$(addsuffix ._.cmakeenv, source/$(arch)/)
patch_=$(addsuffix /._.patch,$(builds))
config_=$(addsuffix /._.config,$(builds))
checkout_=$(addsuffix /._.checkout,$(builds))

# Asking make not to delete any of our intermediate touch files.
.PRECIOUS: $(make_) $(get_) $(patch_) $(config_) $(checkout_) $(toolchain_)
# -----------------------------------------------------------------------------
ar=/usr/ccs/bin/ar
tar=/usr/sfw/bin/gtar
gzip=/bin/gzip
bzip2=/bin/bzip2
patch=/bin/gpatch
rsync=/bin/rsync

as=$(prefix)/$(target)/bin/as
ld=$(prefix)/$(target)/bin/ld
# -----------------------------------------------------------------------------
# $mydirs, and the make rule make sure that our directories are created before
# they are needed. To make use of this, add the directory here, and in the
# target, use `<target>: | <dirname>` incantation to ensure that the directory
# exists. (Notice the use of '|' to ensure that our targets do not get rebuilt
# unnecessarily)

sysdirs=/opt/gcc-$(arch)/sysroot /usr/local
mydirs=source build $(source) $(builds) \
			 build/$(arch)  source/$(arch) \
			 source/$(arch)/root $(sysdirs)
$(mydirs): ; mkdir -p $@
# -----------------------------------------------------------------------------
# some trickery to use array path elements
e:=
space:=$(e) $(e)
path=$(prefix)/bin \
		 $(prefix)/$(target)/bin \
		 /opt/gcc-$(arch)/bin \
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
# -----------------------------------------------------------------------------

# ENTRY
all:
	@echo usage: $(MAKE) arch=$(arch) cfacter

# -----------------------------------------------------------------------------
#  Generic definitions, override them to implement any specific behavior.

source/%.tar.gz: | source
	wget -q -c -P source/ $(sourceurl)/$*.tar.gz

source/%/._.checkout: | source/%.tar.gz build/$(arch)/%
	cat source/$*.tar.gz | (cd source/ && $(gzip) -dc | $(tar) -xpf - )
	touch $@

# ENTRY
# use `gmake arch=sparc headers` just extract the headers. The following rules
headers: source/$(arch)/._.headers
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
build/$(arch)/%/._.install: | build/$(arch)/%/._.make
	cd build/$(arch)/$*/ && $(MAKE) install > .x.install.log
	touch $@

# ENTRY
%-cmakeenv: | source/%/._.cmakeenv source/%
	@echo $@ done

source/%/._.cmakeenv: | source/sol-$(sys_rel)-%-toolchain.cmake /opt/gcc-%/
	cp source/sol-$(sys_rel)-$*-toolchain.cmake /opt/gcc-$*/
	touch $@

# ENTRY
# Clean out our builds. Note that we dont touch our sources which should not
# be dirty.
clean:
	rm -rf build/$(arch)

# ENTRY
# Clean out the installed packages. Unfortunately, we also need to
# redo the headers 
clobber:
	rm -rf /opt/gcc-sparc /opt/gcc-i386 /usr/local/boost_$(boost_ver)

prepare-10:
	@echo

prepare-11:
	pkg install developer/gcc-45
	pkg install system/header

# ENTRY
# This is to be the only command that requires `sudo` or root.
# Use `sudo gmake prepare` to invoke.
prepare: prepare-$(sys_rel)
	rm -rf /opt/gcc-sparc /opt/gcc-i386
	mkdir -p /opt/gcc-sparc /opt/gcc-i386 /usr/local
	chmod 777 /opt/gcc-sparc /opt/gcc-i386 /usr/local

# extract the headers
source/%/._.headers: | source/%.sysroot.tar.gz /opt/gcc-%/sysroot
	cat source/$*.sysroot.tar.gz | (cd /opt/gcc-$*/sysroot && $(gzip) -dc | $(tar) -xpf - )
	touch $@


# we have a few extra patches for binutils, so overriding the default make rules.
source/binutils-$(binutils_ver)/._.patch: | source/binutils-$(binutils_ver)/._.checkout
	wget -q -c -P source/ $(sourceurl)/patches/binutils-2.23.2-common.h.patch
	wget -q -c -P source/ $(sourceurl)/patches/binutils-2.23.2-ldlang.c.patch
	cat source/binutils-2.23.2-common.h.patch | (cd source/binutils-$(binutils_ver)/include/elf && $(patch) -p0)
	cat source/binutils-2.23.2-ldlang.c.patch | (cd source/binutils-$(binutils_ver)/ && $(patch) -p0)
	touch $@

# one patch for gcc too.
source/gcc-$(gcc_ver)/._.patch: |  source/gcc-$(gcc_ver)/._.checkout
	wget -q -c -P source/ $(sourceurl)/patches/gcc-contrib-4.8.3.patch
	cat source/gcc-contrib-4.8.3.patch | (cd ./source/gcc-$(gcc_ver) && $(patch) -p1 )
	cd ./source/gcc-$(gcc_ver) && ./contrib/download_prerequisites 2>&1 | cat > .x.patch.log
	touch $@

# config rules for binutils
build/$(arch)/binutils-$(binutils_ver)/._.config: | source/binutils-$(binutils_ver)/._.patch ./build/$(arch)/binutils-$(binutils_ver)
	cd ./build/$(arch)/binutils-$(binutils_ver) && \
		../../../source/binutils-$(binutils_ver)/configure \
			--target=$(target) --prefix=$(prefix) $(sysroot) --disable-nls -v > .x.config.log
	touch $@

# GCC depends on binutils being already installed.
build/$(arch)/gcc-$(gcc_ver)/._.config: build/$(arch)/binutils-$(binutils_ver)/._.install

# The sparc cross compiler requires the sparc system headers already present.
build/sparc/gcc-$(gcc_ver)/._.config: source/sparc/._.headers

build/$(arch)/gcc-$(gcc_ver)/._.config: | source/gcc-$(gcc_ver)/._.patch ./build/$(arch)/gcc-$(gcc_ver)
	cd ./build/$(arch)/gcc-$(gcc_ver) && \
		../../../source/gcc-$(gcc_ver)/configure \
			--target=$(target) --prefix=$(prefix) $(sysroot) --disable-nls --enable-languages=c,c++ \
			--disable-libgcj \
			--with-gnu-as --with-as=$(as) --with-gnu-ld --with-ld=$(ld) \
			-v > .x.config.log
	touch $@

build/$(arch)/cmake-$(cmake_ver)/._.config: build/$(arch)/gcc-$(gcc_ver)/._.install

build/i386/cmake-$(cmake_ver)/._.config: | source/cmake-$(cmake_ver)/._.patch ./build/i386/cmake-$(cmake_ver)
	cd ./build/i386/cmake-$(cmake_ver) && env CC=$(prefix)/bin/gcc \
		    CXX=$(prefix)/bin/g++ \
		    MAKE=$(MAKE) CFLAGS="-I$(prefix)/include" \
				LD_LIBRARY_PATH="$(prefix)/lib" \
				LDFLAGS="-L$(prefix)/lib -R$(prefix)/lib" \
			../../../source/cmake-$(cmake_ver)/bootstrap --prefix=$(prefix) \
			    --datadir=/share/cmake --docdir=/share/doc/cmake-$(cmake_ver) \
					--mandir=/share/man --verbose > .x.config.log
	touch $@

build/sparc/cmake-$(cmake_ver)/._.config: | source/cmake-$(cmake_ver)/._.patch ./build/$(arch)/cmake-$(cmake_ver)
	echo "Can not build cmake for sparc" && exit 1

source/boost_$(boost_ver).tar.bz2: | source
	wget -q -c -P source/ 'http://ftp.osuosl.org/pub/blfs/svn/b/boost_$(boost_ver).tar.bz2'

source/boost_$(boost_ver)/._.checkout: | build/$(arch)/boost_$(boost_ver) source/boost_$(boost_ver).tar.bz2
	cat source/boost_$(boost_ver).tar.bz2 | (cd source/ && $(bzip2) -dc | $(tar) -xpf - )
	touch $@

source/boost_$(boost_ver)/._.hinstall: source/boost_$(boost_ver)/._.checkout /usr/local
	cat source/boost_$(boost_ver).tar.bz2 | (cd /usr/local/ && $(bzip2) -dc | $(tar) -xpf - )
	touch $@

build/$(arch)/boost_$(boost_ver)/._.config: source/boost_$(boost_ver)/._.checkout build/$(arch) source/boost_$(boost_ver)/._.hinstall
	cd source/boost_$(boost_ver)/tools/build/v2 && ./bootstrap.sh --with-toolset=gcc
	touch $@

source/boost_$(boost_ver)/._.b2install: source/boost_$(boost_ver)/._.checkout
	cd source/boost_$(boost_ver)/tools/build/v2 && ./b2 install --prefix=$(prefix) toolset=gcc
	touch $@

build/$(arch)/boost_$(boost_ver)/._.make: build/$(arch)/boost_$(boost_ver)/._.config source/boost_$(boost_ver)/._.b2install
	cd source/boost_$(boost_ver)/ && $(prefix)/bin/b2 --build-dir=build/$(arch)/boost_$(boost_ver) toolset=gcc stage
	touch $@

build/$(arch)/boost_$(boost_ver)/._.install: build/$(arch)/boost_$(boost_ver)/._.make
	touch $@

# ENTRY
boost: | build/$(arch)/boost_$(boost_ver)/._.make
	@echo done

# ENTRY
toolchain-sparc:  build/i386/cmake-$(cmake_ver)/._.install build/$(arch)/gcc-$(gcc_ver)/._.install

# ENTRY
toolchain-i386:  build/i386/cmake-$(cmake_ver)/._.install build/$(arch)/gcc-$(gcc_ver)/._.install

# ENTRY
uninstall: clobber
	rm -f source/sparc/._.hinstall source/boost_$(boost_ver)/._.hinstall  build/$(arch)/cmake-$(cmake_ver)/._.install build/$(arch)/gcc-$(gcc_ver)/._.install

# ENTRY
# To compile native cfacter, we can just build the native cross-compiler
# toolchain. However, to build the cross compiled sparc cfacter, we need to
# build the native toolchain first, getting us the native cmake, and build the
# cross compiled toolchain, and finally use both together to produce our
# cross-compiled cfacter

cfacter: cfacter-$(arch)

cfacter-sparc:
	$(MAKE) toolchain-i386
	$(MAKE) toolchain-sparc

cfacter-i386:
	$(MAKE) toolchain-i386


