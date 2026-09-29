# 블록 블라스트 (Block Blast)

구글 플레이 인기 퍼즐 **Block Blast!** (`com.block.juggle`)를 **Godot 4.7**로 구현한 8×8 블록 퍼즐입니다. Web(HTML5)으로 내보내 사내 112 서버에서 서비스합니다.

- 플레이: [http://192.168.219.112/block-game/](http://192.168.219.112/block-game/) · 외부 [https://minohlee.mooo.com/block-game/](https://minohlee.mooo.com/block-game/)

## 게임 소개

- **8×8 보드와 3개 한 세트**: 하단 트레이의 블록 3개를 원하는 순서로 드래그해 놓습니다. 회전과 시간 제한은 없습니다.
- **라인 폭발과 콤보**: 가로·세로 줄을 채우면 터집니다. 연속으로 터뜨리면 콤보 배율이 붙고, 3번까지는 못 지워도 콤보가 유지됩니다. 보드를 완전히 비우면 퍼펙트 클리어 보너스를 받습니다.
- **공정한 블록 지급**: 보드를 분석해 필요한 블록을 우선 지급하고, 세 블록을 어떤 순서로든 모두 놓을 수 있는 세트만 줍니다.
- **세 가지 모드**
  - 클래식: 끝없이 최고 점수에 도전
  - 오늘의 챌린지: 모든 사람이 같은 블록 순서로 겨루는 일간 랭킹
  - 어드벤처: 시작 보드·목표(점수/줄/보석)·이동 제한이 있는 스테이지 20개, 별 3단계
- **랭킹과 메타**: 로그인 없는 프로필(닉네임·아바타), 전체·주간·오늘 랭킹, 업적 17개, 블록 스킨 4종
- **연출**: 줄 예고 하이라이트, 연쇄 폭발, 음정이 오르는 콤보음, 화면 흔들림, 모바일 진동(설정에서 끌 수 있음)

## 문서

| 문서 | 내용 |
|---|---|
| [docs/GAME_DESIGN.md](docs/GAME_DESIGN.md) | 원작 재미 요소 분석과 게임 기획 |
| [docs/PROJECT_OVERVIEW.md](docs/PROJECT_OVERVIEW.md) | 코드 구조, 서버 API, 빌드·배포, 테스트 |
| [docs/TASKS.md](docs/TASKS.md) | 작업 목록과 진행 기록 |
| [docs/ADVENTURE_MODE.md](docs/ADVENTURE_MODE.md) | 어드벤처 모드 사양과 밸런스 기록 |
| [docs/SCORING_RULES.md](docs/SCORING_RULES.md) | 점수 규칙, 배치 기록 형식, 서버 검증 |

## 실행

```bash
run_game.bat
```

Godot 4.7.2(WinGet 설치 경로 또는 PATH의 `godot`)로 프로젝트를 엽니다.

## 빌드와 배포

1. Godot에서 `Web` 프리셋으로 내보내기 → `build/web/`
2. `python tools/patch_web.py`
3. `python tools/deploy_112.py`
4. 서버 라우터를 바꿨다면 `tools/server_block_leaderboard.js`, `tools/block_replay.js`, `tools/block_rules.json`을 112 서버의 라우터 위치에 함께 반영합니다.

블록 모양이나 점수 규칙을 바꾸면 서버 검증 규칙도 다시 내보냅니다.

```bash
Godot_v4.7.2-stable_win64_console.exe --headless --path . res://tools/export_rules.tscn
```

## 테스트

헤드리스 테스트 씬이 `tests/`에 있습니다. 실행 방법과 목록은 [docs/PROJECT_OVERVIEW.md](docs/PROJECT_OVERVIEW.md) 8장을 참고하세요.
