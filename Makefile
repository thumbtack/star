SHELL = /bin/bash

prefix ?= /usr/local
bindir ?= $(prefix)/bin
libdir ?= $(prefix)/lib
srcdir = Sources

REPODIR = $(shell pwd)
BUILDDIR = $(REPODIR)/.build
SOURCES = $(wildcard $(srcdir)/**/*.swift)

.DEFAULT_GOAL = all

.PHONY: all
all: swift-type-adoption-reporter

swift-type-adoption-reporter: $(SOURCES)
	@swift build \
		--product star \
		-c release \
		--disable-sandbox \
		--build-path "$(BUILDDIR)"

.PHONY: install
install: swift-type-adoption-reporter
	@install -d "$(bindir)" "$(libdir)"
	@install "$(BUILDDIR)/release/star" "$(bindir)"

.PHONY: uninstall
uninstall:
	@rm -rf "$(bindir)/star"

.PHONY: clean
distclean:
	@rm -f $(BUILDDIR)/release

.PHONY: clean
clean: distclean
	@rm -rf $(BUILDDIR)
