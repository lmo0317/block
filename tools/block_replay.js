'use strict';
// Server-side replay check for submitted scores (see docs/SCORING_RULES.md).
// - GodotRng / godotStringHash: ports of Godot's RandomPCG and String::hash() so the daily
//   challenge sequence can be regenerated exactly (verified against tools/block_rules.json samples)
// - replay(): re-applies a play log and recomputes the score with the exported scoring rules

const MASK64 = (1n << 64n) - 1n;
const PCG_MULT = 6364136223846793005n;
const PCG_DEFAULT_INC = 1442695040888963407n;

class GodotRng {
  constructor(seed) {
    this.setSeed(seed);
  }

  // pcg32_srandom_r(state, seed, DEFAULT_INC)
  setSeed(seed) {
    this.inc = ((PCG_DEFAULT_INC << 1n) | 1n) & MASK64;
    this.state = 0n;
    this.next();
    this.state = (this.state + (BigInt(seed) & MASK64)) & MASK64;
    this.next();
  }

  // pcg32_random_r
  next() {
    const old = this.state;
    this.state = (old * PCG_MULT + this.inc) & MASK64;
    const xorshifted = Number((((old >> 18n) ^ old) >> 27n) & 0xffffffffn);
    const rot = Number(old >> 59n);
    return ((xorshifted >>> rot) | (xorshifted << ((32 - rot) & 31))) >>> 0;
  }

  randi() {
    return this.next();
  }

  // pcg32_boundedrand_r
  bounded(bound) {
    const threshold = ((0x100000000 - bound) >>> 0) % bound;
    for (;;) {
      const r = this.next();
      if (r >= threshold) return r % bound;
    }
  }

  randiRange(from, to) {
    if (from === to) return from;
    const min = Math.min(from, to);
    const max = Math.max(from, to);
    return this.bounded(max - min + 1) + min;
  }

  // RandomPCG::randf(): float32 significand scaled by the leading zeros of a first draw
  randf() {
    const proto = this.next();
    if (proto === 0) return 0;
    const significand = Math.fround((this.next() | 0x80000001) >>> 0);
    return significand * Math.pow(2, -32 - Math.clz32(proto));
  }
}

// String::hash(): djb2 over code points, wrapped to uint32
function godotStringHash(text) {
  let h = 5381;
  for (const ch of text) {
    h = (Math.imul(h, 33) + ch.codePointAt(0)) >>> 0;
  }
  return h;
}

function makeRules(raw) {
  const shapes = new Map();
  for (const s of raw.shapes) {
    const xs = s.cells.map(c => c[0]);
    const ys = s.cells.map(c => c[1]);
    const minX = Math.min(...xs);
    const minY = Math.min(...ys);
    shapes.set(s.id, {
      id: s.id,
      category: s.category,
      offsets: s.cells.map(c => [c[0] - minX, c[1] - minY]),
      width: Math.max(...xs) - minX + 1,
      height: Math.max(...ys) - minY + 1
    });
  }
  return { raw, shapes, n: raw.grid_size };
}

// Port of BlockData.get_seeded_trio()
function seededTrio(rng, rules) {
  const weights = rules.raw.base_weights;
  const pool = rules.raw.shapes.filter(s => s.id !== 'dot_1x1');
  const smallPool = pool.filter(s => s.category !== 'large');
  const pick = (candidates) => {
    let total = 0;
    for (const s of candidates) total += (weights[s.id] ?? 1.0);
    if (total <= 0) return candidates[rng.randi() % candidates.length];
    const roll = rng.randf() * total;
    let accum = 0;
    for (const s of candidates) {
      accum += (weights[s.id] ?? 1.0);
      if (roll <= accum) return s;
    }
    return candidates[candidates.length - 1];
  };
  const trio = [];
  let hasLarge = false;
  for (let i = 0; i < 3; i++) {
    const piece = pick(hasLarge ? smallPool : pool);
    if (piece.category === 'large') hasLarge = true;
    trio.push(piece.id);
  }
  for (let i = trio.length - 1; i > 0; i--) {
    const j = rng.randiRange(0, i);
    [trio[i], trio[j]] = [trio[j], trio[i]];
  }
  return trio;
}

function dailyGenerator(rules, dayKey) {
  const rng = new GodotRng(godotStringHash(rules.raw.daily_seed_prefix + dayKey));
  return () => seededTrio(rng, rules);
}

function fits(grid, n, shape, x, y) {
  if (!Number.isInteger(x) || !Number.isInteger(y)) return false;
  if (x < 0 || y < 0 || x + shape.width > n || y + shape.height > n) return false;
  return shape.offsets.every(([ox, oy]) => grid[(x + ox) + (y + oy) * n] === 0);
}

function fitsAnywhere(grid, n, shape) {
  for (let y = 0; y + shape.height <= n; y++) {
    for (let x = 0; x + shape.width <= n; x++) {
      if (fits(grid, n, shape, x, y)) return true;
    }
  }
  return false;
}

const MAX_LOG_ENTRIES = 20000;

