# 블록 블라스트 (Block Blast) — 프로젝트 개요

> 현재 코드(`master`, 커밋 `f8e8f1e` 기준)를 분석해 정리한 문서입니다.
> 기존 `README.md`는 초기 버전(인스타그램 로그인/친구 랭킹) 기준이라 현재 구현과 다른 부분이 있습니다. 차이점은 [부록: README와의 차이](#부록-readme와의-차이)를 참고하세요.

## 1. 한눈에 보기

| 항목 | 내용 |
|---|---|
| 장르 | 8×8 블록 퍼즐 (구글 플레이 *Block Blast!* `com.block.juggle` 모작) |
| 엔진 | Godot 4.7 (GDScript), 렌더러 `GL Compatibility` |
| 해상도 | 720×1280 세로 고정, `canvas_items` 스트레치 + `keep` 비율 |
| 주 배포 대상 | Web (HTML5/WASM, 스레드 미사용) |
| 백엔드 | Node.js + Express 라우터 (JSON 파일 DB) — 실시간 전체/주간 랭킹 |
| 배포처 | 사내 112 서버 `http://192.168.219.112/block-game/` (`/block-blast/` 심볼릭 링크) |
| 코드 규모 | GDScript 약 2,800줄, Python 도구 약 1,200줄, JS 서버 약 380줄 |

## 2. 디렉터리 구조

```
block/
├── project.godot            # 엔진 설정, Autoload(SoundManager, LeaderboardManager)
├── export_presets.cfg       # Web 내보내기 프리셋 → build/web/index.html
├── run_game.bat             # 로컬 Godot 에디터로 프로젝트 실행
├── scenes/                  # .tscn 씬
│   ├── main.tscn            # 루트 씬: 헤더, 보드, 트레이, 홈 화면, 모든 모달 포함
│   ├── board.tscn           # 8×8 보드 (Slots / Ghosts / Pieces / Effects 레이어)
│   ├── block_piece.tscn     # 드래그 가능한 블록 조각
│   ├── cell_blast.tscn      # 셀 폭발 파티클(CPUParticles2D)
│   ├── floating_text.tscn   # 칭찬/점수 플로팅 텍스트
│   ├── leaderboard_modal.tscn
│   ├── settings_modal.tscn
│   ├── profile_setup_modal.tscn
│   └── revive_modal.tscn
├── scripts/                 # 씬별 스크립트 + 매니저
├── assets/
│   ├── sprites/             # 8색 블록, 슬롯/고스트, UI 아이콘, 스파클
│   ├── avatars/             # 프로필 아바타 8종 (avatar_1~8.png)
│   ├── sfx/                 # place/clear/combo_1~7/gameover/record 등 WAV
│   └── fonts/font.ttf       # 한글 폰트
├── tools/                   # 에셋 생성·웹 패치·배포·서버 코드
└── build/web/               # Web 내보내기 결과물 (커밋되어 있음)
```

## 3. 아키텍처

### 3.1 씬 / 노드 구성 (`main.tscn`)

```
MainGame (Control, main.gd)
├── Background, Camera2D (화면 흔들림), ComboAura (콤보 오라 테두리)
├── BoardBackground, Board (board.tscn)
├── TrayPlates (Plate0~2: 하단 트레이 받침)
├── [런타임] BlockPiece × 3   ← main.gd가 생성
└── UI
    ├── Header (홈/설정/랭킹/사운드 버튼, SCORE, BEST)
    ├── ComboBanner ("COMBO x3  ● ● ○")
    ├── GameOverModal
    ├── LeaderboardModal, SettingsModal, ProfileSetupModal, ReviveModal
    └── StartScreen (홈 로비: 프로필 카드, 시작/랭킹/설정)
```

화면 전환은 별도 씬 전환 없이 **하나의 씬에서 모달/오버레이의 `visible` 토글**로 처리합니다.

### 3.2 스크립트 역할

| 스크립트 | 타입 | 역할 |
|---|---|---|
| `main.gd` (`MainGame`) | Control | 게임 루프 총괄: 입력(마우스/터치) 처리, 트레이 생성, 점수·콤보 계산, 게임오버/부활, 화면 전환, 최고점 저장 |
| `board.gd` (`Board`) | Node2D | 8×8 그리드 상태, 배치 판정, 고스트 프리뷰, 라인 클리어 예고 하이라이트, 라인 클리어 연출, 부활 폭탄, 블록 스폰용 보드 분석(`get_shape_affinity` 등) |
| `block_data.gd` (`BlockData`) | RefCounted (static) | 블록 모양 32종 정의, 기본 가중치, **적응형 3개 블록 생성 알고리즘** |
| `block_piece.gd` (`BlockPiece`) | Node2D | 조각 비주얼 생성, 트레이 자동 축소, 드래그(손가락 오프셋 −110px), 복귀/딤 처리 |
| `sound_manager.gd` | Autoload | 12채널 AudioStreamPlayer 풀, 라인 수에 따른 화음, 콤보 단계별 음정 상승 |
| `leaderboard_manager.gd` | Autoload | 로컬 프로필(user_id/닉네임/아바타) 관리, 랭킹 API 통신(HTTPRequest) |
| `settings_manager.gd` | static | 사운드/화면 흔들림/고스트 프리뷰 설정을 `user://game_settings.json`에 저장 |
| `leaderboard_modal.gd` | ColorRect | 전체/주간 탭 랭킹 목록, 내 순위 표시, 닉네임 변경 |
| `settings_modal.gd` | ColorRect | 아바타·닉네임 편집, 옵션 토글, 프로필 초기화 |
| `profile_setup_modal.gd` | ColorRect | 최초 실행 시 아바타·닉네임 설정(추천 칩, 랜덤 닉네임) |
| `revive_modal.gd` | ColorRect | 5초 카운트다운 "두 번째 기회" 팝업 |
| `cell_blast.gd`, `floating_text.gd` | Node2D | 단발성 이펙트 (Tween 후 자동 `queue_free`) |
| `auth_manager.gd` | static | **레거시**. 과거 인스타그램 친구 랭킹용. 현재는 `main.gd`에서 `init_auth()`만 호출되고 실제로 쓰이지 않음 |

### 3.3 로컬 저장 파일 (`user://`)

| 파일 | 내용 |
|---|---|
| `block_blast_save.cfg` | 최고 점수 (`[game] best_score`) |
| `game_settings.json` | 사운드 / 화면 흔들림 / 고스트 프리뷰 on·off |
| `player_profile.json` | `user_id`, 닉네임, 아바타 ID, 초기 설정 완료 여부, 마지막 순위·최고점 |
| `instagram_profile.json` | 레거시 AuthManager 데이터 |

## 4. 게임플레이 흐름

```
앱 시작 → StartScreen(홈)  ─(최초 실행이면 ProfileSetupModal)
   └ [시작] → start_new_game()
        └ _spawn_new_tray()  ← BlockData.get_adaptive_trio()
             └ 드래그 → 고스트 프리뷰 + 라인 클리어 예고
                  └ 놓기 → board.place_piece()
                       ├ 실패 → 트레이로 복귀
                       └ 성공 → 배치 점수 → check_and_clear_lines() → 콤보/점수
                            ├ 트레이가 비면 새 3개 생성
                            └ 놓을 수 있는 조각이 없으면
                                 ├ 첫 번째: ReviveModal (부활 폭탄)
                                 └ 두 번째 이후 / 거절 / 5초 경과: GAME OVER → 점수 서버 전송
```

### 4.1 입력 & 배치

- 마우스와 터치를 모두 `_input`에서 직접 처리하며, 멀티터치 시 처음 잡은 손가락(`drag_touch_id`)만 추적합니다.
- 조각 선택은 중심에서 95px 이내 또는 조각 영역 +40px 내 클릭 시 가장 가까운 조각이 선택됩니다.
- 드래그 중 조각은 손가락보다 **110px 위**에 표시되고 실제 크기(스케일 1.0)로 확대됩니다.
- 배치 좌표는 조각의 좌상단을 셀 간격(78px)으로 반올림하여 계산합니다(`Board.get_target_placement`).
- 트레이에서 놓을 수 없는 조각은 투명도 0.42로 딤 처리됩니다.

### 4.2 점수 계산 (`main.gd`)

| 항목 | 공식 |
|---|---|
| 배치 점수 | 놓은 칸 수 × 1 |
| 라인 기본 점수 | `10 × L²` (L = 동시에 지운 줄 수, 가로+세로 합산) |
| 콤보 배율 | `1 + 0.45 × C` |
| 콤보 보너스 | `15 × C + 5 × C²` |
| 라인 클리어 총점 | `int(10L² × (1 + 0.45C)) + 15C + 5C²` |

`C`는 이번 클리어를 포함한 콤보 수입니다(첫 클리어 = 1). 예: 첫 1줄 클리어 → 14 + 20 = **34점**.

### 4.3 콤보 & 유예(Grace) 규칙

- 라인을 지우면 `combo_count += 1`, 유예 횟수를 **3**으로 리셋합니다.
- 라인을 못 지운 배치마다 유예 1 감소, 0이 되면 콤보 종료. 즉 **3번 연속 헛놓기 전까지 콤보 유지**.
- 배너에 남은 유예가 `● ● ○` 형태로 표시되며, 1회 남으면 붉은색 경고 펄스가 나옵니다.
- 칭찬 문구: COOL / DOUBLE / TRIPLE (줄 수 기준), GREAT(2) · AMAZING(3) · UNBELIEVABLE(5) · MASTER(7) · LEGENDARY(10) · GODLIKE(15) (콤보 기준).
- 콤보 3 이상: 시안 네온 오라, 5 이상: 금색 불꽃 오라.

### 4.4 부활(Second Chance)

- 게임당 1회. 더 이상 놓을 곳이 없을 때 5초 카운트다운 팝업이 뜹니다(광고 등 조건 없이 무료).
- 수락 시 `Board.execute_revive_bomb()`: 중앙 4×4 영역의 블록을 모두 제거하고, 8칸 미만이면 무작위 칸을 추가로 제거(최대 12칸)한 뒤 새 트레이를 지급합니다.

## 5. 블록 생성 알고리즘 (`BlockData.get_adaptive_trio`)

원작의 "필요한 블록이 잘 나오는" 느낌을 재현하는 핵심 로직입니다.

### 5.1 블록 목록 (32종)

1×1 점(평소 제외, 비상용), 도미노 2, 3줄 2, 작은 코너 4, 2×2, 4줄 2, L 4, T 4, S/Z 4, 5줄 2, 큰 L(3×3 코너) 4, 3×3. 모양별 색상은 고정입니다.

### 5.2 보드 친화도(Affinity)

`Board.get_shape_affinity(shape)`는 가능한 모든 위치에 놓아보고 최고 점수를 반환합니다.

- 놓을 수 있음: 기본 5점
- 줄을 완성함: 줄당 +125점
- 줄을 7/8로 만듦: +28점, 6/8로 만듦: +14점
- 어디에도 못 놓음: −1

동적 가중치 = `기본 가중치 × (1 + affinity × 0.18)`. 기본 가중치는 도미노(4.5)·3줄(3.8)·2×2(3.5)가 높고, S/Z(0.7)·큰 L(0.8)이 낮습니다.

### 5.3 슬롯별 역할

| 슬롯 | 역할 | 선택 규칙 |
|---|---|---|
| A | 해결사 | 도미노·작은 코너·2×2 중 가중치 추첨 |
| B | 라인 완성 / 구원 | 위기 상황이거나, (콤보 중 또는 보드 40% 이상) 85% 확률(유예 1이면 95%)로 **줄을 지울 수 있는 블록**. 아니면 75% 확률로 7/8·6/8 줄을 채우는 블록, 그 외 직선/T/L/S/Z |
| C | 압박 / 밸런서 | 위기 시 4칸 이하 안전 블록만. 여유(보드 45% 이하) + (점수 400↑ 또는 콤보 2↑)이면 50% 확률로 큰 블록(3×3·큰 L·5줄). 그 외 전체 가중치 추첨 |

- **위기 판정**: 보드 채움 70% 이상 또는 놓을 수 있는 모양이 4종 이하.
- 어떤 모양도 못 놓으면 1×1 점 3개를 지급합니다.
- 최종적으로 순서를 섞어 역할을 추측할 수 없게 합니다.

## 6. 연출 · 사운드

- **배치**: 스쿼시&스트레치 바운스 트윈.
- **라인 클리어 예고**: 드래그 중 완성될 줄을 금색으로 빛나게 하고 기존 블록을 1.08배 확대.
- **클리어**: 중심에서 가까운 칸부터 16ms 간격 도미노 폭발, 흰색 플래시 + 파티클.
- **화면 흔들림**: 줄 수·콤보에 비례한 Camera2D 흔들림 (설정에서 끌 수 있음).
- **사운드**: 2줄 이상이면 장3도, 3줄 이상이면 완전5도 화음을 추가. 콤보는 `combo_1~7.wav`를 기반으로 온음계(Diatonic) 단계만큼 음정을 올려 재생.
- 에셋(스프라이트·WAV)은 모두 `tools/generate_*.py`로 절차적으로 생성되었습니다.

## 7. 랭킹 백엔드

### 7.1 클라이언트 (`LeaderboardManager`)

- 최초 실행 시 `usr_<unix시간>_<랜덤12자>` 형식의 `user_id`와 `블록러_123` 같은 임시 닉네임, 랜덤 아바타를 발급합니다(별도 로그인 없음).
- API 주소: Web에서는 `window.location.origin + /api/block-game`, 그 외(에디터/데스크톱)는 `http://192.168.219.112:3000/api/block-game`.
- 게임오버 시 점수 > 0이면 자동 제출하고 순위를 게임오버 화면에 표시합니다.

### 7.2 서버 (`tools/server_block_leaderboard.js`)

Express 라우터로, 112 서버의 기존 Node 앱에 마운트되어 동작합니다. 데이터는 `data/block_leaderboard.json` 단일 파일에 저장하며, 쓰기는 Promise 큐로 직렬화합니다. 최초 생성 시 봇 유저 8명이 시드됩니다.

| 메서드 | 경로 | 설명 |
|---|---|---|
| GET | `/leaderboard?type=all\|weekly&limit=&user_id=` | 순위 목록(최대 100) + 내 순위. 주간은 ISO 주차(`2026-W40`) 기준 |
| POST | `/score` | `{user_id, nickname, avatar_id, score}` → 최고점/주간 최고점 갱신, 순위 반환. 점수 0~2,000,000 검증 |
| POST | `/profile` | 닉네임·아바타 저장 |
| POST | `/nickname` | 닉네임만 변경 (구버전 호환) |

> `tools/server/block_leaderboard.js`는 `avatar_id` 지원 이전의 구버전 사본입니다.

## 8. 빌드 · 배포

1. **로컬 실행**: `run_game.bat` (WinGet으로 설치된 Godot 4.7.2 → 없으면 PATH의 `godot`).
2. **Web 내보내기**: Godot에서 `Web` 프리셋으로 `build/web/index.html` 생성.
3. **웹 패치**: `python tools/patch_web.py`
   - AudioWorklet 미지원 환경(HTTP 비보안 컨텍스트)에서 오디오가 죽지 않도록 `index.js` 패치
   - `secure context` 필수 기능 체크 제거, 페이지 제목·전체화면 CSS 주입
4. **배포**: `python tools/deploy_112.py`
   - SSH 호스트 `local-ai-server`의 `/home/lmo0317/apps/planner/public/block-game`에 tar 업로드
   - `block-blast → block-game` 심볼릭 링크 생성
   - 메인 허브 `hub.html`에 게임 카드 추가(백업 `hub.html.bak-before-block` 생성)

### 에셋 생성 도구

| 스크립트 | 생성물 |
|---|---|
| `generate_assets.py` | 초기 스프라이트 + 모든 효과음(WAV 합성) |
| `generate_faceted_assets.py` | 평면 베벨 스타일 블록 |
| `generate_original_blocks.py` | 원작 스타일 블록(현재 사용 중인 최신 버전) |
| `generate_avatars.py` | 원형 아바타 8종 + UI 아이콘 |

(모두 Pillow 필요)

## 9. 참고 · 개선 포인트

코드 분석 중 확인된 사항입니다.

- **화면 흔들림 중복**: 라인 클리어 시 `_process_line_clears`의 카메라 흔들림과 `board.lines_cleared` 시그널에 연결된 `_shake_screen`(보드 위치 트윈)이 동시에 실행됩니다.
- **레거시 코드**: `auth_manager.gd`(인스타그램 친구 랭킹)는 사실상 미사용입니다. 루트의 `test_gameplay.gd.uid`, `test_insta_ranking.gd.uid`는 원본 `.gd` 없이 남은 파일입니다.
- **서버 코드 중복**: `tools/server/block_leaderboard.js`(구버전)와 `tools/server_block_leaderboard.js`(최신)가 공존합니다.
- **`get_adaptive_trio`의 검증 루프**: 세 조각 모두 `all_fitting`에서 뽑히므로 "놓을 수 있는 수가 없음" 분기는 실제로는 타지 않습니다. 진짜 "세 조각을 순서대로 모두 놓을 수 있는지" 검증은 아직 없습니다.
- **텍스처 로드**: 배치/클리어 때마다 `load("res://assets/sprites/block_%s.png")`를 호출합니다(Godot 리소스 캐시로 큰 문제는 없지만 사전 로드 가능).
- **점수 검증**: 서버는 범위 검사만 하므로 클라이언트 위조 점수를 막지 못합니다.
- **닉네임 길이**: UI는 12자, `LeaderboardManager`는 15자, 서버는 20자로 제한이 서로 다릅니다.

## 부록: README와의 차이

| README 내용 | 현재 코드 |
|---|---|
| 인스타그램 로그인 & 친구 랭킹 | 제거됨 → 닉네임+아바타 프로필, 서버 기반 전체/주간 랭킹 |
| 콤보음 펜타토닉 음계 | 온음계(Diatonic) 음정 상승 + 줄 수별 화음 |
| 칭찬: COOL~UNBELIEVABLE | MASTER / LEGENDARY / GODLIKE 추가 |
| 블록 무작위 균형 분배 | 보드 분석 기반 적응형 생성(해결사/완성/압박 슬롯) |
| (없음) | 콤보 유예 3회, 부활 모달, 라인 클리어 예고, 카메라 흔들림, 홈 화면, 설정 화면 |
