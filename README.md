# Claude Code Settings

Claude Code 설정 백업 및 복원 저장소.
`~/.claude/`의 사용자 설정을 백업하고, 새 머신에서 복원한다.

## 구조

```
claude/
├── CLAUDE.md                   # 전역 지침
├── settings.json               # 권한·hooks·statusLine·플러그인 설정
├── statusline-wrapper.sh       # statusLine 실행 스크립트
├── skills/                     # 커스텀 스킬 전체
├── agents/                     # 커스텀 서브에이전트 전체
├── hooks/                      # 커스텀 훅 스크립트
├── commands/                   # 커스텀 슬래시 커맨드 (존재 시)
├── plugins/
│   ├── installed_plugins.json  # 설치된 플러그인 목록
│   └── known_marketplaces.json # 마켓플레이스 목록
├── install.sh                  # 복원 스크립트
├── sync.sh                     # 백업 스크립트
└── com.user.claude-sync.plist  # macOS launchd 설정
```

## 설치 / 복원

```bash
git clone git@github.com:temeraire97/claude-setting.git ~/dotfiles/claude
cd ~/dotfiles/claude
./install.sh
```

`install.sh`가 수행하는 작업:

1. 설정 파일을 `~/.claude/`로 심볼릭 링크 (CLAUDE.md, settings.json, statusline-wrapper.sh)
2. 디렉토리를 통째로 심볼릭 링크 (skills/, agents/, hooks/, commands/)
3. `known_marketplaces.json` 기반 마켓플레이스 등록
4. `installed_plugins.json` 기반 플러그인 재설치 (`claude` CLI 필요)
5. launchd 자동 백업 등록

기존 실제 파일·디렉토리는 `*.backup.<타임스탬프>`로 보존된다.
실패한 마켓플레이스/플러그인은 `✗` 로그를 남기고 다음 항목으로 계속 진행한다.

## 자동 백업

매일 19:00에 `sync.sh`가 자동 실행되어 변경분을 커밋·푸시한다.
`install.sh`가 launchd 등록까지 처리하므로 별도 설정은 불필요하다.

```bash
# 상태 확인
launchctl list | grep claude-sync

# 수동 재등록 (필요시)
launchctl load ~/Library/LaunchAgents/com.user.claude-sync.plist
```

## 수동 명령어

| 명령어 | 설명 |
|--------|------|
| `/backup` | 백업 상태 확인 |
| `/backup now` | 즉시 백업 |
| `/backup diff` | 변경사항 확인 |
| `/backup restore` | 백업에서 복원 (install.sh 실행) |
| `/backup log` | 로그 확인 |

## 백업 제외 항목

다음은 의도적으로 백업하지 않는다.

| 항목 | 이유 |
|------|------|
| `~/.claude.json` | 라이브 OAuth 토큰 포함 — 버전관리 금지 |
| `settings.local.json` | 머신 로컬·민감 설정 (설계상 gitignore 대상) |
| `mcp.json` | Claude Code 표준 경로 아님 |
| `projects/`, `sessions/`, `todos/` 등 | 세션 기록·런타임 캐시 |

> 이 저장소는 **공개 저장소**다. 민감 정보가 들어갈 수 있는 파일은 백업 대상에서 제외한다.
