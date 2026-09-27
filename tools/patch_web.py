import os
import re

WEB_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "build", "web"))
js_path = os.path.join(WEB_DIR, "index.js")
html_path = os.path.join(WEB_DIR, "index.html")

print("Patching index.js...")
with open(js_path, "r", encoding="utf-8") as f:
    s = f.read()

s1 = 'GodotAudio.audioPositionWorkletPromise=ctx.audioWorklet.addModule(path);'
r1 = 'GodotAudio.audioPositionWorkletPromise=ctx.audioWorklet?ctx.audioWorklet.addModule(path):Promise.resolve();'

s2 = 'async connectPositionWorklet(start){await GodotAudio.audioPositionWorkletPromise;if(this.isCanceled){return}this._source.connect(this.getPositionWorklet());if(start){this.start()}}'
r2 = 'async connectPositionWorklet(start){if(GodotAudio.audioPositionWorkletPromise){await GodotAudio.audioPositionWorkletPromise;}if(this.isCanceled){return}if(GodotAudio.ctx&&GodotAudio.ctx.audioWorklet&&typeof AudioWorkletNode!=="undefined"){this._source.connect(this.getPositionWorklet());}if(start){this.start()}}'

if s1 in s:
    s = s.replace(s1, r1, 1)
    print("Patched audioPositionWorkletPromise in index.js")

if s2 in s:
    s = s.replace(s2, r2, 1)
    print("Patched connectPositionWorklet in index.js")

with open(js_path, "w", encoding="utf-8") as f:
    f.write(s)

print("Patching index.html...")
with open(html_path, "r", encoding="utf-8") as f:
    html = f.read()

# Filter out secure context requirement if threads are disabled
old_missing = '''\tconst missing = Engine.getMissingFeatures({
\t\tthreads: GODOT_THREADS_ENABLED,
\t});'''

new_missing = '''\tconst missing = Engine.getMissingFeatures({
\t\tthreads: GODOT_THREADS_ENABLED,
\t}).filter(function(item) {
\t\treturn !item.toLowerCase().includes('secure context');
\t});'''

if old_missing in html:
    html = html.replace(old_missing, new_missing, 1)
    print("Patched secure context check in index.html")

# Set Page Title and Favicon
html = html.replace("<title>index</title>", "<title>블록 블라스트 (Block Blast!)</title>")
html = html.replace("<title></title>", "<title>블록 블라스트 (Block Blast!)</title>")

# Responsive Canvas viewport styling and black background
custom_css = """
<style>
  html, body {
    margin: 0;
    padding: 0;
    background-color: #0b0f19;
    color: #e2e8f0;
    overflow: hidden;
    touch-action: none;
    -webkit-touch-callout: none;
    -webkit-user-select: none;
    user-select: none;
    width: 100%;
    height: 100%;
  }
  #canvas {
    display: block;
    margin: 0 auto;
    width: 100%;
    height: 100%;
    max-width: 600px;
    object-fit: contain;
  }
</style>
"""

if "</head>" in html:
    html = html.replace("</head>", custom_css + "\n</head>")

with open(html_path, "w", encoding="utf-8") as f:
    f.write(html)

print("Patching finished successfully!")