// Replays a play log and returns { ok, score, moves } or { ok: false, reason }.
// options.nextDailyTrio: when set, every deal must equal the regenerated daily trio.
function replay(log, rules, options = {}) {
  if (!Array.isArray(log) || log.length === 0 || log.length > MAX_LOG_ENTRIES) {
    return { ok: false, reason: 'log size' };
  }
  const sc = rules.raw.scoring;
  const n = rules.n;
  const grid = new Array(n * n).fill(0);
  let tray = [];
  let score = 0;
  let combo = 0;
  let grace = 0;
  let revived = false;
  let moves = 0;

  for (let i = 0; i < log.length; i++) {
    const e = log[i];
    // Longest entries are cell lists (start pattern, revive): at most one per board cell
    if (!Array.isArray(e) || e.length === 0 || e.length > 1 + n * n) return { ok: false, reason: `bad entry ${i}` };
    const kind = e[0];

    if (kind === 's') {
      // Classic start pattern: only as the first entry, only outside the daily challenge
      if (i !== 0 || options.nextDailyTrio) return { ok: false, reason: `start pattern not allowed at ${i}` };
      const cells = e.slice(1);
      const maxCells = rules.raw.start_max_cells || 0;
      if (cells.length === 0 || cells.length > maxCells || new Set(cells).size !== cells.length) {
        return { ok: false, reason: 'bad start pattern size' };
      }
      for (const idx of cells) {
        if (!Number.isInteger(idx) || idx < 0 || idx >= n * n) return { ok: false, reason: 'bad start pattern cell' };
        grid[idx] = 1;
      }
      for (let k = 0; k < n; k++) {
        const rowFull = grid.slice(k * n, k * n + n).every(v => v === 1);
        const colFull = [...Array(n).keys()].every(r => grid[k + r * n] === 1);
        if (rowFull || colFull) return { ok: false, reason: 'start pattern has a full line' };
      }
      continue;
    }

    if (kind === 'd') {
      if (tray.some(t => !t.used)) return { ok: false, reason: `deal before tray empty at ${i}` };
      const ids = e.slice(1);
      if (ids.length !== 3 || !ids.every(id => rules.shapes.has(id))) return { ok: false, reason: `bad deal at ${i}` };
      if (options.nextDailyTrio) {
        const expected = options.nextDailyTrio();
        if (expected.join(',') !== ids.join(',')) return { ok: false, reason: `deal does not match daily sequence at ${i}` };
      }
      tray = ids.map(id => ({ id, used: false }));
    } else if (kind === 'p') {
      const [, id, x, y] = e;
      const slot = tray.find(t => !t.used && t.id === id);
      if (!slot) return { ok: false, reason: `piece not in tray at ${i}` };
      const shape = rules.shapes.get(id);
      if (!fits(grid, n, shape, x, y)) return { ok: false, reason: `illegal placement at ${i}` };
      slot.used = true;
      moves++;
      const touchedRows = new Set();
      const touchedCols = new Set();
      for (const [ox, oy] of shape.offsets) {
        grid[(x + ox) + (y + oy) * n] = 1;
        touchedRows.add(y + oy);
        touchedCols.add(x + ox);
      }
      score += shape.offsets.length;

      const fullRows = [...touchedRows].filter(r => grid.slice(r * n, r * n + n).every(v => v === 1));
      const fullCols = [...touchedCols].filter(c => [...Array(n).keys()].every(r => grid[c + r * n] === 1));
      for (const r of fullRows) for (let c = 0; c < n; c++) grid[c + r * n] = 0;
      for (const c of fullCols) for (let r = 0; r < n; r++) grid[c + r * n] = 0;
      const lines = fullRows.length + fullCols.length;

      if (lines > 0) {
        combo += 1;
        grace = sc.combo_grace;
        const mult = 1.0 + sc.combo_alpha * combo;
        let lineGain = Math.trunc(sc.line_base * lines * lines * mult)
          + Math.trunc(sc.combo_bonus_linear * combo + sc.combo_bonus_quadratic * combo * combo);
        // Combo fever: line clear points multiplied from fever_combo on
        if (sc.fever_combo && combo >= sc.fever_combo) {
          lineGain = Math.trunc(lineGain * sc.fever_multiplier);
        }
        score += lineGain;
        if (grid.every(v => v === 0)) {
          score += Math.round(sc.perfect_base * (1.0 + sc.combo_alpha * combo));
        }
      } else if (combo > 0) {
        grace -= 1;
        if (grace <= 0) combo = 0;
      }
    } else if (kind === 'r') {
      if (revived) return { ok: false, reason: `second revive at ${i}` };
      const open = tray.filter(t => !t.used);
      if (open.length === 0 || open.some(t => fitsAnywhere(grid, n, rules.shapes.get(t.id)))) {
        return { ok: false, reason: `revive while a move was possible at ${i}` };
      }
      const cells = e.slice(1);
      if (cells.length > rules.raw.revive_max_cells) return { ok: false, reason: `revive too large at ${i}` };
      for (const idx of cells) {
        if (!Number.isInteger(idx) || idx < 0 || idx >= n * n || grid[idx] !== 1) return { ok: false, reason: `bad revive cell at ${i}` };
        grid[idx] = 0;
      }
      revived = true;
      tray = [];
    } else {
      return { ok: false, reason: `unknown entry at ${i}` };
    }
  }
  return { ok: true, score, moves };
}

module.exports = { GodotRng, godotStringHash, makeRules, seededTrio, dailyGenerator, replay };
