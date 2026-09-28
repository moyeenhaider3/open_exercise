---
status: complete
phase: quick-260928-j9u
plan: 01
subsystem: infra
tags: [claude-code, claude-md, skills, permissions, settings.json]

requires:
  - phase: "02"
    provides: "Verified facts about pubspec deps, OpenAPI codegen, JS bundling/parity pipeline, lib/ layout and Bloc pattern"
provides:
  - "CLAUDE.md Technology Stack / Conventions / Architecture sections populated with repo-verified facts"
  - "port-from-opengym project skill (.claude/skills/port-from-opengym/SKILL.md)"
  - ".claude/settings.json permissions.deny Read rules for build/generated/vendor dirs"
affects: [claude-code-config, future-phase-execution]

tech-stack:
  added: []
  patterns:
    - "Claude Code project skill (frontmatter name/description + SPDX body) as the on-demand carrier for the long porting workflow, keeping CLAUDE.md itself short"

key-files:
  created:
    - .claude/skills/port-from-opengym/SKILL.md
  modified:
    - CLAUDE.md
    - .claude/settings.json

key-decisions:
  - "Used the actual facade class names found by grep (SessionStartJs, SessionMergeJs) instead of the plan's placeholder SessionJs, since lib/core/js/modules/session_js.dart defines two session facades, not one"
  - "permissions.deny targets Read only (never Write/Edit) so tool/gen_api.sh can still regenerate lib/core/api/generated"

patterns-established:
  - "GSD-managed CLAUDE.md sections (stack/conventions/architecture/skills) are edited only between their marker pairs, verified by marker-count and per-block diff checks before commit"

requirements-completed: [QUICK-260928-j9u]

duration: ~20min
completed: 2026-09-28
---

# Quick Task 260928-j9u: Refresh Claude config, add port-from-opengym skill Summary

**Populated CLAUDE.md's three placeholder sections with facts verified against the live repo, added the first project skill (port-from-opengym) documenting the JS-04 bridging workflow, and added six `permissions.deny` Read rules to `.claude/settings.json` without touching the existing no-tests hook.**

## Performance

- **Tasks:** 3/3 completed
- **Files modified:** 3 (CLAUDE.md, .claude/skills/port-from-opengym/SKILL.md, .claude/settings.json)

## Accomplishments

- CLAUDE.md now documents the real stack (flutter_bloc/equatable/sqflite/dio+retrofit/go_router/flutter_js), conventions (SPDX headers, Bloc feature-folder pattern, JS-04 no-domain-math-in-Dart rule, no-tests verification commands), and an architecture map of `lib/`, `tool/`, `third_party/opengym`, `assets/js` — all 14 GSD markers intact and every other section byte-identical to the prior version.
- Added `.claude/skills/port-from-opengym/SKILL.md`: a 78-line skill that points at `../openGym`'s views/components/store/lib/locales/App.jsx/backend, restates the JS-04 facade rule with the actual (grep-verified) facade class names, walks through adding a new bridged function end-to-end (vendor -> bridge-inventory -> facade -> fixtures -> dispatch -> parity), and documents app patterns, the no-tests rule, and verification commands.
- Added `permissions.deny` to `.claude/settings.json` for `build/`, `.dart_tool/`, `ios/Pods/`, `android/.gradle/`, `tool/js/node_modules/`, and `lib/core/api/generated/`, keeping the existing no-tests `PreToolUse` hook byte-for-byte unchanged (diffed against a saved copy of `.hooks`).

## Task Commits

Each task was committed atomically:

1. **Task 1: Populate CLAUDE.md stack, conventions, architecture and skills sections** - `e47cf9e` (docs)
2. **Task 2: Create the port-from-opengym project skill** - `1ab73c7` (feat)
3. **Task 3: Add permissions.deny Read rules to .claude/settings.json while keeping the hook** - `27e844f` (chore)

_No TDD tasks in this plan (config/docs only); no test files created (project no-tests rule)._

## Files Created/Modified

