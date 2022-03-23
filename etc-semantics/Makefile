# Settings
# --------

SHELL := /bin/bash

BUILD_DIR   := .build
BUILD_LOCAL := $(abspath $(BUILD_DIR)/local)
LOCAL_LIB   := $(BUILD_LOCAL)/lib
LOCAL_BIN   := $(BUILD_LOCAL)/bin
export LOCAL_LIB

INSTALL_PREFIX := /usr
INSTALL_BIN    ?= $(INSTALL_PREFIX)/bin
INSTALL_LIB    ?= $(INSTALL_PREFIX)/lib/ketc

KETC_BIN     := $(BUILD_DIR)$(INSTALL_BIN)
KETC_LIB     := $(BUILD_DIR)$(INSTALL_LIB)
KETC_INCLUDE := $(KETC_LIB)/include
KETC         := ketc

KETC_VERSION     ?= 0.0.1
KETC_RELEASE_TAG ?= v$(KETC_VERSION)-$(shell git rev-parse --short HEAD)

PATH := $(abspath $(KETC_BIN)):$(LOCAL_BIN):$(PATH)
export PATH

.PHONY: all clean build install uninstall \
				test test-concrete

all: build

clean:
	rm -rf $(KETC_BIN) $(KETC_LIB)

distclean:
	rm -rf $(BUILD_DIR)

# Building
# --------

KOMPILE := $(KETC) kompile

ketc_files := etc.md                                         \
			  etc-driver.md                                  \
			  etc-types.md                                   \
			  extension.md                                   \
			  flags.md                                       \
			  simple-instructions.md                         \
			  base/spec.md                                   \
			  width-extensions/width-extensions.md           \
			  width-extensions/byte-operations.md            \
			  width-extensions/doubleword-operations.md      \
			  width-extensions/quadword-operations.md

ketc_includes := $(patsubst %, $(KETC_INCLUDE)/%, $(ketc_files))

$(KETC_INCLUDE)/%.md: %.md
	@mkdir -p $(dir $@)
	install $< $@

KOMPILE_OPTS =

ifneq (,$(RELEASE))
	KOMPILE_OPTS += -O2
endif

ifneq (,$(VERBOSE))
	KOMPILE_OPTS += --verbose
endif

# LLVM
# ----

llvm_dir           := llvm
llvm_main_module   := ETC-DRIVER
llvm_syntax_module := $(llvm_main_module)-SYNTAX
llvm_main_file     := etc-driver.md
llvm_main_filename := $(basename $(notdir $(llvm_main_file)))
llvm_kompiled      := $(llvm_dir)/$(llvm_main_filename)-kompiled/interpreter

$(KETC_LIB)/$(llvm_kompiled): $(ketc_includes) $(KETC_BIN)/ketc
	$(KOMPILE) --backend llvm                 \
		$(llvm_main_file)                     \
		--main-module $(llvm_main_module)     \
		--syntax-module $(llvm_syntax_module) \
		$(KOMPILE_OPTS)

# Haskell
# -------

haskell_dir           := haskell
haskell_main_module   := ETC-DRIVER
haskell_syntax_module := $(haskell_main_module)-SYNTAX
haskell_main_file     := etc-driver.md
haskell_main_filename := $(basename $(notdir $(haskell_main_file)))
haskell_kompiled      := $(haskell_dir)/$(haskell_main_filename)-kompiled/definition.kore

$(KETC_LIB)/$(haskell_kompiled): $(ketc_includes) $(KETC_BIN)/ketc
	$(KOMPILE) --backend haskell                 \
		$(haskell_main_file)                     \
		--main-module $(haskell_main_module)     \
		--syntax-module $(haskell_syntax_module) \
		$(KOMPILE_OPTS)

# Installing
# ----------

install_bins := ketc

install_libs := $(llvm_kompiled)    \
				$(haskell_kompiled) \
				version

build_bins := $(install_bins)
build_libs := $(install_libs)

$(KETC_BIN)/ketc: ketc
	@mkdir -p $(dir $@)
	install $< $@

$(KETC_LIB)/version:
	@mkdir -p $(dir $@)
	echo $(KETC_RELEASE_TAG) > $@

build: $(patsubst %, $(KETC_BIN)/%, $(install_bins)) $(patsubst %, $(KETC_LIB)/%, $(install_libs))

build-llvm: $(KETC_LIB)/$(llvm_kompiled)
build-haskell: $(KETC_LIB)/$(haskell_kompiled)

all_bin_sources := $(shell find $(KETC_BIN) -type f | sed 's|^$(KETC_BIN)/||')
all_lib_sources := $(shell find $(KETC_LIB) -type f              \
							-not -path "$(KETC_LIB)/**/dt/*"     \
						| sed 's|^$(KETC_LIB)/||')

install: $(patsubst %, $(DESTDIR)$(INSTALL_BIN)/%, $(all_bin_sources)) \
		 $(patsubst %, $(DESTDIR)$(INSTALL_LIB)/%, $(all_lib_sources))

$(DESTDIR)$(INSTALL_BIN)/%: $(KETC_BIN)/%
	@mkdir -p $(dir $@)
	install $< $@

$(DESTDIR)$(INSTALL_LIB)/%: $(KETC_LIB)/%
	@mkdir -p $(dir $@)
	install $< $@

uninstall:
	rm -rf $(DESTDIR)$(INSTALL_BIN)/ketc
	rm -rf $(DESTDIR)$(INSTALL_LIB)/ketc

# All Tests
#---------------

BACKEND ?= llvm

test: test-concrete

# Concrete Tests
#---------------

concrete_test_files := \
				test/small_movs.s               \
				test/negative_mov.s             \
				test/movz.s                     \
				test/half_ops.s                 \
				test/enable_dops.s              \
				test/enable_qops.s				\
				test/store_load.s               \
				test/test_jumps.s

all_concrete_test_deps := \
				$(concrete_test_files:.s=.bin) \
				$(concrete_test_files:.s=.sh)

build-test-concrete: $(all_concrete_test_deps)

test/%.bin test/%.sh: test/%.s
	./scripts/build-concrete-test.sh $<

test-concrete: build-test-concrete   \
				$(concrete_test_files:=.run)

%.s.run:
	$*.sh $(KETC) run $(BACKEND)

update-test-concrete: build-test-concrete \
				$(concrete_test_files:=.update)

%.s.update:
	$*.sh $(KETC) update $(BACKEND)

%.accept: %.actual
	mv $*.actual $*.expected
