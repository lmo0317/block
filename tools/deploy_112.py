import os
import subprocess
import tarfile
import tempfile
import sys

SERVER = "local-ai-server"
REMOTE_PUBLIC = "/home/lmo0317/apps/planner/public"
REMOTE_GAME_DIR = f"{REMOTE_PUBLIC}/block-game"
REMOTE_HUB = f"{REMOTE_PUBLIC}/hub.html"
LOCAL_BUILD_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "build", "web"))

def run_ssh(cmd):
    full_cmd = ["ssh", SERVER, cmd]
    print(f"[SSH] {cmd}")
    res = subprocess.run(full_cmd, capture_output=True, text=True)
    if res.returncode != 0:
        print(f"[ERROR] {res.stderr}")
    return res

def deploy():
    print("=== 1. Checking local build files ===")
    if not os.path.exists(os.path.join(LOCAL_BUILD_DIR, "index.html")):
        print(f"Error: {LOCAL_BUILD_DIR}/index.html does not exist! Please export first.")
        sys.exit(1)
        
    print(f"Build dir: {LOCAL_BUILD_DIR}")
    files = os.listdir(LOCAL_BUILD_DIR)
    print(f"Files to deploy: {files}")

    print("\n=== 2. Creating remote directories ===")
    run_ssh(f"mkdir -p {REMOTE_GAME_DIR}")

    print("\n=== 3. Packaging and uploading build files ===")
    with tempfile.NamedTemporaryFile(suffix=".tar.gz", delete=False) as tmp_tar:
        tar_path = tmp_tar.name

    try:
        with tarfile.open(tar_path, "w:gz") as tar:
            for item in os.listdir(LOCAL_BUILD_DIR):
                item_path = os.path.join(LOCAL_BUILD_DIR, item)
                tar.add(item_path, arcname=item)
        print(f"Created local archive: {tar_path} ({os.path.getsize(tar_path)} bytes)")

        # Upload tar to remote
        remote_tar = "/tmp/block_game_web.tar.gz"
        print(f"Uploading {tar_path} -> {SERVER}:{remote_tar} ...")
        scp_cmd = ["scp", tar_path, f"{SERVER}:{remote_tar}"]
        subprocess.run(scp_cmd, check=True)

        # Extract on remote
        print("Extracting files on remote server...")
        run_ssh(f"tar -xzf {remote_tar} -C {REMOTE_GAME_DIR} && rm -f {remote_tar}")
        # Symlink block-blast -> block-game
        run_ssh(f"ln -sfn block-game {REMOTE_PUBLIC}/block-blast")
        print("Web build transferred and symlinked successfully!")
    finally:
        if os.path.exists(tar_path):
            os.remove(tar_path)

    print("\n=== 4. Updating 112 Main Hub (hub.html) ===")
    # Download current hub.html
    hub_tmp = os.path.join(tempfile.gettempdir(), "hub.html")
    subprocess.run(["scp", f"{SERVER}:{REMOTE_HUB}", hub_tmp], check=True)

    with open(hub_tmp, "r", encoding="utf-8") as f:
        content = f.read()

    # 4.1 CSS
    css_target = ".service-card.boar .card-icon-wrap { background: rgba(239, 68, 68, 0.15); border: 1px solid rgba(239, 68, 68, 0.35); color: #f87171; }"
    new_css = """.service-card.boar .card-icon-wrap { background: rgba(239, 68, 68, 0.15); border: 1px solid rgba(239, 68, 68, 0.35); color: #f87171; }
    .service-card.blockblast::before { background: linear-gradient(90deg, #06b6d4, #3b82f6, #8b5cf6); }
    .service-card.blockblast .card-icon-wrap { background: rgba(6, 182, 212, 0.15); border: 1px solid rgba(6, 182, 212, 0.35); color: #22d3ee; }
    .service-card.blockblast .card-route { color: #38bdf8; }"""

    if css_target in content and ".service-card.blockblast" not in content:
        content = content.replace(css_target, new_css)
        print("Added blockblast CSS rules.")

    # 4.2 Card HTML
    card_html = """        <!-- 7. 퍼즐블록 (PuzzleBlock) -->
        <a href="/block-game/" class="service-card blockblast">
          <div class="card-top">
            <div class="card-icon-wrap">
              <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                <rect x="3" y="3" width="7" height="7" rx="1.5"/>
                <rect x="14" y="3" width="7" height="7" rx="1.5"/>
                <rect x="14" y="14" width="7" height="7" rx="1.5"/>
                <rect x="3" y="14" width="7" height="7" rx="1.5"/>
              </svg>
            </div>
            <span class="card-status-badge active" id="badge-blockblast"><span class="mini-dot"></span> 정상 가동 (Godot 4 Web)</span>
          </div>
          <div class="card-title-group">
            <h2>퍼즐블록 (PuzzleBlock)</h2>
            <span class="card-route">/block-game</span>
          </div>
          <p class="card-desc">블록 3개를 놓아 줄을 지우고 콤보를 이어가는 8×8 블록 퍼즐. 오늘의 챌린지와 어드벤처 스테이지까지, 브라우저와 모바일에서 바로 즐기세요!</p>
          <div class="tag-row">
            <span class="tag">#퍼즐블록</span>
            <span class="tag">#PuzzleBlock</span>
            <span class="tag">#8x8퍼즐</span>
            <span class="tag">#콤보폭발</span>
            <span class="tag">#Godot4Web</span>
          </div>
          <div class="card-cta">
            <span>게임 플레이하기</span>
            <svg viewBox="0 0 24 24"><line x1="5" y1="12" x2="19" y2="12"/><polyline points="12 5 19 12 12 19"/></svg>
          </div>
        </a>
"""

    card_anchor = '<!-- 6. FaceMatch AI -->'
    if card_anchor in content and 'class="service-card blockblast"' not in content:
        content = content.replace(card_anchor, card_html + '\n        ' + card_anchor)
        print("Added game Service Card to hub.html.")
    elif 'class="service-card blockblast"' in content:
        # Replace the existing card (from its comment line to its closing </a>) so name/text stay current
        idx = content.index('class="service-card blockblast"')
        start = content.rfind('<!--', 0, idx)
        start = content.rfind('\n', 0, start) + 1
        end = content.index('</a>', idx) + len('</a>\n')
        if content[start:end] != card_html:
            content = content[:start] + card_html + content[end:]
            print("Updated game Service Card in hub.html.")

    # 4.3 Footer links
    footer_target = '<a href="/facematching/">얼굴 유사도(FaceMatch)</a>'
    new_footer = '<a href="/facematching/">얼굴 유사도(FaceMatch)</a>\n        <a href="/block-game/">퍼즐블록</a>'
    if footer_target in content and 'href="/block-game/"' not in content:
        content = content.replace(footer_target, new_footer)
        print("Added block-game to footer links.")
    for old_name in ("블록 블라스트", "블록트리스"):
        content = content.replace(f'<a href="/block-game/">{old_name}</a>', '<a href="/block-game/">퍼즐블록</a>')

    with open(hub_tmp, "w", encoding="utf-8") as f:
        f.write(content)

    # Backup on remote
    run_ssh(f"cp -n {REMOTE_HUB} {REMOTE_HUB}.bak-before-block || true")
    # Upload updated hub.html
    subprocess.run(["scp", hub_tmp, f"{SERVER}:{REMOTE_HUB}"], check=True)
    print("hub.html successfully updated on remote server!")

    print("\n=== 5. Verifying Deployment ===")
    test_res = run_ssh("curl -I -s http://127.0.0.1:3000/block-game/ | head -n 5")
    print(f"HTTP response for /block-game/:\n{test_res.stdout}")

    test_res2 = run_ssh("curl -I -s http://127.0.0.1:3000/block-blast/ | head -n 5")
    print(f"HTTP response for /block-blast/:\n{test_res2.stdout}")

    test_hub = run_ssh("curl -s http://127.0.0.1:3000/ | grep -c 'block-game'")
    print(f"Occurrences of 'block-game' in hub.html response: {test_hub.stdout.strip()}")

    print("\n[SUCCESS] PuzzleBlock deployed and connected to 112 main hub!")

if __name__ == "__main__":
    deploy()
