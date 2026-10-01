// Apps in Toss SDK for the Godot game (scripts/toss.gd), as a small callback API on
// window.TossBridge. Every call is guarded so an old Toss app or a missing feature
// never breaks the game: callbacks then get null.
import {
  closeView,
  generateHapticFeedback,
  getGameCenterGameProfile,
  getUserKeyForGame,
  graniteEvent,
  openGameCenterLeaderboard,
  submitGameCenterLeaderBoardScore,
} from '@apps-in-toss/web-framework';

function settle(call, cb, pick) {
  Promise.resolve()
    .then(call)
    .then((r) => cb(pick(r)), () => cb(null));
}

function quietly(call) {
  Promise.resolve().then(call).catch(() => {});
}

// isSupported() throws outside the Toss app (no host constants), so treat that as unsupported
function supported(fn) {
  try {
    return fn.isSupported();
  } catch (e) {
    return false;
  }
}

// Answer after the game's call has returned: calling back into the engine in the middle of
// its own call into JavaScript is not safe
function later(cb, value) {
  setTimeout(() => cb(value), 0);
}

function reason(e) {
  const text = e && (e.message || e.code) ? e.message || e.code : String(e);
  console.warn('[TossBridge]', text);
  return 'ERROR: ' + text;
}

window.TossBridge = {
  // Game-specific anonymous user key (same player, same game -> same hash)
  userKey(cb) {
    settle(getUserKeyForGame, cb, (r) => (r && r.type === 'HASH' ? r.hash : null));
  },
  // Nickname of the player's Toss game profile, if they have one
  nickname(cb) {
    settle(getGameCenterGameProfile, cb, (r) => (r && r.statusCode === 'SUCCESS' ? r.nickname : null));
  },
  // score: number as a string; cb gets the statusCode ("SUCCESS", "LEADERBOARD_NOT_FOUND", ...),
  // "UNSUPPORTED_APP_VERSION" on an old Toss app, or "ERROR: <message>" when the call fails
  submitScore(score, cb) {
    if (!supported(submitGameCenterLeaderBoardScore)) {
      later(cb, 'UNSUPPORTED_APP_VERSION');
      return;
    }
    Promise.resolve()
      .then(() => submitGameCenterLeaderBoardScore({ score: String(score) }))
      .then((r) => cb(r ? r.statusCode : 'UNSUPPORTED_APP_VERSION'), (e) => cb(reason(e)));
  },
  // cb gets "OK", "UNSUPPORTED_APP_VERSION" or "ERROR: <message>" (e.g. before the app info is approved)
  openLeaderboard(cb) {
    const done = typeof cb === 'function' ? cb : () => {};
    if (!supported(openGameCenterLeaderboard)) {
      later(done, 'UNSUPPORTED_APP_VERSION');
      return;
    }
    Promise.resolve().then(openGameCenterLeaderboard).then(() => done('OK'), (e) => done(reason(e)));
  },
  // tickWeak | tap | tickMedium | softMedium | basicWeak | basicMedium | success | error | wiggle | confetti
  haptic(type) {
    quietly(() => generateHapticFeedback({ type }));
  },
  // Subscribing takes over the Android back button: the game must confirm and call close()
  onBack(cb) {
    try {
      graniteEvent.addEventListener('backEvent', { onEvent: () => cb(true), onError: () => {} });
    } catch (e) {
      // Not inside the Toss app
    }
  },
  close() {
    quietly(closeView);
  },
};
