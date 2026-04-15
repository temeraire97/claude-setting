---
name: task-loop
description: |
  여러 태스크로 쪼개지는 대규모 구현 작업을 "브랜치 생성 → 태스크 분해 → 구현 팀 → git-master 커밋 → 검증 팀(병렬) → 재귀 수정 → PR 머지" 의 재귀 파이프라인으로 실행합니다.
  기능 개발, 대규모 리팩터링, 마이그레이션, 멀티 파일 변경 등 여러 커밋이 필요한 작업에 사용하세요.
  작은 단일 변경(타이포 수정, 1 파일 수정)에는 과한 프로세스이므로 사용하지 마세요.
---

# Task Loop — 재귀 파이프라인

> 하나의 작업 단위(Unit of Work)를 **Task 단위로 분해·커밋·검증**하는 재귀적 구현 프로세스.

---

## 1. 개요

**계층**: `Unit of Work(브랜치) → Task(커밋) → Verification(재귀 수정)`

1개 단위 작업 = 1 브랜치 = 1 PR. 브랜치 내부는 N개의 태스크로 쪼개지고, 각 태스크는 1 커밋에 대응된다. 모든 태스크 완료 후 **검증 팀이 병렬로 리뷰**하고, 이슈가 발견되면 같은 단위 작업 내에서 `[FIX]` 태스크로 재귀.

```
Unit of Work
   ├── 브랜치 생성 (prefix 없음, 설명형 이름)
   ├── TaskCreate 분해
   ├── 구현 루프
   │     └─ 각 task: in_progress → implement → git-master 커밋 → completed
   ├── 검증 팀 (병렬)
   │     ├─ code-reviewer
   │     ├─ architect-medium (복잡한 작업이면 architect/Opus)
   │     └─ WebSearch (현재 연도 포함)
   ├── ❓ 이슈 발견?
   │     └─ Yes → [FIX] TaskCreate → 구현 → git-master 커밋 → 경량 재검증(code-reviewer-low)
   │          └─ 재귀 깊이 최대 2회. 3회째는 사용자에게 상황 보고 + 의사결정 요청
   ├── PR 생성 (gh pr create)
   └── PR 머지 + 브랜치 삭제 (gh pr merge --merge --delete-branch)
```

---

## 2. 트리거 조건

다음 중 하나라도 해당하면 Task Loop를 적용:

- 변경이 3개 이상의 파일에 걸침
- 구현 + 테스트가 한 세션에 함께 들어감
- 검증이 필요한 설계 결정이 포함됨
- 사용자가 "팀 구성해서", "태스크 리스트", "검증해서" 같은 표현을 사용
- 이전 세션에서 작성된 계획서(plan file, 명세서)를 실행하는 맥락

**반대로 Task Loop을 쓰지 말아야 할 때**:
- 1~2 파일 단순 수정, 타이포 교정
- 이미 다른 브랜치에서 작업 중이라 브랜치 전환이 부적절
- 사용자가 "그냥 바로 고쳐줘" 같은 최소 프로세스를 요청
- 읽기/조사 위주 작업 (Explore로 충분)

---

## 3. 역할 (팀 구성)

| 팀 | 구성 | 투입 시점 | 산출물 |
|---|---|---|---|
| **구현 팀** | `executor` 에이전트 또는 메인 에이전트 직접 | 각 Task | 코드 + 커밋 |
| **검증 팀** | `code-reviewer` + `architect-medium` + `WebSearch` 병렬 | Task 전부 완료 직후 | 이슈 리포트 (OK/WARN/BLOCK) |
| **경량 재검증** | `code-reviewer-low` 단독 | `[FIX]` 커밋 완료 후 | 통과 판정 |

**원칙**:
- 작은 태스크(설정 한 줄, 어노테이션 추가)는 메인 에이전트가 직접 구현. executor 스폰 오버헤드가 구현 비용보다 큼.
- 복잡한 태스크(복합 로직, 여러 파일, reactive/async 체인)는 반드시 executor 스폰.
- 검증 팀은 **반드시 병렬** 실행. 단일 메시지에 여러 Agent 호출.

---

## 4. 단계별 흐름

### Step 1. 사전 확인

