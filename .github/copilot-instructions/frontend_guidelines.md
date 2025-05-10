# Frontend Specific Guidelines (ReactJS, NextJS, TypeScript, TailwindCSS)

- **Type Safety:** Use **TypeScript** strictly. Configure `tsconfig.json` for maximum strictness (`strict: true`, `noImplicitAny: true`, `strictNullChecks: true`, etc.). Avoid `any` unless absolutely necessary and clearly justified with a comment. Define explicit types/interfaces for props, state, API responses, etc.
- **Simplicity:** Use functional components with Hooks. Keep components small and focused on a single responsibility. Avoid premature optimization or overly complex component structures.
- **State Management:** Prefer local component state (`useState`, `useReducer`). Use Context API for simple global state sharing. Introduce complex state management libraries (Zustand, Jotai, etc.) *only* if the application's complexity demonstrably requires it, and justify the choice. Avoid Redux unless mandated for legacy reasons.
- **Styling:** Use **TailwindCSS classes exclusively** for styling. Avoid CSS files, `<style>` tags, or inline `style` attributes. Keep class strings readable (potentially using helper libraries like `clsx` or `tailwind-merge` if needed, but justify them).
- **Readability:** Use descriptive names for components, props, state variables, and handler functions. Event handlers must use the `handle` prefix (e.g., `handleClick`, `handleInputChange`). Use `const arrowFunctionName = (): ReturnType => {}` syntax for components and functions.
- **Performance:**
    - Optimize component rendering (use `React.memo`, `useMemo`, `useCallback` *strategically* and only when profiling shows a clear benefit; avoid overuse).
    - Minimize bundle size (code splitting via NextJS, tree shaking, analyze bundles).
    - Optimize image loading (NextJS `<Image>` component, appropriate formats/sizes).
    - Ensure fast Core Web Vitals (LCP, INP, CLS).
    - Write efficient selectors if interacting directly with the DOM (rare).
- **Reliability & Robustness:**
    - Implement comprehensive client-side validation (alongside server-side).
    - Handle API request states (loading, success, error) explicitly and provide user feedback.
    - Use React Error Boundaries to catch and handle rendering errors gracefully.
    - Implement thorough tests:
        - **Unit Tests (Vitest/Jest):** For pure functions, hooks, utilities.
        - **Component/Integration Tests (React Testing Library):** For component behavior and interactions.
        - **End-to-End Tests (Playwright/Cypress):** For critical user flows.
    - Aim for high, meaningful test coverage.
- **Accessibility (A11y):** Implement accessibility best practices rigorously. Use semantic HTML. Provide `aria-*` attributes, `tabindex`, keyboard navigation (`onKeyDown` handlers alongside `onClick`), focus management, and sufficient color contrast. Test with screen readers and keyboard navigation.
- **Early Returns:** Use early returns to reduce nesting and improve clarity.

*Note from user: One specific rule to follow is "Use 'class:' instead of the tertiary operator in class tags whenever possible." (This should be kept if it's a specific preference, though it's quite a detailed stylistic choice for a general guideline. If it refers to a specific framework or templating syntax not standard to React/NextJS, clarification might be needed. Assuming it's a known pattern to the user.)*