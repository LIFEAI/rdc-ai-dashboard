#!/usr/bin/env bash
# ============================================================
#  RDC AI Dashboard — macOS Installer
#  Tested on macOS 13 Ventura / 14 Sonoma
# ============================================================
set -e
echo ""
echo "============================================================"
echo "  RDC AI Dashboard  —  macOS Install"
echo "============================================================"
echo ""

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
echo "[OK] Project dir: $PROJECT_DIR"

# ── Python check ─────────────────────────────────────────────
if command -v python3 &>/dev/null; then
    PY=$(command -v python3)
    echo "[OK] Python3 found: $($PY --version)"
else
    echo "[ERROR] Python 3 not found."
    echo "Install via: brew install python  or  https://python.org"
    exit 1
fi

# ── Virtual environment ───────────────────────────────────────
VENV="$PROJECT_DIR/venv"
if [ -f "$VENV/bin/activate" ]; then
    echo "[OK] Virtual environment exists."
else
    echo "[..] Creating virtual environment..."
    "$PY" -m venv "$VENV"
    echo "[OK] Virtual environment created."
fi

source "$VENV/bin/activate"

# ── Dependencies ──────────────────────────────────────────────
echo "[..] Installing dependencies..."
pip install --upgrade pip -q
pip install -r "$PROJECT_DIR/requirements.txt" -q
echo "[OK] Dependencies installed."

# ── .command launcher ─────────────────────────────────────────
LAUNCHER="$PROJECT_DIR/launchers/Launch_Dashboard.command"
cat > "$LAUNCHER" <<EOF
#!/usr/bin/env bash
source "$VENV/bin/activate"
python "$PROJECT_DIR/src/rdc_dashboard.py" "\$@"
EOF
chmod +x "$LAUNCHER"
echo "[OK] Launcher written: $LAUNCHER"

# ── Applications symlink ──────────────────────────────────────
APP_LINK="$HOME/Applications/RDC Dashboard.command"
mkdir -p "$HOME/Applications"
ln -sf "$LAUNCHER" "$APP_LINK"
echo "[OK] Shortcut created: $APP_LINK"

# ── LaunchAgent for tray-on-login (optional) ─────────────────
PLIST_DIR="$HOME/Library/LaunchAgents"
PLIST="$PLIST_DIR/com.rdc.dashboard.plist"
mkdir -p "$PLIST_DIR"
cat > "$PLIST" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
    "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>             <string>com.rdc.dashboard</string>
    <key>ProgramArguments</key>
    <array>
        <string>$VENV/bin/python</string>
        <string>$PROJECT_DIR/src/rdc_dashboard.py</string>
        <string>--tray</string>
    </array>
    <key>RunAtLoad</key>         <true/>
    <key>KeepAlive</key>         <false/>
    <key>StandardOutPath</key>   <string>/tmp/rdc_dashboard.log</string>
    <key>StandardErrorPath</key> <string>/tmp/rdc_dashboard_err.log</string>
</dict>
</plist>
EOF
launchctl load "$PLIST" 2>/dev/null || true
echo "[OK] LaunchAgent installed (tray starts on login)."

echo ""
echo "============================================================"
echo "  Install complete!"
echo "  Open ~/Applications/RDC Dashboard.command to launch."
echo "  Or double-click launchers/Launch_Dashboard.command"
echo "============================================================"
echo ""
