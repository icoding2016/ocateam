.PHONY: validate install-test test bats-check

# ── Tier 1: Static validation (no external dependencies beyond Python) ──
validate:
	@bash tests/validate.sh

# ── Tier 2: Installer functional tests (requires bats) ──
bats-check:
	@if command -v bats >/dev/null 2>&1; then \
		echo "✓ bats found: $$(bats --version)"; \
	else \
		echo "✗ bats not found. Install: npm install -g bats"; \
		echo "  or visit: https://bats-core.readthedocs.io/"; \
		exit 1; \
	fi

install-test: bats-check
	bats tests/test_install.bats

# ── Run all tests ──
test: validate install-test
	@echo ""
	@echo "All tests passed."
