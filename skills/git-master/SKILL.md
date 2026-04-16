# My Git Rules

Git 커밋, 브랜치, PR 관련 사용자 커스텀 규칙입니다.

---

## Commit Message Convention

커밋 메시지 생성 시:
1. `git status`와 `git diff`로 변경사항 확인
2. **한국어**로 Conventional Commits 형식 작성
3. 커밋 실행하지 말고 메시지만 제안 (사용자가 직접 커밋)

**형식:** `type(scope): message` - scope는 **필수**, 생략 금지

---

## ⛔ FINGERPRINT 절대 금지 (ABSOLUTE RULE)

**절대 절대 무조건 무슨 일이 있어도 다음을 추가하지 말 것:**

- `Co-Authored-By: Claude`
- `Co-Authored-By: Claude Code`
- `Co-Authored-By: Claude Opus`
- `Generated with Claude Code`
- `🤖 Generated with Claude`
- 기타 AI/Claude 관련 fingerprint 일체

**이 규칙은 협상 불가. 예외 없음. 어떤 상황에서도 위반 금지.**

**Types:** `feat`, `fix`, `docs`, `style`, `refactor`, `test`, `chore`, `perf`, `ci`, `build`

---

## Git Workflow

### 저장소 타입별 워크플로우

| 저장소 | PR 생성 | Merge 방식 | CLI |
|--------|---------|------------|-----|
| **GitHub** | `gh pr create` | **3-way merge (`--merge`)** | `gh` |
| **CodeCommit** | `aws codecommit` | **로컬 merge 필수** (author 문제) | `aws` |

---

### GitHub 프로젝트

**GitHub은 로컬 merge가 필요 없음** - 웹 UI 또는 CLI에서 직접 merge:

```bash
# 1. PR 생성
gh pr create --title "feat(scope): 변경 요약" --body "..." --base main

# 2. PR merge (3-way merge 기본)
gh pr merge <PR-NUMBER> --merge

# 3. 로컬 동기화 & 브랜치 삭제
git checkout main && git pull
git branch -d <branch-name>
```

---

### CodeCommit 프로젝트

**CodeCommit은 로컬 merge 필수** - CLI merge는 AWS IAM 사용자로 커밋됨:
- `gh` CLI 대신 `aws codecommit` CLI 사용
- **Merge는 반드시 로컬에서 `AaronYun <hyensooyoon@gmail.com>` author로 수행** (CLI merge 금지)

### ⚠️ CodeCommit AWS Profile (CRITICAL)

**CodeCommit 관련 `aws` CLI 명령은 반드시 `--profile devgentlepie` 사용:**

```bash
# ✅ 올바른 사용
aws codecommit create-pull-request --profile devgentlepie ...
aws codecommit get-pull-request --profile devgentlepie ...
aws codecommit merge-pull-request-by-three-way --profile devgentlepie ...

# ❌ 절대 금지 (다른 프로파일 사용)
aws codecommit ... --profile lg    # 접근 불가
aws codecommit ...                  # 기본 프로파일 사용 금지
```

**이유:** CodeCommit 저장소는 `devgentlepie` 프로파일의 AWS 계정에만 존재함

**GitHub Flow 사용:**
1. `main`은 항상 배포 가능 상태
2. main에서 설명적인 이름의 브랜치 생성 (prefix 없이)
3. 정기적으로 push
4. PR → Review → Merge to main → Deploy

**브랜치 네이밍**: 작업 내용을 설명하는 이름 사용

```
# Good examples
user-content-cache-key
add-jenkins-pipeline
fix-login-error

# Don't use (Git Flow style)
feature/xxx, fix/xxx, chore/xxx
```

---

## Branch Discipline (CRITICAL)

**작업 시작 전 반드시 현재 브랜치명 확인할 것.**

