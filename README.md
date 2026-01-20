# Claude Code Settings

Claude Code 설정 백업 및 동기화 저장소

## 구조

```
claude/
├── CLAUDE.md                 # 전역 지침 (커밋 규칙, Git 워크플로우 등)
├── settings.json             # 플러그인, statusLine, thinking 설정
├── skills/
│   ├── design-first/         # Scout-Architect-Estimator 워크플로우
│   └── backup/               # 백업 관리 스킬
├── plugins/
│   └── installed_plugins.json
├── install.sh                # 설치/복원 스크립트
├── sync.sh                   # 자동 백업 스크립트
└── com.user.claude-sync.plist  # macOS launchd 설정
```

## 설치

```bash
git clone git@github.com:temeraire97/claude-setting.git ~/dotfiles/claude
cd ~/dotfiles/claude
./install.sh
```

## 자동 백업

매일 19:00 KST에 자동 실행됩니다.

```bash
# 서비스 등록
ln -sf ~/dotfiles/claude/com.user.claude-sync.plist ~/Library/LaunchAgents/
launchctl load ~/Library/LaunchAgents/com.user.claude-sync.plist

# 상태 확인
launchctl list | grep claude-sync
```

## 수동 명령어

| 명령어 | 설명 |
|--------|------|
| `/backup` | 백업 상태 확인 |
| `/backup now` | 즉시 백업 |
| `/backup diff` | 변경사항 확인 |
| `/backup restore` | 백업에서 복원 |
| `/backup log` | 로그 확인 |

## 플러그인

| 플러그인 | 상태 |
|----------|------|
| claude-hud | 활성화 |
| claude-mem | 비활성화 |
