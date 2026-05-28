# User Rules

## Build Commands

**NEVER run `pnpm build`, `npm run build`, or any production build during dev.**

Not optional. User verify manually. Build commands:
- Waste time (builds slow)
- Pollute terminal
- Not your job — user decide when build

**ONLY use `pnpm dev` or type-check commands if explicitly asked.**

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