```
1. 영향받는 모든 저장소의 git 상태 확인
2. 현재 main이 최신인지 (git pull --ff-only)
3. 이전 관련 작업의 Done 조건 충족 여부
4. 사용자의 로컬 환경 규칙 확인 (CLAUDE.md, 빌드 금지 규칙 등)
```

### Step 2. 브랜치 생성

```bash
git checkout main
git pull --ff-only
git checkout -b {descriptive-name}
```

**브랜치 네이밍 규칙**:
- ❌ 금지: `feat/`, `fix/`, `chore/`, `docs/` 같은 Git Flow 스타일 prefix
- ✅ 권장: 작업을 설명하는 이름 (예: `redis-state-layer`, `user-content-cache`, `add-jenkins-pipeline`)
- 크로스 저장소 작업: 각 저장소에 **동일한 이름**으로 브랜치 생성

### Step 3. Task List 생성

```
TaskCreate × N
  - subject: imperative ("Add X", "Refactor Y")
  - description: 파일 경로 + 수용 조건 + 의존 정보
  - 마지막 태스크는 반드시 "Verification team review"
```

**태스크 분해 원칙**:
- 1 Task = 1 Commit = 1 파일 또는 1 논리적 변경
- 파일 4개 이상을 한 태스크에서 건드리면 쪼개기
- Task ID는 **생성 순서가 아닌 의존 순서**로 만들 것
- 검증 태스크를 반드시 별도로 포함

### Step 4. 구현 루프

각 Task마다:

```
1. TaskUpdate(in_progress)
2. 구현 (Edit/Write)
   - 의존 파일을 먼저 Read 또는 Grep으로 확인
   - 기존 패턴/컨벤션 답습 (신규 발명 금지)
3. Skill(git-master) 커밋 OR 직접 git add + git commit
   - 한국어 conventional commit (type(scope): message)
   - scope 필수
   - ⛔ 절대 Claude fingerprint 금지
4. TaskUpdate(completed)
```

**커밋 규칙**:
- `type(scope): 한국어 본문` 형식
- 1차 본문에는 WHY, 2차+ 본문에는 WHAT
- 1 커밋 = 논리적으로 분리 가능한 최소 단위
- untracked 파일 보호 — 필요한 파일만 명시 스테이징 (`git add .` 금지)
- 로컬 빌드 명령 금지 (`./gradlew build`, `npm run build` 등) — 사용자가 직접 검증

### Step 5. 검증 팀 (모든 Task 완료 후)

**3개 독립 에이전트 병렬 실행** (단일 메시지에 세 tool call):

```
Agent(code-reviewer)      → 코드 품질, 버그, 보안, 컨벤션
Agent(architect-medium)   → 설계 정합성, 계획서 일치, 아키텍처 건전성
WebSearch({query} 2026)   → 업계 베스트 프랙티스 (반드시 현재 연도 포함)
```

**복잡도에 따른 검증 깊이 조정**:
- 단순 변경: `code-reviewer-low` + WebSearch만
- 표준: 위 3종
- 복잡/위험한 변경: `code-reviewer`(Opus) + `architect`(Opus) + 2~3 WebSearch

### Step 6. 이슈 등급

검증 팀 출력은 반드시 다음 3등급 중 하나로 분류:

| 등급 | 의미 | 액션 |
|---|---|---|
| ✅ **OK** | 통과 | 진행 |
| ⚠️ **WARN** | 권장 수정 | 가능하면 반영, 시간 제약 시 TODO 기록 후 진행 |
| 🛑 **BLOCK** | 차단 | 반드시 수정 후 재검증 |

BLOCK이 하나라도 있으면 Step 7로, 없으면 Step 8로.

### Step 7. 재귀 수정 루프

```
1. 이슈별로 [FIX] TaskCreate
   - subject prefix: "[FIX] "
   - description: 원인 + 수정 범위 + 파일:라인
2. 구현 루프 (Step 4 반복)
3. 경량 재검증 (code-reviewer-low 단독, WebSearch 생략)
4. 재귀 깊이 제한:
   - 1회: 정상
   - 2회: 경고 출력 후 진행
   - 3회: 중단. 사용자에게 상황 보고 + 결정권 이양
```

