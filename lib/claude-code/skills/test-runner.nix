{
  name = "test-runner";
  description = "Detect and run tests for your project. Use when the user asks to run tests, fix test failures, check test coverage, or ensure tests pass. Automatically identifies test framework (pytest, jest, vitest, cargo test) and executes with appropriate flags.";
  content = ''
    ---
    name: test-runner
    description: Detect and run tests for your project. Use when the user asks to run tests, fix test failures, check test coverage, or ensure tests pass. Automatically identifies test framework (pytest, jest, vitest, cargo test) and executes with appropriate flags.
    ---

    # Test Runner Skill

    ## Workflow

    ### 1. Detect Test Framework

    ```bash
    # Python
    ls requirements*.txt 2>/dev/null && echo "Python (pip)"
    cat pyproject.toml 2>/dev/null | grep pytest && echo "Python (pytest)"
    cat pyproject.toml 2>/dev/null | grep vitest && echo "JavaScript (vitest)"

    # JavaScript
    ls package.json 2>/dev/null && (cat package.json | grep -E '"test"|"vitest"|"jest"') && echo "JavaScript"

    # Rust
    ls Cargo.toml 2>/dev/null && echo "Rust"
    ```

    ### 2. Run Tests

    **Python (pytest):**
    ```bash
    # Run all tests
    pytest

    # Run with verbose output
    pytest -v

    # Run with coverage
    pytest --cov=src --cov-report=term-missing

    # Run specific test file
    pytest tests/test_module.py

    # Stop on first failure
    pytest -x
    ```

    **JavaScript (Jest/Vitest):**
    ```bash
    # Run all tests
    npm test
    bun test

    # Watch mode
    npm test -- --watch
    bun test --watch

    # Coverage
    npm test -- --coverage
    bun test --coverage

    # Run specific test
    npm test -- test_name
    ```

    **Rust (cargo test):**
    ```bash
    # Run all tests
    cargo test

    # With output
    cargo test -- --nocapture

    # Specific test
    cargo test test_name

    # Coverage (requires tarpaulin)
    cargo tarpaulin --out Html
    ```

    ### 3. Parse Results

    Report:
    - ✅ Tests passed / failed count
    - ✅ Coverage percentage (if applicable)
    - ✅ Failed test names
    - ✅ Error messages (excerpt first 3)
    - ✅ Slowest tests (if verbose output)

    ### 4. Debug Failures

    **For each failure:**
    1. Extract error message and stack trace
    2. Identify root cause (assertion, timeout, missing dep, etc)
    3. Suggest fix:
       - Missing import? Add it
       - Wrong assertion? Correct the test logic
       - Setup issue? Check fixtures/mocks
       - Performance? Suggest optimization

    ## Command Reference

    | Language | Run Tests | Watch | Coverage |
    |----------|-----------|-------|----------|
    | Python | `pytest` | `pytest-watch` | `pytest --cov` |
    | JavaScript | `npm test` | `npm test --watch` | `npm test --coverage` |
    | Rust | `cargo test` | N/A | `cargo tarpaulin` |

    ## Optimization Tips

    - **Parallel tests**: `pytest -n auto` (requires pytest-xdist)
    - **Fast feedback**: `pytest -x` (stop on first failure)
    - **Focused runs**: Target specific test files or patterns
    - **Performance**: Mark slow tests with `@pytest.mark.slow` and skip with `-m "not slow"`

    ## Post-Test Checklist

    After running tests:
    - ✅ All tests pass (or explain why not)
    - ✅ No flaky tests
    - ✅ Coverage meets threshold (if applicable)
    - ✅ No deprecation warnings
    - ✅ Execution time reasonable
  '';
}
