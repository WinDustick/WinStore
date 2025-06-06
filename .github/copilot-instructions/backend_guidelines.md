# Backend Specific Guidelines (Python, Django, MS SQL via Django ORM)

- **Idiomatic Django & Python:** Write clean, readable, PEP 8 compliant Python code. Leverage Django's conventions and built-in features (ORM, auth, forms, admin, templates, caching, signals *judiciously*) wherever possible before reaching for third-party packages.
- **Project Structure:** Use Django's app structure for modularity and separation of concerns. Keep apps focused.
- **Models (Database - MS SQL via ORM):**
    - Define clear, concise models reflecting the domain.
    - Use appropriate Django field types mapping correctly to MS SQL types.
    - **Enforce Data Integrity:** Use `db_index=True`, `unique=True`, `blank=False`, `null=False`, `choices`, and custom `validators` extensively at the model level. Rely on database constraints.
    - Keep models focused on data structure and core business logic directly related to that data (fat models are acceptable if well-organized and tested, but consider service layers for complex cross-model logic).
- **Views & Templates/Serializers:**
    - Prefer Class-Based Views (CBVs) for complex logic/reuse, Function-Based Views (FBVs) for simple cases. Keep views **thin** – primarily handling request/response logic, authentication/permissions, and calling business logic (in models or services).
    - Use Django Templates for server-rendered HTML, Django REST Framework (DRF) Serializers for APIs. Ensure serializers perform validation and control data exposure.
- **Business Logic:** Place complex business logic in models, model managers, or dedicated, testable service modules/functions, not directly in views.
- **ORM Usage (Performance & Reliability):**
    - Use the ORM exclusively unless **profiling proves** a significant bottleneck *unresolvable* by ORM optimization.
    - **Always** use `select_related` and `prefetch_related` proactively to prevent N+1 query problems. Analyze generated SQL (`queryset.query`) during development/review if unsure.
    - Use `defer()`, `only()`, and `values()`/`values_list()` to fetch only necessary data.
    - Use database transactions (`transaction.atomic`) correctly to ensure data consistency.
    - Understand transaction isolation levels and their implications with MS SQL.
    - If raw SQL is unavoidable, isolate it, comment extensively, ensure it's parameterized against SQL injection, and test it rigorously.
- **Error Handling & Validation:**
    - Use Django's form/serializer validation framework extensively. Add custom validation logic where needed.
    - Handle potential exceptions (e.g., `Model.DoesNotExist`, `IntegrityError`, external API errors) explicitly in views or service layers using `try...except` blocks. Log errors comprehensively with context.
    - Use Django's standard error views (404, 500) or provide informative custom error responses for APIs.
- **Testing (`pytest-django`):**
    - Write comprehensive tests:
        - **Unit Tests:** For models, forms, serializers, utilities, service functions (mocking external dependencies).
        - **Integration Tests:** For views/API endpoints, testing the request/response cycle against a test database (essential!).
    - Test success paths, failure paths (validation errors, exceptions, permission errors), edge cases, and security aspects. Aim for high, meaningful test coverage. Test database constraints are enforced.
- **Security:** Apply all Django security best practices religiously (CSRF protection, XSS prevention via templating, password hashing, HTTPS, check permissions thoroughly). Keep dependencies updated.
- **Performance:**
    - Implement database indexing strategically based on query patterns.
    - Use Django's caching framework (with Redis backend) effectively for expensive queries or computations, with appropriate cache invalidation strategies.
    - Utilize Celery (with Redis broker) for background tasks (email sending, report generation, long-running jobs) to keep requests fast. Design tasks to be idempotent where possible.
    - Optimize static file serving (e.g., WhiteNoise or CDN).
- **Dependencies:** Minimize third-party packages. Justify each one. Prefer Django's built-in features. Keep `requirements.txt` clean and dependencies pinned.