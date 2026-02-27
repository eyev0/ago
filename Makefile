.PHONY: test test-hooks test-hooks-smoke test-hooks-integration

# Run all tests
test: test-hooks

# Run all hook tests (smoke + integration)
test-hooks: test-hooks-smoke test-hooks-integration

# Run quick smoke tests (existing)
test-hooks-smoke:
	@echo "=== Hook Smoke Tests ==="
	@bash hooks/tests/run-hook-tests.sh

# Run full integration tests
test-hooks-integration:
	@echo "=== Hook Integration Tests ==="
	@bash hooks/tests/run-integration-tests.sh
