"""Synthesizes the game's sound effects into assets/sfx/ (copied from PuzzleBlock's generator).

Every file peaks at PEAK_DB so sounds can overlap without clipping; no pitch shifting at runtime.

  click     soft tick for buttons
  place     wooden knock for roads, lots and facilities
  build     small pop when a building finishes
  coin      tiny bright ding when a citizen shops
  bulldoze  crunchy noise thump
  invalid   low double buzz
  rankup    fanfare chord
  notice    two-note chime for events
  yearend   gentle three-note bell

Usage: python tools/generate_sfx.py
"""
import math
import os
import random
import struct
import wave

RATE = 44100
PEAK_DB = -6.0
OUT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "assets", "sfx"))

random.seed(7)


def note(name):
    """'C5' -> Hz (A4 = 440)."""
    names = {"C": -9, "D": -7, "E": -5, "F": -4, "G": -2, "A": 0, "B": 2}
    return 440.0 * 2 ** ((names[name[0]] + 12 * (int(name[-1]) - 4)) / 12)


def silence(sec):
    return [0.0] * int(RATE * sec)


def mix(dst, src, at=0.0, gain=1.0):
    start = int(at * RATE)
    if len(dst) < start + len(src):
        dst.extend([0.0] * (start + len(src) - len(dst)))
    for i, v in enumerate(src):
        dst[start + i] += v * gain
    return dst


def mallet(freq, dur=0.5, bright=0.35):
    """Marimba-like note: soft attack, the upper partials die out faster than the fundamental."""
    n = int(RATE * dur)
    out = []
    for i in range(n):
        t = i / RATE
        attack = min(1.0, t / 0.004)
        v = math.sin(2 * math.pi * freq * t) * math.exp(-t * 6.0)
        v += bright * math.sin(2 * math.pi * freq * 4.0 * t) * math.exp(-t * 28.0)
        v += 0.18 * math.sin(2 * math.pi * freq * 2.0 * t) * math.exp(-t * 14.0)
        out.append(v * attack)
    return out


def bell(freq, dur=0.9):
    """Glassy bell for sparkle: inharmonic partials with long, gentle decay."""
    n = int(RATE * dur)
    out = []
    for i in range(n):
        t = i / RATE
        attack = min(1.0, t / 0.002)
        v = (math.sin(2 * math.pi * freq * t) * math.exp(-t * 4.0)
             + 0.4 * math.sin(2 * math.pi * freq * 2.76 * t) * math.exp(-t * 7.0)
             + 0.2 * math.sin(2 * math.pi * freq * 5.4 * t) * math.exp(-t * 12.0))
        out.append(v * attack)
    return out


def pop(dur=0.12):
    """Soft 'pop' for a clearing line: a short low thump plus a quick filtered noise puff."""
    n = int(RATE * dur)
    out = []
    lp = 0.0
    for i in range(n):
        t = i / RATE
        thump = math.sin(2 * math.pi * (180 - 900 * t) * t) * math.exp(-t * 40)
        lp += (random.uniform(-1, 1) - lp) * 0.25
        out.append(0.8 * thump + 0.5 * lp * math.exp(-t * 55))
    return out


def riser(dur=0.55):
    """Rising whoosh: noise through a sweeping resonant filter, getting louder."""
    n = int(RATE * dur)
    out = []
    low = band = 0.0
    for i in range(n):
        p = i / n
        f = 300 + 3200 * p * p
        k = 2 * math.sin(math.pi * f / RATE)
        x = random.uniform(-1, 1)
        low += k * band
        high = x - low - 0.35 * band
        band += k * high
        tone = 0.35 * math.sin(2 * math.pi * (220 + 660 * p) * (i / RATE))
        out.append((0.6 * band + tone) * (p ** 1.6))
    return out


