# User Rules

## Build Commands

**DO NOT run `pnpm build`, `npm run build`, or any production build commands during development.**

This is NOT optional. The user will verify changes manually. Running build commands:
- Wastes time (builds take forever)
- Pollutes the terminal with unnecessary output
- Is NOT your job - the user decides when to build

**ONLY use `pnpm dev` or type-checking commands if explicitly requested.**

## Package Manager Rules

Check `packageManager` field in `package.json` to determine the project's package manager, then use the appropriate command:

| Package Manager | Run installed package | Run one-off package |
|-----------------|----------------------|---------------------|
| pnpm | `pnpm exec` | `pnpm dlx` |
| npm | `npx` | `npx` |
| yarn | `yarn` | `yarn dlx` |
| bun | `bun` | `bunx` |

## Custom Skills

Git/커밋 작업 시 `~/.claude/skills/git-master/` 규칙을 **반드시** 따를 것.
Frontend 작업 시 `~/.claude/skills/my-frontend/` 가이드라인을 참고할 것.
