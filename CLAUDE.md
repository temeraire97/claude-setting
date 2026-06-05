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