const express = require('express');
const fs = require('fs').promises;
const path = require('path');

const router = express.Router();
const DB_FILE = path.join(__dirname, 'data', 'block_leaderboard.json');
const MAX_NICKNAME_LENGTH = 12;

function cleanTitle(raw) {
  return Array.from(String(raw || '').trim()).slice(0, MAX_NICKNAME_LENGTH).join('');
}

// Count by code point so the limit matches Godot's String.length()
function cleanNickname(raw) {
  return Array.from(String(raw || '').trim()).slice(0, MAX_NICKNAME_LENGTH).join('');
}

let mutationQueue = Promise.resolve();

function getIsoWeekKey(d = new Date()) {
  const date = new Date(Date.UTC(d.getFullYear(), d.getMonth(), d.getDate()));
  const dayNum = date.getUTCDay() || 7;
  date.setUTCDate(date.getUTCDate() + 4 - dayNum);
  const yearStart = new Date(Date.UTC(date.getUTCFullYear(), 0, 1));
  const weekNo = Math.ceil((((date - yearStart) / 86400000) + 1) / 7);
  return `${date.getUTCFullYear()}-W${String(weekNo).padStart(2, '0')}`;
}

// Daily challenge day in KST (UTC+9), matching the client's seed date
function kstDateKey(d = new Date()) {
  return new Date(d.getTime() + 9 * 3600 * 1000).toISOString().slice(0, 10);
}

// Accept today or yesterday so a game started just before midnight still counts
function acceptedDayKey(raw) {
  const key = String(raw || '');
  const today = kstDateKey();
  const yesterday = kstDateKey(new Date(Date.now() - 24 * 3600 * 1000));
  return (key === today || key === yesterday) ? key : null;
}

function pruneDaily(daily) {
  const keep = new Set([kstDateKey(), kstDateKey(new Date(Date.now() - 24 * 3600 * 1000))]);
  const out = {};
  for (const [k, v] of Object.entries(daily || {})) {
    if (keep.has(k)) out[k] = v;
  }
  return out;
}

const DEFAULT_SEED_USERS = {
  "bot_minseo": {
    user_id: "bot_minseo",
    nickname: "퍼즐마스터 민서",
    avatar_id: 5,
    best_score: 3420,
    weekly_score: 3420,
    weekly_key: getIsoWeekKey(),
    games_played: 45,
    updated_at: new Date(Date.now() - 3600000 * 2).toISOString(),
    is_bot: true
  },
  "bot_jenny": {
    user_id: "bot_jenny",
    nickname: "블록장인 Jenny",
    avatar_id: 2,
    best_score: 2890,
    weekly_score: 2890,
    weekly_key: getIsoWeekKey(),
    games_played: 38,
    updated_at: new Date(Date.now() - 3600000 * 5).toISOString(),
    is_bot: true
  },
  "bot_junho": {
    user_id: "bot_junho",
    nickname: "준호 (BlockPro)",
    avatar_id: 4,
    best_score: 2450,
    weekly_score: 2450,
    weekly_key: getIsoWeekKey(),
    games_played: 29,
    updated_at: new Date(Date.now() - 3600000 * 12).toISOString(),
    is_bot: true
  },
  "bot_alex": {
    user_id: "bot_alex",
    nickname: "Alex K.",
    avatar_id: 1,
    best_score: 1980,
    weekly_score: 1980,
    weekly_key: getIsoWeekKey(),
    games_played: 22,
    updated_at: new Date(Date.now() - 3600000 * 20).toISOString(),
    is_bot: true
  },
  "bot_sohee": {
    user_id: "bot_sohee",
    nickname: "소희",
    avatar_id: 6,
    best_score: 1620,
    weekly_score: 1620,
    weekly_key: getIsoWeekKey(),
    games_played: 18,
    updated_at: new Date(Date.now() - 3600000 * 30).toISOString(),
    is_bot: true
  },
  "bot_minwoo": {
    user_id: "bot_minwoo",
    nickname: "민우 (Minwoo)",
    avatar_id: 3,
    best_score: 1250,
    weekly_score: 1250,
    weekly_key: getIsoWeekKey(),
    games_played: 14,
    updated_at: new Date(Date.now() - 3600000 * 45).toISOString(),
    is_bot: true
  },
  "bot_neo": {
    user_id: "bot_neo",
    nickname: "네오 (Neo)",
    avatar_id: 7,
    best_score: 980,
    weekly_score: 980,
    weekly_key: getIsoWeekKey(),
    games_played: 11,
    updated_at: new Date(Date.now() - 3600000 * 60).toISOString(),
    is_bot: true
  },
  "bot_lucky": {
    user_id: "bot_lucky",
    nickname: "럭키블록",
    avatar_id: 8,
    best_score: 650,
    weekly_score: 650,
    weekly_key: getIsoWeekKey(),
    games_played: 7,
    updated_at: new Date(Date.now() - 3600000 * 80).toISOString(),
    is_bot: true
  }
};

