<!-- GSD:project-start source:PROJECT.md -->
## Project

**open_exercise — openGym for Flutter**

A native Flutter (Android/iOS) port of **openGym** (`../openGym/`), the self-hosted gym and body-weight tracker. The goal is a 1:1 replica of openGym's features, offline persistence and UI layout, built with native Flutter widgets (Material 3) instead of a React/Capacitor WebView.

**Core Value:** Log a workout fully offline with **exactly** the same numbers as openGym. The same inputs must give identical 1RM estimates, progression suggestions, plate math and volume/fatigue results, because the original JavaScript logic runs unchanged.

### Constraints

- **License:** AGPL-3.0-or-later. This port is a derivative work and must use the same license.
- **Stack (user-mandated):** flutter_bloc, equatable, sqflite, Dio (OpenAPI-generated), flutter_js, flutter_local_notifications, flutter_passkey_service, xml, path_drawing.
- **Process:** one phase at a time. Wait for user approval before starting each next phase.
- **No tests (user-mandated, enforced):** never write, generate, or plan test code: no `test/`, `integration_test/` or `test_driver/` files, no `*_test.dart`, and no test dev-dependencies (`bloc_test`, `mocktail`, `sqflite_common_ffi`, etc.). Plans must not contain test tasks, TDD tasks, or test-based acceptance criteria. Use `flutter analyze` and source/CLI assertions for verification instead. A PreToolUse hook in `.claude/settings.json` blocks writes to test paths.
<!-- GSD:project-end -->

<!-- GSD:stack-start source:STACK.md -->
## Technology Stack

Technology stack not yet documented. Will populate after codebase mapping or first phase.
<!-- GSD:stack-end -->

<!-- GSD:conventions-start source:CONVENTIONS.md -->
## Conventions

Conventions not yet established. Will populate as patterns emerge during development.
<!-- GSD:conventions-end -->

<!-- GSD:architecture-start source:ARCHITECTURE.md -->
## Architecture

Architecture not yet mapped. Follow existing patterns found in the codebase.
<!-- GSD:architecture-end -->

<!-- GSD:skills-start source:skills/ -->
## Project Skills

No project skills found. Add skills to any of: `.claude/skills/`, `.agents/skills/`, `.cursor/skills/`, `.github/skills/`, or `.codex/skills/` with a `SKILL.md` index file.
<!-- GSD:skills-end -->

<!-- GSD:workflow-start source:GSD defaults -->
## GSD Workflow Enforcement

Before using Edit, Write, or other file-changing tools, start work through a GSD command so planning artifacts and execution context stay in sync.

Use these entry points:
- `/gsd-quick` for small fixes, doc updates, and ad-hoc tasks
- `/gsd-debug` for investigation and bug fixing
- `/gsd-execute-phase` for planned phase work

Do not make direct repo edits outside a GSD workflow unless the user explicitly asks to bypass it.
<!-- GSD:workflow-end -->



<!-- GSD:profile-start -->
## Developer Profile

> Profile not yet configured. Run `/gsd-profile-user` to generate your developer profile.
> This section is managed by `generate-claude-profile` -- do not edit manually.
<!-- GSD:profile-end -->