- `CLAUDE.md` - Technology Stack, Conventions, Architecture and Project Skills sections filled with verified facts; all other content (Project, Constraints, GSD Workflow Enforcement, Developer Profile) untouched
- `.claude/skills/port-from-opengym/SKILL.md` - new project skill: openGym source map, JS-04 facade rule, bridged-function workflow, app patterns, no-tests rule, verify commands
- `.claude/settings.json` - added `permissions.deny` (6 Read rules); `hooks.PreToolUse` unchanged

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Corrected facade class name from plan's `SessionJs` to actual `SessionStartJs`/`SessionMergeJs`**
- **Found during:** Task 2 (read_first: `lib/core/js/modules/session_js.dart`)
- **Issue:** The plan's action text listed `SessionJs` as one of the seven facade classes to document, but `lib/core/js/modules/session_js.dart` actually defines two separate classes, `SessionStartJs` and `SessionMergeJs` (matching `sessionStart`/`sessionMerge` in `tool/js/entry.js`). No `SessionJs` class exists anywhere in `lib/core/js/modules`.
- **Fix:** Documented both real class names in the skill instead of the placeholder name, and verified every facade name in the file against `grep -n '^final class ' lib/core/js/modules/*.dart` before writing (as the plan itself instructed: "check the class names with grep before writing").
- **Files modified:** `.claude/skills/port-from-opengym/SKILL.md`
- **Commit:** `1ab73c7`

No other deviations. All three tasks executed as written otherwise.

## Verification Results

- `jq -e . .claude/settings.json` succeeds; `.permissions.deny` has exactly 6 entries including `Read(./lib/core/api/generated/**)`; `.hooks.PreToolUse[0].hooks[0].statusMessage` is still `"Checking no-tests rule"`; `diff <(jq -S .hooks .claude/settings.json) $SCRATCH/hooks.orig.json` shows no difference.
- `grep -c '<!-- GSD:' CLAUDE.md` = 14; no placeholder text (`not yet documented`/`not yet established`/`not yet mapped`/`No project skills found`) remains; `port-from-opengym`, `lib/core/api/generated`, `JsEngineService`, `js04_audit.sh` all present; the stack-through-architecture block is 41 lines; `diff` of GSD marker lines and of the project/workflow/profile blocks against the pre-edit backup shows no difference.
- `.claude/skills/port-from-opengym/SKILL.md`: frontmatter is the first `---`-delimited block with `name`/`description`; contains the SPDX line, `js04_audit.sh`, `run_parity.sh`, `bridge-inventory.mjs`, `frontend/src/store` (and not `src/stores`); file is 78 lines (<=120); every `lib/`, `tool/`, `third_party/`, `assets/` path named in the file (excluding `<module>`-style placeholders) resolves via `test -e`; every named facade class (`OnermJs`, `BarJs`, `WorkoutModelJs`, `ProgressionJs`, `RecoveryJs`, `HistoryJs`, `SessionStartJs`, `SessionMergeJs`) is found via grep in `lib/core/js/modules`; every `../openGym/...` path named (views, components, store, lib, locales, App.jsx, api/server.js, api/openapi.yaml, CLAUDE.md, PROJECT_CONTEXT.md) was confirmed to exist against the sibling `openGym` checkout.
- `git status --porcelain` after all three commits is empty; only `CLAUDE.md`, `.claude/skills/port-from-opengym/SKILL.md`, and `.claude/settings.json` were touched (plus the `.planning/quick/...` docs artifacts, not committed by this executor). No test files, no Dart files, no pubspec changes.

## Self-Check: PASSED

- FOUND: CLAUDE.md (modified, GSD markers intact)
- FOUND: .claude/skills/port-from-opengym/SKILL.md
- FOUND: .claude/settings.json (permissions.deny added, hooks unchanged)
- FOUND: e47cf9e (Task 1 commit)
- FOUND: 1ab73c7 (Task 2 commit)
- FOUND: 27e844f (Task 3 commit)
