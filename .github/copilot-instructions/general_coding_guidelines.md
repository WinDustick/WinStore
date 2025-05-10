# General Coding Guidelines (Apply to ALL Code)

- **Correctness:** Write code that is logically sound and functionally correct according to the requirements.
- **Simplicity:** Always prefer the simplest approach that meets the requirements robustly. Avoid unnecessary layers of abstraction or complex patterns.
- **Readability:** Use clear, descriptive, and consistent naming for variables, functions, classes, etc. Follow language-specific idiomatic conventions (PEP 8 for Python, standard TS/JS conventions).
- **DRY (Don't Repeat Yourself):** Avoid code duplication, but prefer slight duplication over creating a poor or overly complex abstraction.
- **Robustness & Error Handling:** Explicitly anticipate and handle potential errors (invalid input, network issues, database errors, unexpected states). Use specific exception types. Prefer explicit error returns (`Result` types conceptually) or well-defined exceptions over returning null/undefined/empty values to indicate errors. Ensure errors are logged comprehensively.
- **Testability:** Design code to be easily testable. Prefer pure functions and clear dependencies.
- **Immutability:** Prefer immutable data structures and patterns whenever practical.
- **Dependencies:** Minimize external dependencies. Justify the inclusion of any third-party library based on significant value and alignment with quality/reliability standards.