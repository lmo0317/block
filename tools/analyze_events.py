"""Compute GAME_DESIGN.md chapter 13 metrics from event JSONL logs.

Usage:
    python tools/analyze_events.py <events_dir_or_jsonl> [...]

The server writes events to data/events/YYYY-MM-DD.jsonl (see tools/server_block_leaderboard.js).
"""
import json
import os
import statistics
import sys
from collections import Counter, defaultdict
from datetime import datetime


def load_events(paths):
    files = []
    for p in paths:
        if os.path.isdir(p):
            files += [os.path.join(p, f) for f in sorted(os.listdir(p)) if f.endswith(".jsonl")]
        else:
            files.append(p)
    events = []
    for f in files:
        with open(f, encoding="utf-8") as fh:
            for line in fh:
                line = line.strip()
                if not line:
                    continue
                try:
                    events.append(json.loads(line))
                except json.JSONDecodeError:
                    pass
    events.sort(key=lambda e: e.get("ts", 0))
    return events


def pct(n, d):
    return f"{(100.0 * n / d):.1f}%" if d else "-"


def summarize(values):
    if not values:
        return "-"
    return f"평균 {statistics.mean(values):.1f} · 중앙값 {statistics.median(values):.1f} · 최대 {max(values):.1f} (n={len(values)})"


def combo_bucket(c):
    if c <= 0:
        return "0"
    if c <= 2:
        return "1-2"
    if c <= 4:
        return "3-4"
    if c <= 9:
        return "5-9"
    return "10+"


def main():
    if len(sys.argv) < 2:
        print(__doc__)
        sys.exit(1)
    events = load_events(sys.argv[1:])
    by_type = defaultdict(list)
    for e in events:
        by_type[e.get("event")].append(e)

    game_overs = by_type["game_over"]
    starts = by_type["game_start"]
    places = by_type["place"]
    revives = by_type["revive_result"]
    deals = by_type["tray_dealt"]

    print(f"이벤트 {len(events)}개 · 사용자 {len({e.get('user_id') for e in events})}명 · 게임오버 {len(game_overs)}판\n")

    print("[판 길이]")
    print("  플레이 시간(초):", summarize([g.get("duration_s", 0) for g in game_overs]))
    print("  배치 횟수:     ", summarize([g.get("moves", 0) for g in game_overs]))
    print("  점수:          ", summarize([g.get("score", 0) for g in game_overs]))

    quick = [s for s in starts if 0 <= s.get("secs_since_game_over", -1) <= 10]
    print("\n[즉시 재시작률] 게임오버 후 10초 안에 새 판 시작")
    print(f"  {len(quick)} / {len(game_overs)} = {pct(len(quick), len(game_overs))}")

    print("\n[판당 최대 콤보]")
    combos = [g.get("max_combo", 0) for g in game_overs]
    print("  ", summarize(combos))
    buckets = Counter(combo_bucket(c) for c in combos)
    for b in ["0", "1-2", "3-4", "5-9", "10+"]:
        print(f"    {b:>4}: {buckets.get(b, 0)}")

    crisis = [p for p in places if p.get("fill_after", 0) >= 0.70]
    print("\n[위기 구간 체류] 배치 후 점유율 70% 이상인 배치 비율")
    print(f"  {len(crisis)} / {len(places)} = {pct(len(crisis), len(places))}")

    print("\n[게임오버 원인]")
    print("  게임오버 시 점유율:", summarize([g.get("fill", 0) * 100 for g in game_overs]), "(%)")
    stuck = Counter(s for g in game_overs for s in g.get("remaining_shapes", []))
    print("  남아서 못 놓은 블록 상위:", ", ".join(f"{k}×{v}" for k, v in stuck.most_common(5)) or "-")

    accepted = [r for r in revives if r.get("accepted")]
    print("\n[부활 수락률]")
    print(f"  {len(accepted)} / {len(revives)} = {pct(len(accepted), len(revives))}")

    notes = Counter(d.get("note", "?").split("_")[0] for d in deals)
    print("\n[블록 생성 경로] roll=정상 추첨, rescue=구조 세트, dots=1×1, dead=살릴 수 없음")
    print("  ", dict(notes))

    days = defaultdict(set)
    for e in events:
        ts = e.get("ts")
        if ts:
            days[e.get("user_id")].add(datetime.fromtimestamp(ts / 1000).date())
    if days:
        last_day = max(d for ds in days.values() for d in ds)
        def retention(n):
            eligible = [u for u, ds in days.items() if (last_day - min(ds)).days >= n]
            back = [u for u in eligible if any((d - min(days[u])).days == n for d in days[u])]
            return f"{len(back)} / {len(eligible)} = {pct(len(back), len(eligible))}"
        print("\n[재방문]")
        print("  D1:", retention(1))
        print("  D7:", retention(7))


if __name__ == "__main__":
    main()
