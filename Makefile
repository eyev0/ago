.PHONY: test test-hooks test-hooks-smoke test-hooks-integration \
       test-skills test-agents test-structure test-lint

# Run all tests (hooks + structural lint)
test: test-hooks test-lint

# --- Hook tests ---

# Run all hook tests (smoke + integration)
test-hooks: test-hooks-smoke test-hooks-integration

# Run quick smoke tests
test-hooks-smoke:
	@echo "=== Hook Smoke Tests ==="
	@bash hooks/tests/run-hook-tests.sh

# Run full integration tests
test-hooks-integration:
	@echo "=== Hook Integration Tests ==="
	@bash hooks/tests/run-integration-tests.sh

# --- Structural lint tests (require yq) ---

# Run all structural validation
test-lint: test-skills test-agents test-structure

# Validate skill frontmatter, naming, and references
test-skills:
	@bash tests/test-skills.sh

# Validate agent metadata, examples, and triggering
test-agents:
	@bash tests/test-agents.sh

# Validate plugin structure, manifest, and cross-references
test-structure:
	@bash tests/test-structure.sh