async function initDb() {
  const dir = path.dirname(DB_FILE);
  try {
    await fs.mkdir(dir, { recursive: true });
  } catch (err) {
    if (err.code !== 'EEXIST') throw err;
  }

  try {
    await fs.access(DB_FILE);
  } catch (err) {
    const initialData = { users: DEFAULT_SEED_USERS };
    await fs.writeFile(DB_FILE, JSON.stringify(initialData, null, 2), 'utf8');
  }
}

async function readDbUnlocked() {
  await initDb();
  try {
    const raw = await fs.readFile(DB_FILE, 'utf8');
    const parsed = JSON.parse(raw);
    if (!parsed.users) parsed.users = { ...DEFAULT_SEED_USERS };
    return parsed;
  } catch (e) {
    return { users: { ...DEFAULT_SEED_USERS } };
  }
}

async function readDb() {
  await mutationQueue;
  return readDbUnlocked();
}

async function writeDb(data) {
  await initDb();
  await fs.writeFile(DB_FILE, JSON.stringify(data, null, 2), 'utf8');
}

function enqueueMutation(operation) {
  const result = mutationQueue.then(operation, operation);
  mutationQueue = result.catch(() => {});
  return result;
}

// GET /api/block-game/leaderboard
// Query: ?type=all|weekly & limit=30 & user_id=xxx
router.get('/leaderboard', async (req, res) => {
  try {
    const type = ['weekly', 'daily'].includes(req.query.type) ? req.query.type : 'all';
    const limit = Math.min(Math.max(parseInt(req.query.limit, 10) || 30, 1), 100);
    const userId = req.query.user_id ? String(req.query.user_id).trim() : null;
    const currentWeekKey = getIsoWeekKey();
    const dayKey = acceptedDayKey(req.query.day_key) || kstDateKey();

    const db = await readDb();
    const users = Object.values(db.users || {});

    // Compute effective score for each user
    const list = users.map(u => {
      let score = 0;
      if (type === 'weekly') {
        score = (u.weekly_key === currentWeekKey) ? (u.weekly_score || 0) : 0;
      } else if (type === 'daily') {
        score = (u.daily && u.daily[dayKey]) || 0;
      } else {
        score = u.best_score || 0;
      }
      return {
        user_id: u.user_id,
        nickname: u.nickname || '플레이어',
        avatar_id: parseInt(u.avatar_id, 10) || 1,
        title: u.title || '',
        score: score,
        updated_at: u.updated_at,
        is_me: Boolean(userId && u.user_id === userId)
      };
    }).filter(u => u.score > 0);

    // Sort descending by score, tie-break by earlier updated_at
    list.sort((a, b) => {
      if (b.score !== a.score) return b.score - a.score;
      return new Date(a.updated_at || 0) - new Date(b.updated_at || 0);
    });

    // Assign 1-based ranks
    let myRank = null;
    list.forEach((item, index) => {
      item.rank = index + 1;
      if (userId && item.user_id === userId) {
        myRank = {
          rank: item.rank,
          score: item.score,
          nickname: item.nickname,
          avatar_id: item.avatar_id,
          total_players: list.length
        };
      }
    });

    const topList = list.slice(0, limit);

    res.json({
      success: true,
      type,
      week_key: currentWeekKey,
      day_key: dayKey,
      total_players: list.length,
      leaderboard: topList,
      my_rank: myRank
    });
  } catch (err) {
    console.error('[Leaderboard] GET Error:', err);
    res.status(500).json({ success: false, error: '랭킹 조회 중 오류가 발생했습니다.' });
  }
});

