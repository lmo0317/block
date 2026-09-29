// Local dev server: mounts the leaderboard router the way the 112 server does, and can serve a
// Web build. Used by tests/test_autoplay.tscn and tests/test_achievements.tscn.
//
//   npm install express            (once, in any folder on NODE_PATH or next to this file)
//   node tools/dev_server.js [web_build_dir]
//
// Data is written to tools/data/ (git-ignored).
const path = require('path');
const express = require('express');

const app = express();
app.use(express.json({ limit: '1mb' }));
app.use('/api/block-game', require('./server_block_leaderboard.js'));
if (process.argv[2]) {
  app.use('/block-game', express.static(path.resolve(process.argv[2])));
}
app.listen(3000, '127.0.0.1', () => console.log('BlockTris dev server on http://127.0.0.1:3000'));
