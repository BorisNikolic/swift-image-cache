.PHONY: check-deps hook test lint format clean

check-deps:
	@echo "Checking dependencies..."
	@if ! command -v brew >/dev/null 2>&1; then \
		echo "Error: Homebrew is not installed."; \
		echo "Please install Homebrew first by running:"; \
		echo "/bin/bash -c \"$$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""; \
		exit 1; \
	fi
	@echo "✓ Homebrew is installed"
	@if ! command -v swiftformat >/dev/null 2>&1; then \
		echo "SwiftFormat not found. Installing via Homebrew..."; \
		brew install swiftformat; \
	else \
		echo "✓ SwiftFormat is already installed"; \
	fi
	@if ! command -v swiftlint >/dev/null 2>&1; then \
		echo "SwiftLint not found. Installing via Homebrew..."; \
		brew install swiftlint; \
	else \
		echo "✓ SwiftLint is already installed"; \
	fi

hook: check-deps
	@echo "Setting up pre-commit hook..."
	@if [ ! -d .git/hooks ]; then \
		mkdir -p .git/hooks; \
	fi
	@echo "#!/bin/bash" > .git/hooks/pre-commit
	@echo "" >> .git/hooks/pre-commit
	@echo "# Run SwiftFormat on staged Swift files" >> .git/hooks/pre-commit
	@echo "./BuildTools/git-format-staged.sh --formatter \"swiftformat --config .swiftformat stdin --stdinpath '{}'\" \"*.swift\"" >> .git/hooks/pre-commit
	@echo "" >> .git/hooks/pre-commit
	@echo "# Run SwiftLint on staged Swift files" >> .git/hooks/pre-commit
	@echo "git diff --cached --name-only --diff-filter=AM -- '*.swift' | while read file; do" >> .git/hooks/pre-commit
	@echo "  swiftlint lint --strict --config .swiftlint.yml --path \"\$$file\"" >> .git/hooks/pre-commit
	@echo "  if [ \$$? -ne 0 ]; then" >> .git/hooks/pre-commit
	@echo "    echo \"SwiftLint failed for \$$file\"" >> .git/hooks/pre-commit
	@echo "    exit 1" >> .git/hooks/pre-commit
	@echo "  fi" >> .git/hooks/pre-commit
	@echo "done" >> .git/hooks/pre-commit
	@chmod +x .git/hooks/pre-commit
	@echo "✓ Pre-commit hook installed (SwiftFormat + SwiftLint)"

test:
	@echo "Running SDK unit tests..."
	set -o pipefail && xcodebuild test -scheme RoundsImageKit \
		-destination 'platform=iOS Simulator,name=iPhone SE (3rd generation),OS=18.6' \
		2>&1 | grep -E "◇|✔|✘|error:|BUILD|Executed"

lint:
	@echo "Running SwiftLint..."
	swiftlint lint --config .swiftlint.yml

format:
	@echo "Running SwiftFormat..."
	swiftformat Sources Tests ExampleApp/ExampleApp --config .swiftformat

clean:
	@echo "Cleaning build artifacts..."
	swift package clean
	rm -rf .build