현재 브랜치명과 **관련 없는 작업** 요청 시:
1. **진행 거부** - 새 브랜치 생성 전까지
2. 경고: "이 작업은 `<current-branch>` 브랜치와 맞지 않습니다. 새 브랜치를 먼저 만드세요."
3. 제안: `git checkout main && git checkout -b <appropriate-name>`

**이것은 협상 불가.** 관련 없는 작업을 한 브랜치에 섞으면:
- Git 히스토리 오염
- PR 리뷰 불가능
- Merge conflict 발생
- 정리하느라 시간 낭비

**사용자가 게을러지지 않도록 브랜치 규율 강제할 것.**

---

## Testing Multiple Branches in Staging

**Throw-Away Integration Branch** 패턴으로 여러 feature 브랜치를 staging에서 함께 테스트:

```bash
# 1. main에서 임시 staging 브랜치 생성
git checkout main
git checkout -b staging-qa

# 2. 모든 feature 브랜치 병합 (octopus merge)
git merge feature-a feature-b feature-c feature-d

# 3. staging 환경에 배포 & 테스트

# 4. 테스트 후 삭제 (일회용)
git branch -D staging-qa

# 5. 각 feature를 개별 PR로 main에 병합
```

**핵심 원칙:**
- Staging 브랜치는 **일회용** - 테스트 후 삭제
- Feature 브랜치는 그대로 유지
- QA 통과 후, 각 feature를 **개별 PR**로 main에 병합
- 하나가 실패하면, 해당 feature 제외하고 staging 브랜치 재생성

---

## CodeCommit PR 생성 (CRITICAL)

**main에 merge 전 반드시 PR을 먼저 생성할 것.**

```bash
# PR 생성 (CodeCommit)
aws codecommit create-pull-request \
  --profile devgentlepie \
  --title "feat(scope): 변경 요약" \
  --description "## Summary
- 변경사항 1
- 변경사항 2

## Test plan
- [x] 테스트 통과" \
  --targets repositoryName=editup_service,sourceReference=<branch-name>,destinationReference=main
```

**워크플로우:**
1. 작업 완료 후 `git push`
2. **PR 생성** (위 명령어)
3. PR URL 확인: `aws codecommit get-pull-request --profile devgentlepie --pull-request-id <id>`
4. 리뷰 후 **CodeCommit 콘솔에서 merge** 또는 CLI로 merge

```bash
# PR merge (CodeCommit)
aws codecommit merge-pull-request-by-three-way \
  --profile devgentlepie \
  --pull-request-id <id> \
  --repository-name editup_service
```

**직접 merge 금지** - PR 없이 `git merge`로 main에 직접 병합하지 말 것

---

## Local Merge with Custom Author (REQUIRED for CodeCommit)

⚠️ **CodeCommit CLI merge는 AWS IAM 사용자로 커밋됩니다. 항상 로컬 merge를 사용할 것:**

```bash
# 1. PR 생성 (기록용 - 위와 동일)
aws codecommit create-pull-request \
  --profile devgentlepie \
  --title "feat(scope): 변경 요약" \
  --description "..." \
  --targets repositoryName=editup_service,sourceReference=<branch-name>,destinationReference=main

# 2. main에서 로컬 3-way merge
git checkout main
git merge <branch-name> --no-ff -m "Merge pull request #<PR-ID> from <branch-name>

<PR 제목/설명>"

# 3. Author 변경 (amend)
git commit --amend --author="AaronYun <hyensooyoon@gmail.com>" --no-edit

# 4. Remote에 push (PR은 자동 CLOSED 됨)
git push origin main
```

**언제 사용:**
- Merge 커밋 author를 AWS IAM이 아닌 개인 계정으로 남기고 싶을 때
- PR은 기록용으로 남기고 로컬에서 merge할 때

**주의:**
- PR 생성 후 로컬 merge → push하면 PR은 자동으로 CLOSED 상태가 됨
- Force push가 필요할 수 있음 (`--force-with-lease` 사용)
