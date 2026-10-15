import os
import requests

GITHUB_API = "https://api.github.com/repos/M5Devs/OpenROM/releases/latest"

def get_latest_release():
    try:
        response = requests.get(GITHUB_API, timeout=15)
        response.raise_for_status()
        return response.json()
    except Exception as e:
        print(f"⚠️ Error fetching release from GitHub: {e}")
        return None

def generate_html(release_data=None):
    version = "v3.8.0"
    release_date = ""
    
    # Download URLs & sizes
    win_installer_url = win_portable_url = linux_x64_url = linux_arm_url = mac_arm_url = mac_intel_url = "#"
    win_installer_sz = win_portable_sz = linux_x64_sz = linux_arm_sz = mac_arm_sz = mac_intel_sz = "—"

    if release_data:
        version = release_data.get('tag_name', version)
        release_date = release_data.get('published_at', '')[:10]
        
        for asset in release_data.get('assets', []):
            name = asset.get('name', '').lower()
            url  = asset.get('browser_download_url', '#')
            size = f"{round(asset.get('size', 0) / (1024*1024), 1)} MB"
            
            if 'windows' in name or 'win' in name:
                if 'setup' in name or 'installer' in name:
                    win_installer_url, win_installer_sz = url, size
                else:
                    win_portable_url, win_portable_sz = url, size
            elif 'linux' in name:
                if 'arm64' in name or 'aarch64' in name:
                    linux_arm_url, linux_arm_sz = url, size
                else:
                    linux_x64_url, linux_x64_sz = url, size
            elif 'macos' in name or 'mac' in name:
                if 'arm64' in name or 'applesilicon' in name:
                    mac_arm_url, mac_arm_sz = url, size
                else:
                    mac_intel_url, mac_intel_sz = url, size

    assets_rows = ""
    if release_data and release_data.get('assets'):
        for asset in release_data.get('assets', []):
            nm  = asset.get('name', '')
            url = asset.get('browser_download_url', '#')
            sz  = round(asset.get('size', 0) / (1024*1024), 1)
            dl  = asset.get('download_count', 0)
            assets_rows += f'<tr><td><a href="{url}">{nm}</a></td><td>{sz} MB</td><td>{dl:,}</td></tr>\n'
    else:
        assets_rows = '<tr><td colspan="3" style="color:#7070a0; text-align:center;">No release assets found</td></tr>'

    html = f"""<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<meta name="description" content="OpenROM {version} — Universal Retro Gaming Toolkit. Convert, patch, compress, and manage ROMs. Offline, privacy-first, and multiplatform.">
<meta name="keywords" content="OpenROM, ROM converter, CHD, RVZ, CSO, WUA, PS1, PS2, GameCube, Wii, Wii U, Dreamcast, Saturn, Retro Gaming, Emulation, M3U, Patching, xdelta3">
<title>OpenROM {version} — Universal Retro Gaming Toolkit</title>
<link rel="icon" type="image/png" sizes="32x32" href="/icons/favicon-32x32.png">
<link rel="icon" type="image/png" sizes="16x16" href="/icons/favicon-16x16.png">
<link rel="apple-touch-icon" sizes="180x180" href="/icons/apple-touch-icon.png">
<link rel="manifest" href="/icons/site.webmanifest">
<link rel="preconnect" href="https://fonts.googleapis.com">
<link href="https://fonts.googleapis.com/css2?family=Space+Grotesk:wght@400;500;600;700&family=Inter:wght@400;500;600&family=JetBrains+Mono:wght@400;500&display=swap" rel="stylesheet">
<style>
:root {{
  --bg: #090910;
  --bg2: #111120;
  --bg3: #18182a;
  --red: #e63946;
  --red-dim: #9b2335;
  --gold: #f4c542;
  --blue: #4895ef;
  --green: #2ec4b6;
  --text: #e8e8f0;
  --muted: #7070a0;
  --border: #22223a;
  --radius: 8px;
  --font-h: 'Space Grotesk', sans-serif;
  --font-b: 'Inter', sans-serif;
  --font-m: 'JetBrains Mono', monospace;
}}

*, *::before, *::after {{ box-sizing: border-box; margin: 0; padding: 0; }}

body {{
  font-family: var(--font-b);
  background: var(--bg);
  color: var(--text);
  line-height: 1.65;
  -webkit-font-smoothing: antialiased;
}}

a {{ color: var(--red); text-decoration: none; transition: color .15s; }}
a:hover {{ text-decoration: underline; }}

body::before {{
  content: '';
  position: fixed;
  inset: 0;
  background: repeating-linear-gradient(0deg, transparent, transparent 2px, rgba(0,0,0,.06) 2px, rgba(0,0,0,.06) 4px);
  pointer-events: none;
  z-index: 9999;
}}

.wrap {{ max-width: 900px; margin: 0 auto; padding: 0 24px; }}

nav {{
  border-bottom: 1px solid var(--border);
  padding: 16px 0;
  position: sticky;
  top: 0;
  background: rgba(9,9,16,.92);
  backdrop-filter: blur(12px);
  z-index: 100;
}}
nav .wrap {{ display: flex; align-items: center; justify-content: space-between; }}
.nav-logo {{
  font-family: var(--font-h);
  font-weight: 700;
  font-size: 1.15rem;
  color: var(--text);
  display: flex;
  align-items: center;
  gap: 8px;
}}
.nav-logo span {{ color: var(--red); }}
.nav-links {{ display: flex; gap: 24px; font-size: .9rem; }}
.nav-links a {{ color: var(--muted); }}
.nav-links a:hover {{ color: var(--text); text-decoration: none; }}

.hero {{ padding: 75px 0 55px; border-bottom: 1px solid var(--border); }}
.hero-eyebrow {{
  font-family: var(--font-m);
  font-size: .75rem;
  color: var(--red);
  letter-spacing: .12em;
  margin-bottom: 16px;
}}
.hero h1 {{
  font-family: var(--font-h);
  font-size: clamp(2.4rem, 6vw, 3.8rem);
  font-weight: 700;
  line-height: 1.1;
  margin-bottom: 16px;
}}
.hero h1 em {{ font-style: normal; color: var(--red); }}
.hero-sub {{ font-size: 1.05rem; color: var(--muted); max-width: 620px; margin-bottom: 30px; }}

.pill-row {{ display: flex; flex-wrap: wrap; gap: 8px; margin-bottom: 35px; }}
.pill {{
  font-family: var(--font-m);
  font-size: .72rem;
  padding: 4px 10px;
  border-radius: 4px;
  border: 1px solid var(--border);
  color: var(--muted);
}}
.pill.active {{ border-color: var(--red-dim); color: var(--red); }}
.pill.green {{ border-color: rgba(46,196,182,.3); color: var(--green); }}

.dl-grid {{
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
  gap: 12px;
  margin-bottom: 14px;
}}
.dl-btn {{
  display: flex;
  flex-direction: column;
  padding: 14px 18px;
  background: var(--bg3);
  border: 1px solid var(--border);
  border-radius: var(--radius);
  color: var(--text);
  font-size: .9rem;
  font-weight: 500;
  transition: all .15s ease;
}}
.dl-btn:hover {{
  border-color: var(--red);
  background: rgba(230,57,70,.08);
  text-decoration: none;
  transform: translateY(-1px);
}}
.dl-btn .os {{ font-size: .8rem; color: var(--muted); margin-bottom: 2px; }}
.dl-btn .sz {{ font-family: var(--font-m); font-size: .72rem; color: var(--muted); }}

.dl-note {{ font-family: var(--font-m); font-size: .75rem; color: var(--muted); margin-top: 10px; }}

section {{ padding: 60px 0; border-bottom: 1px solid var(--border); }}
.section-label {{
  font-family: var(--font-m);
  font-size: .72rem;
  color: var(--red);
  letter-spacing: .1em;
  margin-bottom: 10px;
}}
section h2 {{ font-family: var(--font-h); font-size: 1.5rem; font-weight: 600; margin-bottom: 25px; }}

.feat-grid {{
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(260px, 1fr));
  gap: 12px;
}}
.feat {{
  padding: 24px;
  background: var(--bg2);
  border: 1px solid var(--border);
  border-radius: var(--radius);
}}
.feat-icon {{ font-size: 1.6rem; margin-bottom: 12px; }}
.feat h3 {{ font-family: var(--font-h); font-size: .95rem; font-weight: 600; margin-bottom: 6px; }}
.feat p {{ font-size: .88rem; color: var(--muted); }}

.tbl-wrap {{ overflow-x: auto; background: var(--bg2); border: 1px solid var(--border); border-radius: var(--radius); }}
table {{ width: 100%; border-collapse: collapse; font-size: .88rem; }}
th, td {{ padding: 12px 16px; text-align: left; border-bottom: 1px solid var(--border); vertical-align: top; }}
th {{
  font-family: var(--font-m);
  font-size: .72rem;
  color: var(--muted);
  letter-spacing: .06em;
  font-weight: 500;
  background: var(--bg3);
}}
tr:last-child td {{ border-bottom: none; }}
tbody tr:hover {{ background: rgba(255,255,255,.02); }}
td code {{
  font-family: var(--font-m);
  font-size: .8rem;
  color: var(--gold);
  background: rgba(244,197,66,.08);
  padding: 2px 6px;
  border-radius: 3px;
}}

.video-box {{
  position: relative;
  padding-bottom: 56.25%;
  height: 0;
  overflow: hidden;
  border-radius: var(--radius);
  border: 1px solid var(--border);
}}
.video-box iframe {{ position: absolute; inset: 0; width: 100%; height: 100%; }}

.term {{
  background: #05050d;
  border: 1px solid var(--border);
  border-radius: var(--radius);
  padding: 20px 24px;
  overflow-x: auto;
}}
.term pre {{ font-family: var(--font-m); font-size: .82rem; color: #a8b5d1; line-height: 1.7; }}
.term .prompt {{ color: var(--red); user-select: none; }}
.term .comment {{ color: #4d4d75; }}

.support-box {{
  background: var(--bg2);
  border: 1px solid var(--border);
  border-radius: var(--radius);
  padding: 36px;
  text-align: center;
}}
.support-box h2 {{ font-family: var(--font-h); font-size: 1.35rem; margin-bottom: 8px; }}
.support-box p {{ color: var(--muted); font-size: .9rem; margin-bottom: 20px; }}
.crypto {{
  font-family: var(--font-m);
  font-size: .78rem;
  color: var(--gold);
  background: rgba(244,197,66,.06);
  border: 1px solid rgba(244,197,66,.15);
  padding: 10px 16px;
  border-radius: 4px;
  display: inline-block;
  word-break: break-all;
}}
.btn-row {{ display: flex; justify-content: center; gap: 12px; flex-wrap: wrap; margin-top: 20px; }}
.btn {{
  font-family: var(--font-h);
  font-size: .88rem;
  font-weight: 600;
  padding: 10px 22px;
  border-radius: var(--radius);
  border: 1px solid var(--border);
  color: var(--text);
  background: var(--bg3);
}}
.btn:hover {{ border-color: var(--red); text-decoration: none; }}
.btn.primary {{ background: var(--red); border-color: var(--red); color: #fff; }}
.btn.primary:hover {{ background: #c1121f; border-color: #c1121f; }}

footer {{ padding: 35px 0; border-top: 1px solid var(--border); }}
footer .wrap {{ display: flex; justify-content: space-between; align-items: center; flex-wrap: wrap; gap: 12px; font-size: .82rem; color: var(--muted); }}
footer a {{ color: var(--muted); }}
footer a:hover {{ color: var(--text); }}
</style>
</head>
<body>

<!-- NAV -->
<nav>
  <div class="wrap">
    <div class="nav-logo">⬡ <span>Open</span>ROM</div>
    <div class="nav-links">
      <a href="#features">Features</a>
      <a href="#matrix">Formats</a>
      <a href="#cli">CLI</a>
      <a href="https://github.com/M5Devs/OpenROM/releases">Releases</a>
      <a href="https://github.com/M5Devs/OpenROM">GitHub</a>
    </div>
  </div>
</nav>

<!-- HERO -->
<div class="hero">
  <div class="wrap">
    <p class="hero-eyebrow">M5 DEV · GPL-3.0 · {version} {'· ' + release_date if release_date else ''}</p>
    <h1>Universal Retro<br><em>Gaming Toolkit.</em></h1>
    <p class="hero-sub">One modern app to convert, patch, compress, and organize your entire ROM library.
    From PS1 & Dreamcast to Wii U — 100% offline, zero telemetry, zero nonsense.</p>

    <div class="pill-row">
      <span class="pill active">🪟 Windows</span>
      <span class="pill active">🐧 Linux x64 / ARM64</span>
      <span class="pill active">🍎 macOS Apple Silicon / Intel</span>
      <span class="pill green">CHD (FLAC/Vorbis)</span>
      <span class="pill green">RVZ</span>
      <span class="pill green">WUA (Wii U)</span>
      <span class="pill green">CSO · ZSO</span>
      <span class="pill">11 Patch Formats</span>
      <span class="pill">No-Intro / Redump DAT</span>
    </div>

    <div class="dl-grid">
      {'<a href="' + win_installer_url + '" class="dl-btn"><span class="os">Windows Setup</span><span>Installer (.exe)</span><span class="sz">' + win_installer_sz + '</span></a>' if win_installer_url != '#' else ''}
      {'<a href="' + win_portable_url + '" class="dl-btn"><span class="os">Windows Portable</span><span>Portable (.zip)</span><span class="sz">' + win_portable_sz + '</span></a>' if win_portable_url != '#' else ''}
      {'<a href="' + linux_x64_url + '" class="dl-btn"><span class="os">Linux x86_64</span><span>Native Bundle</span><span class="sz">' + linux_x64_sz + '</span></a>' if linux_x64_url != '#' else ''}
      {'<a href="' + linux_arm_url + '" class="dl-btn"><span class="os">Linux ARM64</span><span>Steam Deck / Pi</span><span class="sz">' + linux_arm_sz + '</span></a>' if linux_arm_url != '#' else ''}
      {'<a href="' + mac_arm_url + '" class="dl-btn"><span class="os">macOS Apple Silicon</span><span>M1 / M2 / M3 / M4</span><span class="sz">' + mac_arm_sz + '</span></a>' if mac_arm_url != '#' else ''}
      {'<a href="' + mac_intel_url + '" class="dl-btn"><span class="os">macOS Intel</span><span>x86_64 Mac</span><span class="sz">' + mac_intel_sz + '</span></a>' if mac_intel_url != '#' else ''}
    </div>
    <p class="dl-note">
      Also mirrored on <a href="https://sourceforge.net/projects/openrom/">SourceForge</a> ·
      <a href="https://github.com/M5Devs/OpenROM/releases">All Releases on GitHub</a> ·
      <a href="https://github.com/M5Devs/OpenROM/blob/main/SECURITY.md">SHA256 Checksums</a>
    </p>
  </div>
</div>

<!-- ROMEO INTRO -->
<section>
  <div class="wrap">
    <p class="section-label">MEET ROMEO</p>
    <h2>OpenROM's pixel-art companion</h2>
    <div class="video-box">
      <iframe src="https://www.youtube.com/embed/oOYszkhmR3A" title="Meet ROMeo" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture" allowfullscreen></iframe>
    </div>
  </div>
</section>

<!-- FEATURES -->
<section id="features">
  <div class="wrap">
    <p class="section-label">TOOLKIT FEATURES</p>
    <h2>Engineered for game preservation</h2>
    <div class="feat-grid">
      <div class="feat">
        <div class="feat-icon">🔁</div>
        <h3>20+ Conversion Paths</h3>
        <p>Smart magic-byte detection. Convert between ISO, CHD, RVZ, CSO, ZSO, WUA, XISO, ECM, and more without guessing.</p>
      </div>
      <div class="feat">
        <div class="feat-icon">🌀</div>
        <h3>Dreamcast & Saturn Suite</h3>
        <p>IP.BIN boot sector editor (region free, VGA, Shift-JIS), GDI track inspector, DCP patcher, and Sega Saturn SSP support.</p>
      </div>
      <div class="feat">
        <div class="feat-icon">🩹</div>
        <h3>Universal ROM Patching</h3>
        <p>11 formats: IPS, IPS32, UPS, BPS, PPF, APS, EBP, DPS, xdelta3, SSP, and DCP with automatic format detection.</p>
      </div>
      <div class="feat">
        <div class="feat-icon">🏷️</div>
        <h3>ROM Renamer & DAT Matching</h3>
        <p>Instant No-Intro & Redump DAT matching. High-performance streaming XML parser with composite CRC32+Size lookup.</p>
      </div>
      <div class="feat">
        <div class="feat-icon">🗂️</div>
        <h3>Multi-Disc & CUE Utilities</h3>
        <p>One-click M3U playlist generator, multi-track BIN merger with PREGAP handling, and integrated CUE sheet editor.</p>
      </div>
      <div class="feat">
        <div class="feat-icon">🖥️</div>
        <h3>Flutter GUI + Headless CLI</h3>
        <p>Modern dark gaming dashboard with themes and real-time logs, coupled with <code>openrom-core</code> for script automation.</p>
      </div>
    </div>
  </div>
</section>

<!-- MATRIX -->
<section id="matrix">
  <div class="wrap">
    <p class="section-label">CONVERSION MATRIX</p>
    <h2>Supported image formats</h2>
    <div class="tbl-wrap">
      <table>
        <thead>
          <tr><th>Source Format</th><th>Target Output</th><th>Target Systems</th><th>Backend Engine</th></tr>
        </thead>
        <tbody>
          <tr><td>ISO / BIN / CUE / IMG</td><td><code>CHD</code></td><td>PS1, PS2, Dreamcast, Saturn, Sega CD</td><td>chdman (FLAC / Vorbis)</td></tr>
          <tr><td>GDI</td><td><code>CHD</code></td><td>Dreamcast</td><td>chdman</td></tr>
          <tr><td>ISO / GCZ</td><td><code>RVZ / WIA</code></td><td>GameCube, Wii</td><td>nodtool</td></tr>
          <tr><td>WUD / WUX</td><td><code>WUA / ISO</code></td><td>Wii U (ZArchive)</td><td>nkit v3.1</td></tr>
          <tr><td>ISO</td><td><code>CSO / ZSO</code></td><td>PSP, PS2</td><td>maxcso</td></tr>
          <tr><td>ISO</td><td><code>XISO / Folders</code></td><td>Original Xbox</td><td>extract-xiso</td></tr>
          <tr><td>CCI / ZAR</td><td><code>ISO</code></td><td>Xbox 360</td><td>xgdtool</td></tr>
          <tr><td>CHD</td><td><code>ISO / BIN+CUE</code></td><td>All supported CD/DVD discs</td><td>chdman extract</td></tr>
          <tr><td>CSO / ZSO</td><td><code>ISO</code></td><td>PSP, PS2</td><td>maxcso decompress</td></tr>
          <tr><td>RVZ / WIA / WBFS</td><td><code>ISO</code></td><td>GameCube, Wii</td><td>nodtool convert</td></tr>
          <tr><td>ECM / unecm</td><td><code>ISO / BIN</code></td><td>Universal</td><td>ecm / unecm</td></tr>
        </tbody>
      </table>
    </div>
  </div>
</section>

<!-- CLI -->
<section id="cli">
  <div class="wrap">
    <p class="section-label">AUTOMATION & TERMINAL</p>
    <h2>Full headless CLI included</h2>
    <div class="term"><pre>
<span class="comment"># Detect console & magic bytes</span>
<span class="prompt">$</span> openrom-core --detect "Silent Hill.bin"

<span class="comment"># Convert to CHD (FLAC audio by default)</span>
<span class="prompt">$</span> openrom-core --input "game.iso" --format CHD

<span class="comment"># Convert to CHD with maximum Vorbis audio compression</span>
<span class="prompt">$</span> openrom-core --input "game.cue" --format CHD --audio-codec vorbis

<span class="comment"># Convert Wii U image to compressed WUA (ZArchive)</span>
<span class="prompt">$</span> openrom-core --input "SuperMario3DWorld.wux" --format WUA

<span class="comment"># Edit Dreamcast IP.BIN boot sector</span>
<span class="prompt">$</span> openrom-core --write-ipbin IP.BIN --region-free --set-vga --set-title "CUSTOM TITLE"

<span class="comment"># Apply delta patch (IPS, BPS, xdelta3, DCP, SSP)</span>
<span class="prompt">$</span> openrom-core --patch "game.sfc" --patch-file "translation.bps"
    </pre></div>
  </div>
</section>

<!-- ASSETS -->
<section>
  <div class="wrap">
    <p class="section-label">RELEASE ARTIFACTS · {version}</p>
    <h2>Official downloads</h2>
    <div class="tbl-wrap">
      <table>
        <thead><tr><th>Package</th><th>Size</th><th>Downloads</th></tr></thead>
        <tbody>{assets_rows}</tbody>
      </table>
    </div>
    <br>
    <p style="font-size:.82rem; color:var(--muted)">
      Every release package is verifiable via SHA256 checksums documented in
      <a href="https://github.com/M5Devs/OpenROM/blob/main/SECURITY.md">SECURITY.md</a>.
    </p>
  </div>
</section>

<!-- SUPPORT -->
<section>
  <div class="wrap">
    <div class="support-box">
      <h2>Support OpenROM Development</h2>
      <p>Solo developer building modern open-source tools for retro gamers.<br>Your support fuels more features, wider preservation, and unlimited coffee.</p>
      
      <p style="color:var(--muted); font-size:.78rem; margin-bottom: 6px;">USDT (TRC20)</p>
      <div class="crypto">TWbG9smLbcyTcVod3YsRPyEtWhtQnnu7vC</div>
      
      <div class="btn-row">
        <a href="https://donatr.ee/m5dev" class="btn primary" target="_blank" rel="noopener">Donate via Donatree</a>
        <a href="https://github.com/sponsors/clausvalcatd" class="btn" target="_blank" rel="noopener">GitHub Sponsors</a>
        <a href="https://github.com/M5Devs/OpenROM" class="btn">View on GitHub</a>
      </div>
    </div>
  </div>
</section>

<!-- FOOTER -->
<footer>
  <div class="wrap">
    <span>⬡ OpenROM {version} · Maintained by M5 Dev · GPL-3.0</span>
    <span>
      <a href="https://github.com/M5Devs/OpenROM">GitHub</a> ·
      <a href="https://sourceforge.net/projects/openrom/">SourceForge</a> ·
      <a href="https://huggingface.co/collections/M5-Dev/m5-nostalgia-archive">Nostalgia Archive</a>
    </span>
  </div>
</footer>

</body>
</html>"""
    return html

def main():
    print("🚀 Fetching latest OpenROM release from GitHub API...")
    release = get_latest_release()
    if release:
        print(f"📦 Found tag: {release.get('tag_name')} ({release.get('published_at','')[:10]})")
    else:
        print("⚠️ GitHub API unreachable, using default fallback metadata.")

    print("\n📝 Generating index.html...")
    html_content = generate_html(release)
    
    out_path = "index.html"
    with open(out_path, "w", encoding="utf-8") as f:
        f.write(html_content)
        
    print(f"✅ Generated {out_path} ({len(html_content):,} bytes)")

if __name__ == "__main__":
    main()