### Step 8. PR 생성

```bash
git push -u origin {branch}
gh pr create --base main --head {branch} --title "type(scope): 요약" --body "..."
```

**PR 본문 템플릿**:

```markdown
## Summary
{1-3 bullet points, why + what}

### 변경 사항
- 파일/영역별 요약

### 설계 원칙
- 핵심 결정 사항

## Test plan
- [x] 완료된 자동 검증
- [ ] 수동 확인 필요한 항목

## 후속 작업 (선택)
{다음 단계 참조}
```

### Step 9. 머지 + 정리 (승인 시)

```bash
gh pr merge {N} --merge --delete-branch
# 로컬/원격 브랜치 자동 삭제
```

**주의**: 머지는 **사용자 승인 후**에만 실행. 자동 머지는 금지. 사용자가 `/git-master merge` 같은 명시적 명령을 줄 때만 수행.

---

## 5. 불변 규칙 (절대 어기면 안 됨)

1. **Claude fingerprint 금지** — 커밋/PR/문서 어디에도
2. **로컬 빌드 명령 금지** (`./gradlew build`, `npm run build`, `pnpm build` 등) — 사용자가 직접 검증
3. **브랜치 prefix 금지** — `feat/`, `fix/`, `chore/` 등
4. **한국어 commit message**, scope 필수
5. **untracked 파일 보호** — 명시 스테이징만, `git add .` 금지
6. **파괴적 git 명령 사용자 확인 후** — `reset --hard`, `push --force`, `branch -D` 등
7. **검증 팀은 병렬 실행** — 순차 실행 금지 (토큰 낭비 + 지연)
8. **WebSearch는 반드시 현재 연도 포함** — 구 정보 회귀 방지
9. **자동 머지 금지** — 사용자 명시 승인 후에만
10. **재귀 3회째는 escalate** — 무한 루프 방지

---

## 6. 권장 관행

- 태스크 ID 순서 = 의존 순서
- 1 PR = 1 Unit of Work (태스크 단위 PR 금지)
- 같은 작업이 여러 저장소에 걸치면 **각 저장소에 동일 이름 브랜치 + 각 저장소 PR 독립 생성**
- 검증 팀 출력은 **재귀적으로 신뢰**하되 2회 초과 시 사용자 개입
- 큰 태스크는 executor 스폰, 작은 태스크는 직접 구현
- 방어적 표기 선호 (`@Immutable`, `updatable=false`, `final`, `readonly` 등)
- 커밋 메시지는 WHY 먼저, WHAT 나중. 1차 줄은 50자 내외.

---

## 7. 다른 스킬과의 관계

| 스킬 | 관계 |
|---|---|
| `git-master` | Task Loop의 **커밋/브랜치/PR 단계**에서 호출. 규칙 일치 |
| `design-first` | Task Loop **진입 전** 복잡한 설계가 필요할 때 선행. Task Loop가 실행 단계를 담당 |
| `simplify` / `audit` / `polish` | Task Loop **내부 검증 단계**에서 추가 검증 레이어로 호출 가능 |
| `find-skills` | Task Loop 실행 중 특정 문제에 맞는 보조 스킬 탐색용 |

---

## 8. 체크리스트 (Unit of Work 1회 수명주기)

```
▢ 이전 작업의 완료 상태 확인
▢ main 최신화 (git pull --ff-only)
▢ 브랜치 생성 (prefix 없음, 설명형)
▢ TaskList 생성 (구현 + 검증 + (잠재적) 수정)
▢ 각 Task 루프:
   ▢ in_progress 마킹
   ▢ 구현 (Read → Edit/Write)
   ▢ git-master 커밋 (Korean, scope 필수, fingerprint 금지)
   ▢ completed 마킹
▢ 검증 팀 병렬 실행 (code-reviewer + architect + WebSearch 현재 연도)
▢ 이슈 있으면:
   ▢ [FIX] TaskCreate
   ▢ 수정 + 커밋
   ▢ 경량 재검증
   ▢ (재귀, 최대 2회)
▢ PR 생성 (gh pr create)
▢ 사용자 승인 대기
▢ 승인 시: gh pr merge --merge --delete-branch
▢ 회고/요약 응답 작성
```
