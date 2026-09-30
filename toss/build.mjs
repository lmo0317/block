// Wraps the Godot "Toss" export (../build/toss) into dist/ for `ait build`:
// copies the game files, bundles src/bridge.js (the Apps in Toss SDK) into ait-bridge.js
// and loads it before the engine script.
import { build } from 'esbuild';
import { cpSync, existsSync, readFileSync, rmSync, writeFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const here = dirname(fileURLToPath(import.meta.url));
const game = join(here, '..', 'build', 'toss');
const dist = join(here, 'dist');

if (!existsSync(join(game, 'index.html'))) {
  console.error(`No Godot export at ${game}. Export the "Toss" preset and run tools/patch_web.py build/toss first.`);
  process.exit(1);
}

rmSync(dist, { recursive: true, force: true });
cpSync(game, dist, {
  recursive: true,
  filter: (src) => !src.endsWith('.import'),
});

await build({
  entryPoints: [join(here, 'src', 'bridge.js')],
  bundle: true,
  format: 'iife',
  minify: true,
  target: 'es2019',
  outfile: join(dist, 'ait-bridge.js'),
});

const htmlPath = join(dist, 'index.html');
let html = readFileSync(htmlPath, 'utf8');
const engineTag = '<script src="index.js"></script>';
if (!html.includes(engineTag)) {
  console.error('Could not find the engine script tag in index.html');
  process.exit(1);
}
html = html.replace(engineTag, `<script src="ait-bridge.js"></script>\n\t\t${engineTag}`);
writeFileSync(htmlPath, html);
console.log('dist/ ready:', dist);
