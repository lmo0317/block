# 아트 가이드 — 도트 미니 시티

아트 디렉터 스킬(`art-director`)이 그림을 만들기 전에 읽는 기준입니다. 바뀌면 여기부터 고칩니다.

## 스타일 한 줄

정면에서 살짝 내려다본 **세밀한 도트 일러스트**(Codex 이미지 생성). 1px 진한 외곽선, 따뜻하고 밝은 색, 빛은 왼쪽 위. 카이로소프트 경영 게임처럼 아기자기하게.

2026-10-02에 16px 코드 도트에서 이 스타일로 바꿨습니다(사용자 요청 "이풍으로 싹다 교체"). 코드 도트(`tools/generate_sprites.py`, `atlas.png`)는 그림이 없을 때의 대체용과 작은 UI 아이콘(경고, 속도 버튼)에만 남아 있습니다.

## 기준 그림

`art/style_ref.png`(빨간 지붕 집). Codex로 새 그림을 만들 때 항상 붙입니다(`tools/codex_art.py`가 자동으로 붙임).

## 규칙

- **시점**: 정면 입면을 위에서 약 30도. 아이소메트릭(비스듬히 돌린 시점) 금지. 옆벽이 보이지 않게
- **배경**: 투명. 땅·그림자·글자·로고 없음. 간판에는 글자 대신 작은 그림
- **크기**: 건물은 가로 96px로 맞춰 저장(`assets/sprites/hd`), 게임에서는 칸 너비(16단위 중 15)에 맞춰 그림. 세로는 그림 비율대로라 아파트·시계탑·관람차는 윗칸으로 솟음
- **질감**: 땅(풀·물·아스팔트)은 64×64 이음매 없는 질감. 도로 16종·다리·빈 구역은 질감으로 코드에서 조립(`tools/generate_ground.py`)해 이음매를 정확히 맞춤
- 주거·상업·공업은 빈 땅, 공사장, 건물 모두 한눈에 구별돼야 함
- 그림 안에 글자를 넣지 않음. 한글은 게임 글꼴로
- 게임 안 그림은 차분하게. 큰 일러스트는 타이틀 액자 안에만

## 만드는 방법

| 종류 | 방법 | 위치 |
|---|---|---|
| 건물·시설·공사장·나무·주민·차·도구 아이콘·동전 | Codex(`tools/codex_art.py`, 프롬프트는 파일 안 `ASSETS`) | 원본 `art/raw/`(git 제외), 게임용 `assets/sprites/hd/` |
| 풀·물·아스팔트 질감 | Codex 질감 + 이음매 보정 | 같은 스크립트 |
| 도로·다리·빈 구역·차 색 변형·앱 아이콘 | 코드 조립 | `tools/generate_ground.py` |
| 경고 아이콘, 속도 버튼, 불꽃 | 코드 도트 | `tools/generate_sprites.py` → atlas |
| 타이틀 일러스트 | Gemini | 원본 `art/concept_keyart_b.png`, 게임용 `assets/art/title.jpg` |
| 스토어 스크린샷 | 실제 게임 캡처 | (출시 때) `store/` |

새 그림 추가: `ASSETS`에 한 줄 넣고 `python tools/codex_art.py --gen <이름>` → 검수 시트 확인 → 게임 코드에서 이름으로 사용(`Art.tex(name)`).

## 사용자가 거절한 것

- 2026-10-02: 주거·상업·공업을 칠해도 빈 땅과 공사장이 똑같아 보임 → 구역별 땅·표지판·공사장
- 2026-10-02: 16px 코드 도트 → Codex 세밀한 도트 스타일로 전부 교체
- (퍼즐블록) 화려한 배경은 "홍보 이미지 같다" → 게임 화면 안에서는 쓰지 않음
- 실제 게임·회사 이름과 로고(Cities: Skylines, Kairosoft)는 저장소에 넣지 않음

## 에셋 목록

| 이름 | 방법 | 출처 | 쓰는 곳 |
|---|---|---|---|
| house_a/b/c, rowhouse(_b), apartment(_b) | Codex | `codex_art.py` ASSETS | 주거 1~3단계 |
| bakery·cafe·restaurant·clothes·books·flowers (+_2), dept(_b) | Codex | 〃 | 상업 1~3단계 |
| workshop, factory, hightech | Codex | 〃 | 공업 1~3단계 |
| power, water_tower, park, tree, forest, fountain, police, fire, hospital, school, clock, wheel, stadium | Codex | 〃 | 시설·숲 |
| scaffold_r/c/i | Codex | 〃 | 공사 중 |
| cit0-5, car_h, car_v | Codex | 〃 | 주민·차 |
| ui_road/res/com/ind/fac/bulldoze/hand, coin | Codex | 〃 | 도구 막대, 동전 효과 |
| tex_grass, tex_water, tex_asphalt | Codex 질감 | 〃 | 땅 |
| road0-15, bridge0-15, lot_r/c/i, car_h0-3/v0-3, icon.png | 코드 조립 | `generate_ground.py` | 도로·다리·빈 구역·차·앱 아이콘 |
| icon_power/water/road, ui_pause/play1-3, ui_undo/book/menu, fire0-1 | 코드 도트 | `generate_sprites.py` | 경고·속도·메뉴 |
| concept_keyart_a/b | Gemini | 콘셉트 프롬프트 | b → 타이틀 |

검수: `python ~/.claude/skills/art-director/scripts/contact_sheet.py assets/sprites/hd --bg grass --out <sheet.png>`
