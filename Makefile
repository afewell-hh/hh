# HH Project Makefile

.PHONY: all build test e2e clean help

# Default target
all: build

# Build binaries
build:
	@echo "Building hh CLI..."
	@echo "hh CLI is a Python script, no compilation needed"
	@echo "Building docker-credential-hh..."
	@cd cli/docker-credential-hh && \
		PATH=$$PATH:/usr/local/go/bin CGO_ENABLED=0 GOOS=linux GOARCH=amd64 \
		go build -o docker-credential-hh .
	@echo "✓ Build complete"

# Run all tests
test: e2e

# Run end-to-end tests
e2e:
	@echo "Running end-to-end tests..."
	@./scripts/e2e/test-sandbox-flow.sh
	@echo "✓ All e2e tests passed"

# Clean build artifacts
clean:
	@echo "Cleaning build artifacts..."
	@rm -f cli/docker-credential-hh/docker-credential-hh
	@rm -f cli/docker-credential-hh/docker-credential-hh-new
	@rm -rf .sandbox*
	@echo "✓ Clean complete"

# Show help
help:
	@echo "HH Project Makefile"
	@echo ""
	@echo "Targets:"
	@echo "  build    - Build all binaries"
	@echo "  test     - Run all tests"
	@echo "  e2e      - Run end-to-end tests"
	@echo "  clean    - Clean build artifacts"
	@echo "  help     - Show this help message"