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
		-c release \
		--disable-sandbox \
		--build-path "$(BUILDDIR)"

.PHONY: install
install: swift-type-adoption-reporter
	@install -d "$(bindir)" "$(libdir)"
	@install "$(BUILDDIR)/release/swift-type-adoption-reporter" "$(bindir)"
	@install "$(BUILDDIR)/release/SwiftSyntax.swiftmodule" "$(libdir)"
	@install_name_tool -change \
		"$(BUILDDIR)/x86_64-apple-macosx10.10/release/SwiftSyntax.swiftmodule" \
		"$(libdir)/SwiftSyntax.swiftmodule" \
		"$(bindir)/swift-type-adoption-reporter"
	@if [ ! -e  "$(bindir)/star" ]; then ln -s "$(bindir)/swift-type-adoption-reporter" "$(bindir)/star"; fi

.PHONY: uninstall
uninstall:
	@rm -rf "$(bindir)/star"
	@rm -rf "$(bindir)/swift-type-adoption-reporter"
	@rm -rf "$(libdir)/SwiftSyntax.swiftmodule"

.PHONY: clean
distclean:
	@rm -f $(BUILDDIR)/release

.PHONY: clean
clean: distclean
	@rm -rf $(BUILDDIR)
