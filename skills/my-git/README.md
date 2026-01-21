# My Git Rules

Git 커밋, 브랜치, PR 관련 사용자 커스텀 규칙입니다.

---

## Commit Message Convention

커밋 메시지 생성 시:
1. `git status`와 `git diff`로 변경사항 확인
2. **한국어**로 Conventional Commits 형식 작성
3. 커밋 실행하지 말고 메시지만 제안 (사용자가 직접 커밋)
4. **fingerprint 금지** - "Generated with Claude Code", "Co-Authored-By: Claude" 절대 추가 금지

**형식:** `type(scope): message` - scope는 **필수**, 생략 금지

**Types:** `feat`, `fix`, `docs`, `style`, `refactor`, `test`, `chore`, `perf`, `ci`, `build`

---

## Git Workflow

**저장소**: AWS CodeCommit (GitHub 아님)
- `gh` CLI 대신 `aws codecommit` CLI 사용
- PR 생성: `aws codecommit create-pull-request --title "..." --description "..." --targets repositoryName=...,sourceReference=...,destinationReference=main`

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
