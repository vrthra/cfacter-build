binutils_ver=2.23.2
gcc_ver=4.8.2
cmake_ver=3.0.0
arch=i386

sourceurl=http://enterprise.delivery.puppetlabs.net/sources/solaris

include Makefile.$(arch)

myprojects=binutils gcc cmake
myversions=$(binutils_ver) $(gcc_ver) $(cmake_ver)

projects=$(join $(addsuffix -,$(myprojects)),$(myversions))
builds=$(addprefix build/$(arch)/,$(projects))
source=$(addprefix source/,$(projects))

mydirs=build/$(arch) source

make_=$(addsuffix /._.make,$(builds))
get_=$(addsuffix .tar.gz,$(addprefix source/,$(projects)))
patch_=$(addsuffix /._.patch,$(builds))
config_=$(addsuffix /._.config,$(builds))
checkout_=$(addsuffix /._.checkout,$(builds))

tar=/usr/sfw/bin/gtar
gzip=/bin/gzip

as=$(prefix)/bin/$(target)-as
ld=$(prefix)/bin/$(target)-ld


.PRECIOUS: $(make_) $(get_) $(patch_) $(config_) $(checkout_)

$(mydirs): ; mkdir -p $@

all: $(make_)
	@echo $* done

source/%.tar.gz: | source
	wget -c -P source/ $(sourceurl)/$*.tar.gz

source/%/._.checkout: | source/%.tar.gz build/$(arch)
	cat source/$*.tar.gz | (cd source/ && $(gzip) -dc | $(tar) -xpf - )
	touch $@

build/$(arch)/binutils-$(binutils_ver)/._.patch: | source/binutils-$(binutils_ver)/._.checkout
	wget -c -P source/ $(sourceurl)/patches/binutils-2.23.2-common.h.patch
	wget -c -P source/ $(sourceurl)/patches/binutils-2.23.2-ldlang.c.patch
	cat source/binutils-2.23.2-common.h.patch | (cd source/binutils-$(binutils_ver)/include/elf && patch -p0)
	cat source/binutils-2.23.2-ldlang.c.patch | (cd source/binutils-$(binutils_ver)/ && patch -p0)
	touch $@

source/gcc-$(gcc_ver)/._.patch: |  source/gcc-$(gcc_ver)/._.checkout
	cd ./source/gcc-$(gcc_ver) && ./contrib/download_prerequisites
	touch $@


build/$(arch)/binutils-$(binutils_ver)/._.config: | source/binutils-$(binutils_ver)/._.patch
	rm -rf ./build/$(arch)/binutils-$(binutils_ver); mkdir -p ./build/$(arch)/binutils-$(binutils_ver)
	cd ./build/$(arch)/binutils-$(binutils_ver) && \
		../../../source/binutils-$(binutils_ver)/configure \
			--target=$(target) --prefix=$(prefix) $(sysroot) --disable-nls -v > .x.config.log
	touch $@

build/$(arch)/gcc-$(gcc_ver)/._.config: | build/$(arch)/gcc-$(gcc_ver)/._.patch
	rm -rf ./build/$(arch)/gcc-$(gcc_ver)-x; mkdir -p ./build/$(arch)/gcc-$(gcc_ver)-x
	cd ./build/$(arch)/gcc-$(gcc_ver)-x && \
		../../../build/$(arch)/gcc-$(gcc_ver)/configure \
			--target=$(target) --prefix=$(prefix) $(sysroot) --disable-nls --enable-languages=c,c++ \
			--disable-libgcj \
			-v > .x.config.log
	touch $@

			# --with-gnu-as --with-as=$(as) --with-gnu-ld --with-ld=$(ld)

build/$(arch)/%/._.patch: | build/$(arch)/%/._.checkout
	touch $@


build/$(arch)/%/._.config: | build/$(arch)/%/._.patch
	touch $@


build/$(arch)/%/._.make: | build/$(arch)/%/._.config
	$(MAKE)
	touch $@


clobber:
	rm -rf build/$(arch)
