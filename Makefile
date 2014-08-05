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

tar=/usr/sfw/bin/gtar
gzip=/bin/gzip

.PRECIOUS: $(make_) $(get_) $(patch_) $(config_)

$(mydirs): ; mkdir -p $@

all: $(make_)
	@echo $* done

source/%.tar.gz: source
	wget -c -P source/ $(sourceurl)/$*.tar.gz

build/$(arch)/%/._.checkout: source/%.tar.gz | build/$(arch)
	cat $< | (cd build/$(arch)  && $(gzip) -dc | $(tar) -xpf - )
	@touch $@


build/$(arch)/%/._.patch: build/$(arch)/%/._.checkout
	echo touch $@


build/$(arch)/%/._.config: build/$(arch)/%/._.patch
	echo touch $@


build/$(arch)/%/._.make: build/$(arch)/%/._.config
	echo touch $@
