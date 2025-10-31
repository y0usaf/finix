{
  name = "linter";
  description = "Apply language-specific linters and formatters to enforce code style. Use when the user asks to lint, format, fix style issues, or when you detect style problems (unused code, formatting inconsistencies). Works with Nix, Python, JavaScript, and detects the best linter for each language.";
  content = ''
    ---
    name: linter
    description: Apply language-specific linters and formatters to enforce code style. Use when the user asks to lint, format, fix style issues, or when you detect style problems (unused code, formatting inconsistencies). Works with Nix, Python, JavaScript, and detects the best linter for each language.
    ---

    # Linter Skill

    ## Workflow

    ### 1. Detect Project Type
    ```bash
    # Check for file types in current directory
    ls *.nix 2>/dev/null && echo "Nix project"
    ls *.py 2>/dev/null && echo "Python project"
    ls *.{js,ts,jsx,tsx} 2>/dev/null && echo "JavaScript project"
    cat pyproject.toml 2>/dev/null && echo "Python (uv/poetry)"
    cat package.json 2>/dev/null && echo "JavaScript (npm/bun)"
    ```

    ### 2. Apply Linters by Language

    **Nix:**
    ```bash
    # Check for issues
    statix check .

    # Fix issues
    statix fix .

    # Remove dead code
    deadnix .

    # Format
    alejandra .
    ```

    **Python:**
    ```bash
    # Fastest modern linter
    ruff check . --fix

    # Fallback (if ruff unavailable)
    python -m pylint src/
    python -m flake8 .
    ```

    **JavaScript/TypeScript:**
    ```bash
    # Via bun/npm
    bunx eslint . --fix
    npm run lint -- --fix
    bun run lint --fix
    ```

    ### 3. Format Code

    **Nix:**
    ```bash
    alejandra .
    ```

    **Python:**
    ```bash
    ruff format .
    ```

    **JavaScript:**
    ```bash
    bunx prettier . --write
    npm run format
    ```

    ## Command Reference

    | Language | Check | Fix | Format |
    |----------|-------|-----|--------|
    | Nix | `statix check .` | `statix fix .` | `alejandra .` |
    | Python | `ruff check .` | `ruff check --fix .` | `ruff format .` |
    | JS/TS | `eslint .` | `eslint --fix .` | `prettier --write .` |

    ## Quick Aliases (Already Available)

    - `lintcheck` - Run Nix linters (statix + deadnix)
    - `lintfix` - Fix Nix issues (statix fix + deadnix)

    ## Important Notes

    - **Nix**: Always use `statix`, `deadnix`, and `alejandra` together. Your workflow: `alejandra . && statix check . && deadnix .`
    - **Python**: Ruff is the modern standard (Rust-based, fastest). Falls back to pylint/flake8 if not available.
    - **JavaScript**: Check for eslint in package.json first, fallback to bunx eslint.
    - **Formatting**: Alejandra (Nix) and Prettier (JS) are auto-formatters; Ruff/Flake8 are linters—sometimes need both.

    ## Post-Lint Checklist

    After linting, report:
    - ✅ Number of issues found
    - ✅ Number of issues fixed automatically
    - ✅ Any manual fixes required
    - ✅ Code formatted or ready to format
  '';
}
