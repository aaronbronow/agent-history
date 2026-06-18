.PHONY: test clean help

# Default target
all: test

# Run tests
test:
	@echo "Running unit tests..."
	@./tests/test_parser.sh

# Clean temporary files
clean:
	@echo "Cleaning up..."
	@find . -name "__pycache__" -type d -exec rm -rf {} + 2>/dev/null || true

# Print help message
help:
	@echo "Available make targets:"
	@echo "  make test   - Run the unit tests"
	@echo "  make clean  - Clean temporary files"
	@echo "  make help   - Print this help message"