// POST /api/block-game/score
// Body: { user_id, nickname, avatar_id, score, play_time, lines_cleared }
router.post('/score', async (req, res) => {
  try {
    const rawUserId = String(req.body.user_id || '').trim();
    if (!rawUserId || rawUserId.length < 3 || rawUserId.length > 64) {
      return res.status(400).json({ success: false, error: '유효한 user_id가 필요합니다.' });
    }

    const score = parseInt(req.body.score, 10);
    if (isNaN(score) || score < 0 || score > 2000000) {
      return res.status(400).json({ success: false, error: '점수가 유효하지 않습니다.' });
    }

    let nickname = cleanNickname(req.body.nickname);
    if (!nickname) nickname = '플레이어';

    const avatarId = parseInt(req.body.avatar_id, 10) || 0;
    const currentWeekKey = getIsoWeekKey();
    const nowIso = new Date().toISOString();

    const isDaily = req.body.mode === 'daily';
    const dayKey = isDaily ? acceptedDayKey(req.body.day_key) : null;
    if (isDaily && !dayKey) {
      return res.status(400).json({ success: false, error: '오늘 또는 어제의 챌린지만 등록할 수 있습니다.' });
    }

    const result = await enqueueMutation(async () => {
      const db = await readDbUnlocked();
      if (!db.users) db.users = {};

      const existing = db.users[rawUserId] || {
        user_id: rawUserId,
        nickname: nickname,
        avatar_id: avatarId > 0 ? avatarId : 1,
        best_score: 0,
        weekly_score: 0,
        weekly_key: currentWeekKey,
        games_played: 0,
        created_at: nowIso
      };

      if (req.body.title !== undefined) existing.title = cleanTitle(req.body.title);

      if (isDaily) {
        // Daily challenge scores are kept apart from all-time/weekly records
        existing.daily = pruneDaily(existing.daily);
        const isNewDailyBest = score > (existing.daily[dayKey] || 0);
        if (isNewDailyBest) existing.daily[dayKey] = score;
        existing.nickname = nickname;
        if (avatarId > 0) existing.avatar_id = avatarId;
        existing.games_played = (existing.games_played || 0) + 1;
        existing.updated_at = nowIso;
        db.users[rawUserId] = existing;
        await writeDb(db);

        const dailyUsers = Object.values(db.users).filter(u => u.daily && (u.daily[dayKey] || 0) > 0);
        dailyUsers.sort((a, b) => b.daily[dayKey] - a.daily[dayKey]);
        const dailyRank = dailyUsers.findIndex(u => u.user_id === rawUserId);
        return {
          mode: 'daily',
          day_key: dayKey,
          is_new_best: isNewDailyBest,
          best_score: existing.daily[dayKey] || 0,
          rank: dailyRank >= 0 ? dailyRank + 1 : dailyUsers.length,
          total_players: dailyUsers.length,
          avatar_id: existing.avatar_id
        };
      }

      const isNewBest = score > (existing.best_score || 0);
      const isNewWeeklyBest = (existing.weekly_key !== currentWeekKey) 
        ? score > 0 
        : score > (existing.weekly_score || 0);

      existing.nickname = nickname;
      if (avatarId > 0) {
        existing.avatar_id = avatarId;
      } else if (!existing.avatar_id) {
        existing.avatar_id = 1;
      }

      existing.games_played = (existing.games_played || 0) + 1;
      existing.updated_at = nowIso;

      if (isNewBest) {
        existing.best_score = score;
      }

      if (existing.weekly_key !== currentWeekKey) {
        existing.weekly_key = currentWeekKey;
        existing.weekly_score = score;
      } else if (isNewWeeklyBest) {
        existing.weekly_score = score;
      }

      db.users[rawUserId] = existing;
      await writeDb(db);

      // Compute rank immediately
      const allUsers = Object.values(db.users).filter(u => (u.best_score || 0) > 0);
      allUsers.sort((a, b) => (b.best_score || 0) - (a.best_score || 0));
      const rankIndex = allUsers.findIndex(u => u.user_id === rawUserId);

      return {
        is_new_best: isNewBest,
        is_new_weekly_best: isNewWeeklyBest,
        best_score: existing.best_score,
        weekly_score: existing.weekly_score,
        rank: rankIndex >= 0 ? rankIndex + 1 : allUsers.length,
        total_players: allUsers.length,
        avatar_id: existing.avatar_id
      };
    });

    res.json({
      success: true,
      ...result
    });
  } catch (err) {
    console.error('[Leaderboard] POST Score Error:', err);
    res.status(500).json({ success: false, error: '점수 등록 중 오류가 발생했습니다.' });
  }
});

