# Global Claude Code Settings

## Build Commands - READ THIS FIRST

**DO NOT run `pnpm build`, `npm run build`, or any production build commands during development.**

This is NOT optional. The user will verify changes manually. Running build commands:
- Wastes time (builds take forever)
- Pollutes the terminal with unnecessary output
- Is NOT your job - the user decides when to build

**ONLY use `pnpm dev` or type-checking commands if explicitly requested.**

If you catch yourself about to run a build command, STOP. Ask the user first.

---

## Commit Message Convention

When asked to generate a commit message:
1. Check changes with `git status` and `git diff`
2. Generate message in Korean following Conventional Commits format
3. Do NOT execute the commit - user will commit manually
4. **NEVER add fingerprints** - no "Generated with Claude Code", no "Co-Authored-By: Claude", no emojis like 🤖

Format: `type(scope): message` - scope is REQUIRED, never omit it

Types: `feat`, `fix`, `docs`, `style`, `refactor`, `test`, `chore`, `perf`, `ci`, `build`

## Git Workflow

**Repository**: AWS CodeCommit (not GitHub)
- `gh` CLI 대신 `aws codecommit` CLI 사용
- PR 생성: `aws codecommit create-pull-request --title "..." --description "..." --targets repositoryName=...,sourceReference=...,destinationReference=main`

Use [GitHub Flow](https://githubflow.github.io/):

1. `main` is always deployable
2. Create descriptively named branches from main (no prefixes)
3. Push commits regularly
4. Open PR → Review → Merge to main → Deploy

**Branch naming**: Use descriptive names that explain the work

```
# Good examples
user-content-cache-key
add-jenkins-pipeline
fix-login-error

# Don't use (Git Flow style)
feature/xxx, fix/xxx, chore/xxx
```

### Branch Discipline (CRITICAL)

**STOP. Before ANY work, check the current branch name.**

If the user requests work UNRELATED to the current branch name:
1. **REFUSE to proceed** until a new branch is created
2. Warn the user: "This work doesn't match branch `<current-branch>`. Create a new branch first."
3. Suggest: `git checkout main && git checkout -b <appropriate-name>`

**This is NON-NEGOTIABLE.** Mixing unrelated work in a single branch:
- Pollutes git history
- Makes PRs impossible to review
- Causes merge conflicts
- Wastes hours of cleanup work (like we just did)

**Do NOT let the user be lazy. Enforce branch discipline.**

### Testing Multiple Branches in Staging

Use **Throw-Away Integration Branch** pattern to test multiple feature branches together in staging while maintaining GitHub Flow.

```bash
# 1. Create temporary staging branch from main
git checkout main
git checkout -b staging-qa

# 2. Merge all feature branches (octopus merge)
git merge feature-a feature-b feature-c feature-d

# 3. Deploy to staging environment & test

# 4. Delete after testing (disposable)
git branch -D staging-qa

# 5. Merge each feature to main via individual PRs
```

**Key principles:**
- Staging branch is **disposable** - delete after testing
- Feature branches remain untouched
- After QA passes, merge each feature via **individual PR** to main
- If a feature fails, recreate staging branch without it

## Frontend Design Guidelines

### Readability

- **Name magic numbers**: Use named constants (e.g., `ANIMATION_DELAY_MS = 300`)
- **Abstract implementation details**: Extract complex logic into dedicated components/HOCs (e.g., `AuthGuard`, `InviteButton`)
- **Separate conditional code paths**: Split significantly different UI/logic into distinct components
- **Simplify ternaries**: Replace complex/nested ternaries with `if`/`else` or IIFEs
- **Name complex conditions**: Assign boolean expressions to descriptive variables (`isSameCategory`, `isPriceInRange`)

### Predictability

- **Standardize return types**: Use consistent return types for similar functions (e.g., React Query hooks return full query object, validation functions return `{ ok: true } | { ok: false; reason: string }`)
- **Reveal hidden logic (SRP)**: Functions should only perform actions implied by their signature - no hidden side effects
- **Use unique descriptive names**: Avoid ambiguity with custom wrappers (e.g., `httpService.getWithAuth` not just `http.get`)

### Cohesion

- **Form cohesion**: Choose field-level validation (independent fields) or form-level validation (zod schema) based on requirements
- **Organize by feature/domain**: Group related files together, not just by code type
- **Relate constants to logic**: Define constants near related logic or name them to show the relationship

### Coupling

- **Avoid premature abstraction**: Allow some duplication if use cases might diverge
- **Scope state management**: Break broad state hooks into smaller, focused ones to prevent unnecessary re-renders
- **Use composition over props drilling**: Render children directly instead of passing props through intermediate components
