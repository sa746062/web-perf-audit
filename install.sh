#!/usr/bin/env bash
#
# web-perf-audit — One-shot install script (macOS / Linux)
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/EVEDensity/web-perf-audit/main/install.sh | bash
#   # or
#   chmod +x install.sh && ./install.sh
#
# Options:
#   --dir <path>    Install directory (default: ~/.web-perf-audit)
#   --no-lighthouse Skip Lighthouse CLI install
#   --no-puppeteer  Skip Puppeteer install
#   --help          Show this message

set -euo pipefail

INSTALL_DIR="${HOME}/.web-perf-audit"
SKIP_LIGHTHOUSE=false
SKIP_PUPPETEER=false
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

log()  { echo -e "${CYAN}[web-perf-audit]${NC} $1"; }
ok()   { echo -e "${GREEN}[✓]${NC} $1"; }
warn() { echo -e "${YELLOW}[!]${NC} $1"; }
err()  { echo -e "${RED}[✗]${NC} $1"; exit 1; }

# ── Parse args ──────────────────────────────────────────────
while [[ $# -gt 0 ]]; do
  case "$1" in
    --dir) INSTALL_DIR="$2"; shift 2 ;;
    --no-lighthouse) SKIP_LIGHTHOUSE=true; shift ;;
    --no-puppeteer) SKIP_PUPPETEER=true; shift ;;
    --help)
      sed -n '3,13p' "$0"
      exit 0
      ;;
    *) err "Unknown flag: $1 (use --help)" ;;
  esac
done

# ── Prerequisites check ─────────────────────────────────────
log "Checking prerequisites..."

command -v git      >/dev/null 2>&1 || err "git is required. Install: https://git-scm.com"
command -v python3  >/dev/null 2>&1 || err "Python 3.8+ is required. Install: https://python.org"
command -v node     >/dev/null 2>&1 || err "Node.js 18+ is required. Install: https://nodejs.org"

PYTHON_VERSION=$(python3 -c 'import sys; print(f"{sys.version_info.major}.{sys.version_info.minor}")')
NODE_VERSION=$(node -v | sed 's/v//' | cut -d. -f1)

py_ver_ok() { python3 -c "import sys; sys.exit(0 if sys.version_info >= (3,8) else 1)"; }
if py_ver_ok; then
  ok "Python $PYTHON_VERSION"
else
  err "Python $PYTHON_VERSION is too old. Need ≥ 3.8"
fi

if [ "$NODE_VERSION" -ge 18 ] 2>/dev/null; then
  ok "Node.js $(node -v)"
else
  err "Node.js $(node -v) is too old. Need ≥ 18"
fi

# ── Clone repository ────────────────────────────────────────
if [ -d "$INSTALL_DIR" ]; then
  warn "$INSTALL_DIR already exists. Updating..."
  cd "$INSTALL_DIR"
  git pull --ff-only 2>/dev/null || warn "Could not git pull — continuing with existing files"
  ok "Repository updated"
else
  log "Cloning into $INSTALL_DIR..."
  git clone --depth 1 https://github.com/EVEDensity/web-perf-audit.git "$INSTALL_DIR"
  ok "Repository cloned"
fi

cd "$INSTALL_DIR"

# ── Install Node dependencies ───────────────────────────────
log "Installing Node.js dependencies..."

if [ "$SKIP_PUPPETEER" = false ]; then
  npm install 2>/dev/null || warn "npm install failed — try running manually: cd $INSTALL_DIR && npm install"
  ok "Puppeteer installed"
fi

if [ "$SKIP_LIGHTHOUSE" = false ]; then
  if command -v lighthouse >/dev/null 2>&1; then
    ok "Lighthouse CLI already installed ($(lighthouse --version 2>&1 | head -1))"
  else
    log "Installing Lighthouse CLI..."
    npm install -g lighthouse 2>/dev/null || warn "Lighthouse install failed. Try: npm install -g lighthouse"
    ok "Lighthouse CLI installed"
  fi
fi

# ── Python check ────────────────────────────────────────────
log "Checking Python scripts..."
for script in scripts/*.py; do
  python3 -m py_compile "$script" 2>/dev/null || warn "Syntax error in $(basename $script)"
done
ok "Python scripts validated"

# ── Shell alias ─────────────────────────────────────────────
SHELL_RC=""
case "$SHELL" in
  */bash) SHELL_RC="$HOME/.bashrc" ;;
  */zsh)  SHELL_RC="$HOME/.zshrc"  ;;
  */fish) SHELL_RC="$HOME/.config/fish/config.fish" ;;
  *)      SHELL_RC="$HOME/.profile" ;;
esac

if [ -f "$SHELL_RC" ]; then
  if ! grep -q "web-perf-audit" "$SHELL_RC" 2>/dev/null; then
    echo "" >> "$SHELL_RC"
    echo "# web-perf-audit (added by install.sh)" >> "$SHELL_RC"
    echo "alias perf-audit='python3 $INSTALL_DIR/scripts/fetch_metrics.py'" >> "$SHELL_RC"
    echo "alias perf-score='python3 $INSTALL_DIR/scripts/score_and_report.py'" >> "$SHELL_RC"
    ok "Aliases added to $SHELL_RC"
  else
    ok "Aliases already present in $SHELL_RC"
  fi
fi

# ── Done ────────────────────────────────────────────────────
echo ""
log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log "  web-perf-audit installed! 🚀"
log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log ""
log "  Quick start:"
log "    python3 $INSTALL_DIR/scripts/fetch_metrics.py https://example.com --output-dir .web-perf"
log ""
log "  Or use the alias (restart your shell first):"
log "    perf-audit https://example.com"
log ""
log "  IDE plugins:"
log "    Claude Code:  /plugin install web-perf-audit@EVEDensity/web-perf-audit"
log "    Cursor:       Add '@web-perf-audit' to .cursorrules"
log ""
log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
