"""Deploys the web build to the 112 server and adds the game card to the hub page.
(Adapted from PuzzleBlock's deploy script.)

  1. backs up the current game folder and hub.html on the server
  2. uploads build/web to public/mini-city
  3. adds a "도트 미니 시티" card, CSS and footer link to hub.html (once)
  4. checks the URLs answer and the uploaded files match the local build

Usage: bash tools/build_web.sh && python tools/deploy_112.py
"""
import hashlib
import os
import subprocess
import sys
import tarfile
import tempfile
import time

SERVER = "local-ai-server"
REMOTE_PUBLIC = "/home/lmo0317/apps/planner/public"
ROUTE = "mini-city"
REMOTE_GAME_DIR = f"{REMOTE_PUBLIC}/{ROUTE}"
REMOTE_HUB = f"{REMOTE_PUBLIC}/hub.html"
LOCAL_BUILD_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "build", "web"))

CSS_ANCHOR = ".service-card.blockblast .card-route { color: #38bdf8; }"
CSS = """
    .service-card.minicity::before { background: linear-gradient(90deg, #22c55e, #facc15, #f97316); }
    .service-card.minicity .card-icon-wrap { background: rgba(34, 197, 94, 0.15); border: 1px solid rgba(34, 197, 94, 0.35); color: #4ade80; }
    .service-card.minicity .card-route { color: #86efac; }"""

CARD_ANCHOR = "<!-- 6. FaceMatch AI -->"
CARD = """<!-- 8. 도트 미니 시티 -->
        <a href="/mini-city/" class="service-card minicity">
          <div class="card-top">
            <div class="card-icon-wrap">
              <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                <path d="M3 21h18"/>
                <path d="M5 21V10l4-3v14"/>
                <path d="M9 21V4h6v17"/>
                <path d="M15 21v-8h4v8"/>
              </svg>
            </div>
            <span class="card-status-badge active" id="badge-minicity"><span class="mini-dot"></span> 첫 플레이 버전 (Godot 4 Web)</span>
          </div>
          <div class="card-title-group">
            <h2>도트 미니 시티 (가칭)</h2>
            <span class="card-route">/mini-city</span>
          </div>
          <p class="card-desc">도로를 깔고 구역을 칠하면 도시가 스스로 자라는 도트 도시 건설 게임. 콤보를 모으고 마을 랭크를 올려 10년 뒤 도시 점수를 겨뤄요!</p>
          <div class="tag-row">
            <span class="tag">#도시건설</span>
            <span class="tag">#도트</span>
            <span class="tag">#콤보</span>
            <span class="tag">#Godot4Web</span>
          </div>
          <div class="card-cta">
            <span>게임 플레이하기</span>
            <svg viewBox="0 0 24 24"><line x1="5" y1="12" x2="19" y2="12"/><polyline points="12 5 19 12 12 19"/></svg>
          </div>
        </a>

        """

FOOTER_ANCHOR = '<a href="/facematching/">얼굴 유사도(FaceMatch)</a>'
FOOTER = '\n        <a href="/mini-city/">도트 미니 시티</a>'


def ssh(cmd, check=True):
    print(f"[SSH] {cmd}")
    res = subprocess.run(["ssh", SERVER, cmd], capture_output=True, text=True, encoding="utf-8")
    if check and res.returncode != 0:
        print(res.stderr)
        sys.exit(f"remote command failed: {cmd}")
    return res.stdout


def md5(path):
    h = hashlib.md5()
    with open(path, "rb") as f:
        for chunk in iter(lambda: f.read(1 << 20), b""):
            h.update(chunk)
    return h.hexdigest()


def main():
    if not os.path.exists(os.path.join(LOCAL_BUILD_DIR, "index.html")):
        sys.exit(f"{LOCAL_BUILD_DIR}/index.html is missing; run tools/build_web.sh first")
    stamp = time.strftime("%Y%m%d-%H%M%S")

    print("=== 1. Backups ===")
    ssh(f"if [ -d {REMOTE_GAME_DIR} ]; then cp -a {REMOTE_GAME_DIR} {REMOTE_GAME_DIR}.bak-{stamp}; fi")
    ssh(f"cp -a {REMOTE_HUB} {REMOTE_HUB}.bak-{stamp}")

    print("=== 2. Upload ===")
    tar_path = os.path.join(tempfile.gettempdir(), "mini_city_web.tar.gz")
    with tarfile.open(tar_path, "w:gz") as tar:
        for item in os.listdir(LOCAL_BUILD_DIR):
            tar.add(os.path.join(LOCAL_BUILD_DIR, item), arcname=item)
    subprocess.run(["scp", tar_path, f"{SERVER}:/tmp/mini_city_web.tar.gz"], check=True)
    os.remove(tar_path)
    ssh(f"rm -rf {REMOTE_GAME_DIR} && mkdir -p {REMOTE_GAME_DIR} && tar -xzf /tmp/mini_city_web.tar.gz -C {REMOTE_GAME_DIR} && rm -f /tmp/mini_city_web.tar.gz")

    print("=== 3. Hub card ===")
    hub_tmp = os.path.join(tempfile.gettempdir(), "hub_mini_city.html")
    subprocess.run(["scp", f"{SERVER}:{REMOTE_HUB}", hub_tmp], check=True)
    with open(hub_tmp, encoding="utf-8") as f:
        hub = f.read()
    changed = False
    if ".service-card.minicity" not in hub and CSS_ANCHOR in hub:
        hub = hub.replace(CSS_ANCHOR, CSS_ANCHOR + CSS, 1)
        changed = True
    if 'class="service-card minicity"' not in hub:
        if CARD_ANCHOR not in hub:
            sys.exit("hub.html: card anchor not found; not touching the hub")
        hub = hub.replace(CARD_ANCHOR, CARD + CARD_ANCHOR, 1)
        changed = True
    if 'href="/mini-city/">' not in hub.split("<footer>")[-1] and FOOTER_ANCHOR in hub:
        hub = hub.replace(FOOTER_ANCHOR, FOOTER_ANCHOR + FOOTER, 1)
        changed = True
    if changed:
        with open(hub_tmp, "w", encoding="utf-8", newline="\n") as f:
            f.write(hub)
        subprocess.run(["scp", hub_tmp, f"{SERVER}:{REMOTE_HUB}"], check=True)
        print("hub.html updated")
    else:
        print("hub.html already has the card")
    os.remove(hub_tmp)

    print("=== 4. Verify ===")
    remote = {}
    for line in ssh(f"cd {REMOTE_GAME_DIR} && md5sum *").splitlines():
        h, name = line.split(None, 1)
        remote[name.strip()] = h
    bad = [n for n in os.listdir(LOCAL_BUILD_DIR) if remote.get(n) != md5(os.path.join(LOCAL_BUILD_DIR, n))]
    print("files match" if not bad else f"MISMATCH: {bad}")
    print(ssh(f"curl -s -o /dev/null -w '%{{http_code}}' http://127.0.0.1:3000/{ROUTE}/", check=False), f"<- /{ROUTE}/")
    print(ssh(f"curl -s http://127.0.0.1:3000/ | grep -c '/{ROUTE}/'", check=False).strip(), "hub links")
    if bad:
        sys.exit(1)
    print(f"done: https://minohlee.mooo.com/{ROUTE}/")


if __name__ == "__main__":
    main()
