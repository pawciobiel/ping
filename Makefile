GO           ?= go
GOFMT        ?= $(GO)fmt
# Security-hardened build flags:
# -buildmode=pie: Position Independent Executable (ASLR support)
# -trimpath: Remove file system paths from binary (reduces info leakage)
GOOPTS       ?= -buildmode=pie -trimpath
# Production ldflags strip debug symbols for smaller binaries
LDFLAGS_PROD ?= -s -w
GO111MODULE  :=
pkgs          = ./...

all: style vet build test

.PHONY: help
help:
	@echo "Available targets:"
	@echo "  make build       - Build goping with debug info (default, 4.3MB)"
	@echo "  make build-prod  - Build goping for production, stripped (3.0MB)"
	@echo "  make test        - Run tests with race detector"
	@echo "  make style       - Check code formatting"
	@echo "  make vet         - Run go vet"
	@echo "  make all         - Run style, vet, build, and test"

.PHONY: build
build:
	@echo ">> building goping (with debug info)"
	GO111MODULE=$(GO111MODULE) $(GO) build $(GOOPTS) -o goping ./cmd/ping

.PHONY: build-prod
build-prod:
	@echo ">> building goping for production (stripped)"
	GO111MODULE=$(GO111MODULE) $(GO) build $(GOOPTS) -ldflags='$(LDFLAGS_PROD)' -o goping ./cmd/ping

.PHONY: style
style:
	@echo ">> checking code style"
	@fmtRes=$$($(GOFMT) -d $$(find . -path ./vendor -prune -o -name '*.go' -print)); \
	if [ -n "$${fmtRes}" ]; then \
		echo "gofmt checking failed!"; echo "$${fmtRes}"; echo; \
		echo "Please ensure you are using $$($(GO) version) for formatting code."; \
		exit 1; \
	fi

.PHONY: test
test:
	@echo ">> running all tests"
	GO111MODULE=$(GO111MODULE) $(GO) test -race -cover -trimpath $(pkgs)

.PHONY: vet
vet:
	@echo ">> vetting code"
	GO111MODULE=$(GO111MODULE) $(GO) vet $(GOOPTS) $(pkgs)
