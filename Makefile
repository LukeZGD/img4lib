# undefined = use OpenSSL

# 1 = use included sources

# CORECRYPTO removed

# Darwin can use CommonCrypto instead of OpenSSL

# COMMONCRYPTO = 1

CC = clang
LD = clang
AR = ar
ARFLAGS = crus

ARCH ?= $(shell uname -m)
OS := $(shell uname -s)

BUILD_DIR = build/$(ARCH)
OBJ_DIR = $(BUILD_DIR)/obj

CFLAGS = -Wall -W -pedantic
CFLAGS += -Wno-variadic-macros -Wno-multichar -Wno-four-char-constants -Wno-unused-parameter
CFLAGS += -O2 -I. -g -DiOS10
CFLAGS += -DDER_MULTIBYTE_TAGS=1 -DDER_TAG_SIZE=8
CFLAGS += -D__unused="__attribute__((unused))"
CFLAGS += -Wno-deprecated-declarations

LDFLAGS = -g

ifeq ($(OS),Darwin)
CFLAGS += -arch $(ARCH)
LDFLAGS += -arch $(ARCH)
endif

ifneq (,$(wildcard lzfse/build/bin/liblzfse.a))
# liblzfse.a exists in-tree
CFLAGS += -Ilzfse/src
LDFLAGS += -Llzfse/build/bin
LDLIBS = -llzfse
else
ifneq (,$(wildcard /usr/lib/libcompression.dylib))
# Darwin libcompression is available
CFLAGS += -DUSE_LIBCOMPRESSION
LDLIBS = -lcompression
endif
endif

SOURCES = \
	img4.c

LIBSOURCES = \
	lzss.c

VFSSOURCES = \
	libvfs/vfs_file.c \
	libvfs/vfs_mem.c \
	libvfs/vfs_sub.c \
	libvfs/vfs_enc.c \
	libvfs/vfs_lzss.c \
	libvfs/vfs_lzfse.c \
	libvfs/vfs_img4.c

DERSOURCES = \
	libDER/DER_Encode.c \
	libDER/DER_Decode.c \
	libDER/oids.c

LIBOBJECTS = \
	$(addprefix $(OBJ_DIR)/,$(LIBSOURCES:.c=.o)) \
	$(addprefix $(OBJ_DIR)/,$(DERSOURCES:.c=.o)) \
	$(addprefix $(OBJ_DIR)/,$(VFSSOURCES:.c=.o))

MAINOBJECTS = \
	$(addprefix $(OBJ_DIR)/,$(SOURCES:.c=.o))

OBJECTS = $(MAINOBJECTS) $(LIBOBJECTS)

ifdef COMMONCRYPTO
CFLAGS += -DUSE_COMMONCRYPTO
LDLIBS += -framework Security -framework CoreFoundation
else
LDLIBS += -lcrypto
endif

.PHONY: all clean distclean universal

all: img4 libimg4.a

img4: $(BUILD_DIR)/img4
	cp $< $@

libimg4.a: $(BUILD_DIR)/libimg4.a
	cp $< $@

$(BUILD_DIR)/img4: $(OBJECTS) $(BUILD_DIR)/libimg4.a
	$(LD) -o $@ $(LDFLAGS) $(MAINOBJECTS) $(BUILD_DIR)/libimg4.a $(LDLIBS)

$(BUILD_DIR)/libimg4.a: $(LIBOBJECTS)
	@mkdir -p $(dir $@)
	$(AR) $(ARFLAGS) $@ $(LIBOBJECTS)

$(OBJ_DIR)/%.o: %.c
	@mkdir -p $(dir $@)
	$(CC) -o $@ $(CFLAGS) -c $<

clean:
	-$(RM) -r build
	-$(RM) img4 libimg4.a

distclean: clean

universal:
	$(MAKE) ARCH=arm64
	cp build/arm64/img4 build/img4.arm64
	cp build/arm64/libimg4.a build/libimg4.arm64.a

	$(MAKE) ARCH=x86_64
	cp build/x86_64/img4 build/img4.x86_64
	cp build/x86_64/libimg4.a build/libimg4.x86_64.a

	@mkdir -p build/bin

	lipo -create build/img4.arm64 build/img4.x86_64 \
		-output build/bin/img4

	lipo -create build/libimg4.arm64.a build/libimg4.x86_64.a \
		-output build/bin/libimg4.a

	@echo "Universal binaries created:"
	@lipo -info build/bin/img4
	@lipo -info build/bin/libimg4.a
