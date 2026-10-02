# 아트 가이드 — 도트 미니 시티

아트 디렉터 스킬(`art-director`)이 그림을 만들기 전에 읽는 기준입니다. 바뀌면 여기부터 고칩니다.

## 스타일 한 줄

위에서 살짝 기운 시점의 16px 도트. 진한 남보라 외곽선, 밝고 따뜻한 색, 카이로소프트처럼 작고 귀여운 느낌.

## 팔레트 (`tools/generate_sprites.py` 상수)

| 이름 | hex | 쓰는 곳 |
|---|---|---|
| 외곽선 INK | #2C2436 | 모든 건물·아이콘 외곽 |
| 풀 / 어두운 풀 / 밝은 풀 | #70C04C / #5CAA40 / #92D660 | 땅 |
| 물 / 어두운 물 / 밝은 물 | #4292E0 / #3476C4 / #8CC8F6 | 강·바다·분수 |
| 아스팔트 / 연석 / 차선 | #70707C / #CEC8BC / #F6E28C | 도로 |
| 나무판 / 어두운 나무 | #B07C48 / #7E5432 | 다리, 공사장 |
| 유리 | #84CEF4 | 창문 |
| 지붕 | 빨강 #D84A40, 파랑 #4670CC, 초록 #48A25C, 주황 #E88E3A, 보라 #965CB8, 갈색 #9C623E, 청록 #30A0A0 | 건물 |
| 벽 | 크림 #F8ECCC, 흰 #F0F0EC, 베이지 #E4CCA4, 회색 #BEBEC8, 분홍 #F8CED4, 민트 #C4E8D4 | 건물 |
| 구역 표시 | 주거 초록, 상업 파랑, 공업 노랑 (`Defs.ZONE_COLORS`) | 빈 땅 테두리, 수요 막대 |
| UI 창 / 금색 글자 | #243361 + 흰 테두리 / #FFD64D | `ui_kit.gd` |

## 규칙

- 크기: 칸 16×16. 건물은 16×24 또는 16×32이고, 아래 16줄이 칸에 앉고 나머지는 윗칸으로 솟음. 화면에서는 3배(48px)가 기본
- 외곽선 1px INK, 빛은 위쪽, 명암은 색마다 2~3단계(`shade(col, 0.7~1.25)`)
- 같은 단계 건물은 색 바꾸기(팔레트 교체)로 변형을 만든다. 거리 하나가 같은 그림으로 반복되지 않게
- 주거·상업·공업은 빈 땅, 공사장, 건물 모두 한눈에 구별돼야 함
- 그림 안에 글자를 넣지 않음. 한글은 게임 글꼴로
- 게임 안 그림은 차분하게. 일러스트는 타이틀 액자 안에만

## 만드는 방법

| 종류 | 방법 | 위치 |
|---|---|---|
| 땅·도로·건물·시설·주민·차·아이콘 | 코드 | `tools/generate_sprites.py` → `assets/sprites/atlas.png` + `atlas.json` |
| 앱 아이콘 | 코드(스프라이트 조합) | 같은 스크립트 `app_icon()` → `assets/sprites/icon.png` |
| 타이틀 일러스트 | Gemini | 원본 `art/`, 게임용 `assets/art/title.jpg`(720×720) |
| 스토어 스크린샷 | 실제 게임 캡처 | (출시 때) `store/` |

## Gemini 스타일 문구

```
cozy retro pixel-art city builder, Japanese management-sim charm, top-down slightly tilted view,
warm cheerful palette, crisp pixels, tiny chibi citizens, no text, no letters, no watermark, no logos
```

## 사용자가 거절한 것

- 2026-10-02: 주거·상업·공업을 칠해도 빈 땅과 공사장이 똑같아 보임 → 구역별 땅·표지판·공사장으로 바꿈
- (퍼즐블록) 화려한 Gemini 배경은 "홍보 이미지 같다" → 게임 화면 안에서는 쓰지 않음
- 실제 게임·회사 이름과 로고(Cities: Skylines, Kairosoft)는 저장소에 넣지 않음

## 에셋 목록

| 이름 | 파일 | 방법 | 출처 | 쓰는 곳 | 상태 |
|---|---|---|---|---|---|
| grass0-2, water0-1, forest, tree | atlas | 코드 | `grass_tile`, `water_tile`, `tree_cluster` | 땅 | 사용 중 |
| road0-15, bridge0-15 | atlas | 코드 | `road_tile(mask)` | 도로·다리 | 사용 중 |
| lot_r, lot_c, lot_i | atlas | 코드 | `lot_tile` | 빈 구역 | 사용 중 |
| scaffold_r/c/i | atlas | 코드 | `scaffold_zone` | 공사 중 | 사용 중 |
| house_a/b/c, rowhouse(+_b,_c), apartment(+_b,_c) | atlas | 코드 | `house`, `rowhouse`, `apartment`, `swap_family` | 주거 1~3단계 | 사용 중 |
| bakery·cafe·restaurant·clothes·books·flowers(+_2), dept(+_b) | atlas | 코드 | `shop`, `dept`, `swap` | 상업 1~3단계 | 사용 중 |
| workshop, factory, hightech (+_b) | atlas | 코드 | `workshop`, `factory`, `hightech`, `swap` | 공업 1~3단계 | 사용 중 |
| power, water_tower, park, fountain, police, fire, hospital, school, clock, wheel, stadium | atlas | 코드 | 각 함수 | 시설 | 사용 중 |
| cit0-5_0/1, car_h/v0-3, coin, icon_*, ui_* | atlas | 코드 | `citizen`, `car`, `icon`, `ui_icon` | 주민·차·UI | 사용 중 |
| icon.png | assets/sprites | 코드 | `app_icon` | 앱 아이콘 | 사용 중 |
| concept_keyart_a/b | art/ | Gemini | 콘셉트 프롬프트(2026-10-02) | b → 타이틀 | 사용 중 |

검수: `python ~/.claude/skills/art-director/scripts/contact_sheet.py assets/sprites/atlas.json --bg grass --out <sheet.png>`