def reverb(x, mix_amount=0.28, room=0.78):
    """Small Schroeder reverb (4 combs + 2 allpasses) for a soft tail."""
    tail = int(RATE * 0.35)
    x = x + [0.0] * tail
    combs = [1557, 1617, 1491, 1422]
    wet = [0.0] * len(x)
    for d in combs:
        buf = [0.0] * d
        idx = 0
        for i, v in enumerate(x):
            y = buf[idx]
            buf[idx] = v + y * room
            idx = (idx + 1) % d
            wet[i] += y * 0.25
    for d, g in ((225, 0.5), (556, 0.5)):
        buf = [0.0] * d
        idx = 0
        for i, v in enumerate(wet):
            y = buf[idx]
            out = -v + y
            buf[idx] = v + y * g
            idx = (idx + 1) % d
            wet[i] = out
    return [(1 - mix_amount) * a + mix_amount * b for a, b in zip(x, wet)]


def fade_tail(x, sec=0.05):
    n = min(len(x), int(RATE * sec))
    for i in range(n):
        x[len(x) - n + i] *= 1 - i / n
    return x


def write(name, x, peak_db=PEAK_DB):
    x = fade_tail(x)
    peak = max(abs(v) for v in x) or 1.0
    scale = (10 ** (peak_db / 20)) / peak
    path = os.path.join(OUT, name + ".wav")
    with wave.open(path, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(RATE)
        w.writeframes(b"".join(struct.pack("<h", int(max(-1, min(1, v * scale)) * 32767)) for v in x))
    print(f"{name}.wav  {len(x) / RATE:.2f}s")


def noise_burst(dur, decay, smooth=0.3):
    n = int(RATE * dur)
    out = []
    lp = 0.0
    for i in range(n):
        t = i / RATE
        lp += (random.uniform(-1, 1) - lp) * smooth
        out.append(lp * math.exp(-t * decay))
    return out


def main():
    os.makedirs(OUT, exist_ok=True)
    x = mallet(note("A5"), 0.08, 0.2)
    write("click", x, PEAK_DB - 4)

    x = pop(0.1)
    mix(x, mallet(note("D4"), 0.18, 0.1), gain=0.6)
    write("place", x)

    x = pop(0.14)
    mix(x, mallet(note("G5"), 0.25, 0.25), at=0.02, gain=0.5)
    write("build", reverb(x, 0.15))

    x = bell(note("E6"), 0.25)
    mix(x, bell(note("B6"), 0.2), at=0.05, gain=0.6)
    write("coin", x)

    x = noise_burst(0.35, 12, 0.4)
    mix(x, [math.sin(2 * math.pi * (90 - 60 * (i / RATE)) * (i / RATE)) * math.exp(-(i / RATE) * 14) for i in range(int(RATE * 0.3))], gain=0.8)
    write("bulldoze", x)

    x = []
    for k in range(2):
        tone = [0.6 * (1 if math.sin(2 * math.pi * 140 * (i / RATE)) > 0 else -1) * math.exp(-(i / RATE) * 18) for i in range(int(RATE * 0.12))]
        mix(x, tone, at=0.13 * k)
    write("invalid", x, PEAK_DB - 3)


    x = []
    for k, name in enumerate(["G4", "C5", "E5"]):
        mix(x, mallet(note(name), 0.3, 0.3), at=0.11 * k, gain=0.6)
    for name in ["C5", "E5", "G5", "C6"]:
        mix(x, mallet(note(name), 1.0, 0.35), at=0.36, gain=0.45)
    mix(x, bell(note("G6"), 1.0), at=0.4, gain=0.25)
    write("rankup", reverb(x, 0.3), PEAK_DB + 1.0)

    x = bell(note("A5"), 0.6)
    mix(x, bell(note("E6"), 0.7), at=0.14, gain=0.8)
    write("notice", reverb(x, 0.25), PEAK_DB - 2)

    x = []
    for k, name in enumerate(["E5", "G5", "C6"]):
        mix(x, bell(note(name), 0.9), at=0.16 * k, gain=0.6)
    write("yearend", reverb(x, 0.3))


if __name__ == "__main__":
    main()
