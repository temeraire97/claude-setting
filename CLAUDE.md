# User Rules

## Build Commands

**NEVER run `pnpm build`, `npm run build`, or any production build during dev.**

Not optional. User verify manually. Build commands:
- Waste time (builds slow)
- Pollute terminal
- Not your job — user decide when build

**ONLY use `pnpm dev` or type-check commands if explicitly asked.**

## Model Routing (Orchestrator Discipline)

**The main loop (Opus) is an ORCHESTRATOR / ARCHITECT only.** It plans, decomposes, delegates, reviews, and commits — it does NOT write implementation code itself.

- ⛔ **Main Opus loop: NEVER call `Edit` / `Write` / `MultiEdit` / `NotebookEdit` directly.** Every file-modifying change is delegated to a **Sonnet** subagent via the Task tool.
- ✅ **Implementation → Sonnet subagents.** Spawn `executor` (or `tdd-executor` for `[TDD]` tasks, `build-fixer` for build/type errors) for every code change, including "tiny" ones. Consistency over the marginal latency saved by inlining.
- ✅ **Haiku = one-shot lookup / single-pass only.** Use Haiku-tier agents (`architect-low`, `code-reviewer-low`, `security-reviewer-low`) for single-pass read/lookup/review. The `writer` agent (Haiku) is the one sanctioned Haiku editor, and ONLY for documentation. Never give a Haiku agent multi-step or code-mutating work.
- A PreToolUse hook (`block-main-impl.js`) enforces this by denying Edit/Write from the main session; if it is ever disabled, this directive still governs.
- The ONLY exception is a literal one-keystroke fix the user explicitly orders inline ("just fix it directly"); even then prefer delegation.

## Package Manager Rules

Check `packageManager` field in `package.json` for project's package manager, then use matching command:

| Package Manager | Run installed package | Run one-off package |
|-----------------|----------------------|---------------------|
| pnpm | `pnpm exec` | `pnpm dlx` |
| npm | `npx` | `npx` |
| yarn | `yarn` | `yarn dlx` |
| bun | `bun` | `bunx` |

## Custom Skills

Git/커밋 작업 시 `~/.claude/skills/git-master/` 규칙 **반드시** 따를 것.
Frontend 작업 시 `~/.claude/skills/my-frontend/` 가이드라인 참고할 것.
# graphify
- **graphify** (`~/.claude/skills/graphify/SKILL.md`) — any input to knowledge graph. Trigger: `/graphify`
User types `/graphify` → invoke Skill tool with `skill: "graphify"` before anything else.

## Work-style (promoted from aequitas project memory, 2026-06-08)

- **Verify before claiming:** "best practice" / "권장 방법" 단정 전 WebSearch + 공식 가이드 1회 이상 확인; 검증 못 했으면 "일반론, 도메인 idiom은 다를 수 있음" 명시.
- **Task-loop for big work:** Day 단위 큰 UoW는 `/task-loop` skill(Pre-flight → 새 브랜치 → TaskCreate×N → verification team 병렬 → BLOCK/WARN triage → merge); 작은 단일 변경은 직접 진행.
- **Parallel dispatch — dispatch all at once:** Agent/Task N개 보낼 때 4-5개씩 나눠 보내다 후반 누락 반복 발생 → 한 메시지에 전부 호출. 분할 불가피하면 "이번 N개 / 남은 M개" 명시 추적.
- **Caveman/terse 모드 — 도구 호출 구조는 압축 금지:** prose/텍스트 응답만 terse 적용; 도구 호출 XML, 코드, 커밋 메시지, PR 본문은 항상 완전한 형식 유지.
- **CSS 단위 무조건 rem:** 사용자가 px로 말해도 코드엔 rem 환산 (÷16, 예: 800px→50rem); vw/vh/% 는 그대로 유지.
- **Worktree 무조건:** 신규 브랜치 작업은 `git worktree add -b <branch> ../<repo>-<topic> main`; 메인 체크아웃에 직접 브랜치+편집 금지.