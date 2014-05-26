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


.DEFAULT_GOAL := all

CFLAGS=-c -Wall -I./include
CFLAGS_APPLE=$(CFLAGS)
ARCH_FLAGS_OS_X=-arch i386 -arch x86_64

STANDALONE_DIR=/usr/local/bin/

LDFLAGS_APPLE=$(LDFLAGS) 

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


all:
ifeq ($(UNAME),Darwin)
	$(CC) $(CFLAGS_APPLE) $(ARCH_FLAGS_OS_X) $(STANDALONE_FILE_LIST)
	$(CC) $(LDFLAGS_APPLE) $(ARCH_FLAGS_OS_X) *.o -o $(STANDALONE_EXECUTABLE_NAME)
else
	$(CC) $(CFLAGS) $(STANDALONE_FILE_LIST)
	$(CC) $(LDFLAGS) *.o -o $(STANDALONE_EXECUTABLE_NAME)
endif

install: 
	sudo cp $(STANDALONE_EXECUTABLE_NAME) $(STANDALONE_DIR)
	sudo chown root:wheel $(STANDALONE_DIR)$(STANDALONE_EXECUTABLE_NAME)
	sudo chmod 755 $(STANDALONE_DIR)$(STANDALONE_EXECUTABLE_NAME)
	
clean:
	rm -f *.o
	rm -f *.a
	rm -f *.lo
	rm -f *.lai
	rm -rf .libs
	rm -f $(STANDALONE_EXECUTABLE_NAME)

