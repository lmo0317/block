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

window.TossBridge = {
  // Game-specific anonymous user key (same player, same game -> same hash)
  userKey(cb) {
    settle(getUserKeyForGame, cb, (r) => (r && r.type === 'HASH' ? r.hash : null));
  },
  // Nickname of the player's Toss game profile, if they have one
  nickname(cb) {
    settle(getGameCenterGameProfile, cb, (r) => (r && r.statusCode === 'SUCCESS' ? r.nickname : null));
  },
  // score: number as a string; cb gets the statusCode ("SUCCESS", "LEADERBOARD_NOT_FOUND", ...)
  submitScore(score, cb) {
    settle(() => submitGameCenterLeaderBoardScore({ score: String(score) }), cb, (r) => (r ? r.statusCode : 'UNSUPPORTED'));
  },
  openLeaderboard() {
    quietly(openGameCenterLeaderboard);
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
