#
#
# Makefile (for the rabin polynomial library)
# Created by Joel Lawrence Tucci on 09-March-2011.
# 
# Copyright (c) 2011 Joel Lawrence Tucci
# All rights reserved.
# 
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
# 
# Redistributions of source code must retain the above copyright notice,
# this list of conditions and the following disclaimer.
# 
# Redistributions in binary form must reproduce the above copyright
# notice, this list of conditions and the following disclaimer in the
# documentation and/or other materials provided with the distribution.
# 
# Neither the name of the project's author nor the names of its
# contributors may be used to endorse or promote products derived from
# this software without specific prior written permission.
# 
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
# "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
# LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
# FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
# HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
# SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
# TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
# PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
# LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
# NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
# SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#

libdir=/usr/local/lib

UNAME := $(shell uname)

CC=gcc

#TODO: figure this out automatically
IOS_VERSION=4.3
IOS_SIM_SDK_LOC=SDKs/iPhoneSimulator$(IOS_VERSION).sdk/
IOS_DEV_SDK_LOC=SDKs/iPhoneOS$(IOS_VERSION).sdk/

#Place to put the various compiled libraries, we need to keep the sim and device libraries in separate directories
IOS_DEV_DIR=ios_dev_libs/
IOS_SIM_DIR=ios_sim_libs/

#Need the various ios dev and sim directories
IOS_PLAT_PREFIX=/Developer/Platforms/
IOS_DEV_PLAT=$(IOS_PLAT_PREFIX)iPhoneOS.platform/Developer/
IOS_SIM_PLAT=$(IOS_PLAT_PREFIX)iPhoneSimulator.platform/Developer/

#The directories relative structure is the same(at least for the time being)
IOS_CC_SUFFIX=usr/bin/gcc
IOS_LIBTOOL_SUFFIX=usr/bin/libtool

IOS_SIM_ARCH=i386
IOS_DEV_ARCH=armv6 armv7

IOS_SIM_ARCH_FLAG=-arch $(IOS_SIM_ARCH)
IOS_DEV_ARCH_FLAG=-arch armv6 -arch armv7

IOS_DEV_LIBTOOL_CMD=$(IOS_DEV_PLAT)$(IOS_LIBTOOL_SUFFIX)
IOS_SIM_LIBTOOL_CMD=$(IOS_SIM_PLAT)$(IOS_LIBTOOL_SUFFIX)


#Necessary for newer versions of llvm
OS_X_VER=10.6
OS_X_SDK_DIR=/Developer/SDKs/MacOSX$(OS_X_VER).sdk/

CFLAGS=-c -Wall -I./include
CFLAGS_APPLE=$(CFLAGS) -I $(OS_X_SDK_DIR)usr/include/
ARCH_FLAGS_OS_X=-arch i386 -arch x86_64

STANDALONE_DIR=/usr/local/bin/

IOS_LIB_NAME=rabin_polynomial.o
LDFLAGS_APPLE=$(LDFLAGS) -framework Foundation

STANDALONE_FILE_LIST=rabin_polynomial.c rabin_polynomial_main.c
STANDALONE_EXECUTABLE_NAME=rabin_fingerprint

define compile_rule
	libtool --mode=compile \
	$(CC) $(CFLAGS) -c $<
endef
define link_rule
	libtool --mode=link \
	$(CC) $(LDFLAGS) -o $@ $^ $(LDLIBS)
endef

LIBS = librabinpoly.lai
librabinpoly_OBJS = rabin_polynomial.lo

rabin_polynomial.lo: rabin_polynomial.c
	$(call compile_rule)

librabinpoly.lai: $(librabinpoly_OBJS)
	$(call link_rule)

install/$(LIBS): $(LIBS)
	libtool --mode=install \
	install -c $(notdir $@) $(libdir)/$(notdir $@)
install: $(addprefix install/,$(LIBS))
	libtool --mode=finish $(libdir)

install_standalone: 
	sudo cp $(STANDALONE_EXECUTABLE_NAME) $(STANDALONE_DIR)
	sudo chown root:wheel $(STANDALONE_DIR)$(STANDALONE_EXECUTABLE_NAME)
	sudo chmod 755 $(STANDALONE_DIR)$(STANDALONE_EXECUTABLE_NAME)
	

standalone:
ifeq ($(UNAME),Darwin)
	$(CC) $(CFLAGS_APPLE) $(ARCH_FLAGS_OS_X) $(STANDALONE_FILE_LIST)
	$(CC) $(LDFLAGS_APPLE) $(ARCH_FLAGS_OS_X) -isysroot $(OS_X_SDK_DIR) *.o -o $(STANDALONE_EXECUTABLE_NAME)
else
	$(CC) $(CFLAGS) $(STANDALONE_FILE_LIST)
	$(CC) $(LDFLAGS) *.o -o $(STANDALONE_EXECUTABLE_NAME)
endif


iossim: 
	mkdir -p $(IOS_SIM_DIR)
	$(IOS_SIM_PLAT)$(IOS_CC_SUFFIX) $(CFLAGS_APPLE) $(IOS_SIM_ARCH_FLAG) -isysroot  $(IOS_SIM_PLAT)$(IOS_SIM_SDK_LOC) rabin_polynomial.c
	$(IOS_SIM_LIBTOOL_CMD) -arch_only $(IOS_SIM_ARCH) $(LDFLAGS_APPLE) -L $(IOS_LIB_NAME) -o $(IOS_SIM_DIR)libRabinPoly.a

iosdev: 
	mkdir -p $(IOS_DEV_DIR)	
	$(IOS_DEV_PLAT)$(IOS_CC_SUFFIX) $(CFLAGS_APPLE) $(IOS_DEV_ARCH_FLAG) -isysroot  $(IOS_DEV_PLAT)$(IOS_DEV_SDK_LOC) rabin_polynomial.c
	for architecture in $(IOS_DEV_ARCH) ; do \
	 $(IOS_DEV_LIBTOOL_CMD) -arch_only $$architecture $(LDFLAGS_APPLE) -L $(IOS_LIB_NAME) -o $(IOS_DEV_DIR)libRabinPoly_$$architecture.a ; \
	done
#Now join the archs together in a single library.
	$(IOS_DEV_LIBTOOL_CMD) -static $(foreach architecture,$(IOS_DEV_ARCH),$(IOS_DEV_DIR)libRabinPoly_$(architecture).a) -o $(IOS_DEV_DIR)libRabinPoly.a

clean:
	rm -f *.o
	rm -f *.a
	rm -f *.lo
	rm -f *.lai
	rm -rf .libs
	rm -rf $(IOS_SIM_DIR)
	rm -rf $(IOS_DEV_DIR)
	rm -f $(STANDALONE_EXECUTABLE_NAME)