// POST /api/block-game/profile
// Body: { user_id, nickname, avatar_id }
router.post('/profile', async (req, res) => {
  try {
    const rawUserId = String(req.body.user_id || '').trim();
    let nickname = cleanNickname(req.body.nickname);
    const avatarId = parseInt(req.body.avatar_id, 10) || 1;

    if (!rawUserId) {
      return res.status(400).json({ success: false, error: 'user_id가 필요합니다.' });
    }
    if (!nickname) nickname = '블록러';

    const nowIso = new Date().toISOString();
    await enqueueMutation(async () => {
      const db = await readDbUnlocked();
      if (!db.users) db.users = {};
      const existing = db.users[rawUserId] || {
        user_id: rawUserId,
        nickname: nickname,
        avatar_id: avatarId,
        best_score: 0,
        weekly_score: 0,
        weekly_key: getIsoWeekKey(),
        games_played: 0,
        created_at: nowIso
      };
      existing.nickname = nickname;
      existing.avatar_id = avatarId;
      if (req.body.title !== undefined) existing.title = cleanTitle(req.body.title);
      existing.updated_at = nowIso;
      db.users[rawUserId] = existing;
      await writeDb(db);
    });

    res.json({ success: true, nickname, avatar_id: avatarId });
  } catch (err) {
    console.error('[Leaderboard] POST Profile Error:', err);
    res.status(500).json({ success: false, error: '프로필 저장 중 오류가 발생했습니다.' });
  }
});

// POST /api/block-game/nickname
// Body: { user_id, nickname, avatar_id }
router.post('/nickname', async (req, res) => {
  try {
    const rawUserId = String(req.body.user_id || '').trim();
    const nickname = cleanNickname(req.body.nickname);
    const avatarId = parseInt(req.body.avatar_id, 10) || 0;

    if (!rawUserId || !nickname) {
      return res.status(400).json({ success: false, error: 'user_id와 nickname이 필요합니다.' });
    }

    await enqueueMutation(async () => {
      const db = await readDbUnlocked();
      if (!db.users) db.users = {};
      if (db.users[rawUserId]) {
        db.users[rawUserId].nickname = nickname;
        if (avatarId > 0) db.users[rawUserId].avatar_id = avatarId;
        db.users[rawUserId].updated_at = new Date().toISOString();
        await writeDb(db);
      }
    });

    res.json({ success: true, nickname, avatar_id: avatarId });
  } catch (err) {
    console.error('[Leaderboard] POST Nickname Error:', err);
    res.status(500).json({ success: false, error: '닉네임 변경 중 오류가 발생했습니다.' });
  }
});

// POST /api/block-game/events
// Body: { user_id, session_id, events: [{ event, ts, ...fields }] }
// Appends one JSON line per event to data/events/YYYY-MM-DD.jsonl (server local date)
const EVENTS_DIR = path.join(__dirname, 'data', 'events');
const MAX_EVENTS_PER_BATCH = 200;
const EVENT_NAME_RE = /^[a-z_]{1,32}$/;
let eventWriteQueue = Promise.resolve();

function localDateKey(d = new Date()) {
  const pad = (n) => String(n).padStart(2, '0');
  return `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())}`;
}

router.post('/events', async (req, res) => {
  try {
    const userId = String(req.body.user_id || '').trim();
    const sessionId = String(req.body.session_id || '').trim().slice(0, 64);
    const events = Array.isArray(req.body.events) ? req.body.events : null;

    if (!userId || userId.length > 64) {
      return res.status(400).json({ success: false, error: '유효한 user_id가 필요합니다.' });
    }
    if (!events || events.length === 0 || events.length > MAX_EVENTS_PER_BATCH) {
      return res.status(400).json({ success: false, error: `events는 1~${MAX_EVENTS_PER_BATCH}개여야 합니다.` });
    }

    const receivedAt = new Date().toISOString();
    const lines = [];
    for (const ev of events) {
      if (!ev || typeof ev !== 'object' || !EVENT_NAME_RE.test(String(ev.event || ''))) continue;
      const line = JSON.stringify({ received_at: receivedAt, user_id: userId, session_id: sessionId, ...ev });
      if (line.length > 4000) continue;
      lines.push(line);
    }

    if (lines.length > 0) {
      const file = path.join(EVENTS_DIR, `${localDateKey()}.jsonl`);
      const write = eventWriteQueue.then(async () => {
        await fs.mkdir(EVENTS_DIR, { recursive: true });
        await fs.appendFile(file, lines.join('\n') + '\n', 'utf8');
      });
      eventWriteQueue = write.catch(() => {});
      await write;
    }

    res.json({ success: true, accepted: lines.length });
  } catch (err) {
    console.error('[Leaderboard] POST Events Error:', err);
    res.status(500).json({ success: false, error: '이벤트 저장 중 오류가 발생했습니다.' });
  }
});

module.exports = router;
