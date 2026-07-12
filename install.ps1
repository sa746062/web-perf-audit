# web-perf-audit — One-shot install script (Windows PowerShell)
#
# Usage:
#   iwr -Uri https://raw.githubusercontent.com/EVEDensity/web-perf-audit/main/install.ps1 -OutFile install.ps1; ./install.ps1
#   # or
#   ./install.ps1 -InstallDir "$env:USERPROFILE\.web-perf-audit"
#
# Options:
#   -InstallDir <path>    Install directory (default: ~\.web-perf-audit)
#   -SkipLighthouse       Skip Lighthouse CLI install
#   -SkipPuppeteer        Skip Puppeteer install
#   -Help                 Show this message

param(
  [string]$InstallDir = "$env:USERPROFILE\.web-perf-audit",
  [switch]$SkipLighthouse = $false,
  [switch]$SkipPuppeteer = $false,
  [switch]$Help = $false
)

if ($Help) {
  Get-Help $PSCommandPath -Detailed
  exit 0
}

$ErrorActionPreference = "Stop"
$CYAN = [ConsoleColor]::Cyan
$GREEN = [ConsoleColor]::Green
$YELLOW = [ConsoleColor]::Yellow
$RED = [ConsoleColor]::Red

function Write-Log  { Write-Host "[web-perf-audit] $args" -ForegroundColor $CYAN }
function Write-OK   { Write-Host "[✓] $args" -ForegroundColor $GREEN }
function Write-Warn { Write-Host "[!] $args" -ForegroundColor $YELLOW }
function Write-Err  { Write-Host "[✗] $args" -ForegroundColor $RED; exit 1 }

# ── Prerequisites check ─────────────────────────────────────
Write-Log "Checking prerequisites..."

try { git --version | Out-Null } catch { Write-Err "git is required. Install: https://git-scm.com" }
try { python --version | Out-Null } catch { Write-Err "Python 3.8+ is required. Install: https://python.org" }
try { node --version | Out-Null } catch { Write-Err "Node.js 18+ is required. Install: https://nodejs.org" }

$pyVer = (python -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}')")
$nodeMajor = [int](node -v).Replace("v", "").Split(".")[0]

$pyOk = python -c "import sys; sys.exit(0 if sys.version_info >= (3,8) else 1)"
if ($LASTEXITCODE -eq 0) {
  Write-OK "Python $pyVer"
} else {
  Write-Err "Python $pyVer is too old. Need ≥ 3.8"
}

if ($nodeMajor -ge 18) {
  Write-OK "Node.js $(node -v)"
} else {
  Write-Err "Node.js $(node -v) is too old. Need ≥ 18"
}

# ── Clone repository ────────────────────────────────────────
if (Test-Path $InstallDir) {
  Write-Warn "$InstallDir already exists. Updating..."
  Push-Location $InstallDir
  try { git pull --ff-only 2>$null } catch { Write-Warn "Could not git pull — continuing with existing files" }
  Pop-Location
  Write-OK "Repository updated"
} else {
  Write-Log "Cloning into $InstallDir..."
  git clone --depth 1 https://github.com/EVEDensity/web-perf-audit.git $InstallDir
  Write-OK "Repository cloned"
}

Push-Location $InstallDir

# ── Install Node dependencies ───────────────────────────────
Write-Log "Installing Node.js dependencies..."

if (-not $SkipPuppeteer) {
  try { npm install 2>$null } catch { Write-Warn "npm install failed — try running manually: cd $InstallDir; npm install" }
  Write-OK "Puppeteer installed"
}

if (-not $SkipLighthouse) {
  $lhInstalled = Get-Command lighthouse -ErrorAction SilentlyContinue
  if ($lhInstalled) {
    Write-OK "Lighthouse CLI already installed"
  } else {
    Write-Log "Installing Lighthouse CLI..."
    try { npm install -g lighthouse 2>$null } catch { Write-Warn "Lighthouse install failed. Try: npm install -g lighthouse" }
    Write-OK "Lighthouse CLI installed"
  }
}

# ── Python check ────────────────────────────────────────────
Write-Log "Checking Python scripts..."
Get-ChildItem scripts\*.py | ForEach-Object {
  try { python -m py_compile $_.FullName 2>$null } catch { Write-Warn "Syntax error in $($_.Name)" }
}
Write-OK "Python scripts validated"

# ── PowerShell profile alias ────────────────────────────────
$profileDir = Split-Path $PROFILE -Parent
if (-not (Test-Path $profileDir)) {
  New-Item -ItemType Directory -Force -Path $profileDir | Out-Null
}

if (Test-Path $PROFILE) {
  $profileContent = Get-Content $PROFILE -Raw -ErrorAction SilentlyContinue
  if ($profileContent -notmatch "web-perf-audit") {
    Add-Content $PROFILE ""
    Add-Content $PROFILE "# web-perf-audit (added by install.ps1)"
    Add-Content $PROFILE "function perf-audit { python `"$InstallDir\scripts\fetch_metrics.py`" @args }"
    Add-Content $PROFILE "function perf-score { python `"$InstallDir\scripts\score_and_report.py`" @args }"
    Write-OK "Functions added to PowerShell profile"
  } else {
    Write-OK "Functions already present in PowerShell profile"
  }
} else {
  Write-Warn "PowerShell profile not found. Create one with: New-Item -Path `$PROFILE -Force"
}

Pop-Location

# ── Done ────────────────────────────────────────────────────
Write-Host ""
Write-Log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
Write-Log "  web-perf-audit installed! 🚀"
Write-Log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
Write-Host ""
Write-Log "  Quick start:"
Write-Log "    python $InstallDir\scripts\fetch_metrics.py https://example.com --output-dir .web-perf"
Write-Host ""
Write-Log "  Or use the function (restart your shell first):"
Write-Log "    perf-audit https://example.com"
Write-Host ""
Write-Log "  IDE plugins:"
Write-Log "    Claude Code:  /plugin install web-perf-audit@EVEDensity/web-perf-audit"
Write-Log "    Cursor:       Add '@web-perf-audit' to .cursorrules"
Write-Host ""
Write-Log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
