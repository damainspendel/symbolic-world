#!/bin/bash

# The Symbolic World — knowledge-graph & Atlas management
# Build/deploy the web Atlas, run it as a launchd service (auto-start on reboot
# + auto-restart on crash), expose it through the Cloudflare tunnel, and run the
# graph integrity tests. Self-contained to this repo.
#
# Usage: ./manage.sh [command]

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WEB_DIR="$SCRIPT_DIR/web"

# The repo lives under ~/Documents, which macOS TCC privacy-protects — a
# background launchd agent has no access there and hangs on the protected path.
# So we BUILD in the repo but DEPLOY a copy to ~/Library and serve from there.
ATLAS_HOME="$HOME/Library/Application Support/SymbolicWorld"
ATLAS_PORT=8788
ATLAS_LABEL="org.symbolicworld.atlas"
ATLAS_PLIST="$HOME/Library/LaunchAgents/${ATLAS_LABEL}.plist"
ATLAS_LOG="$ATLAS_HOME/serve.log"

# Public exposure runs over the shared Cloudflare tunnel (the tunnel itself is
# owned by the Hexagram project; the Atlas is just one hostname on it). The
# tunnel is remotely-managed, so `expose` edits the REMOTE config via the API.
PUBLIC_HOST="symbolicworld.observer"
TUNNEL_ID="c3fa3fa3-10ab-4e9b-990f-305840738b08"
CF_ACCOUNT="32e42aa1d9315c7f157fa15f472e541e"
CF_CERT="$HOME/.cloudflared/cert.pem"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'
log()   { echo -e "${GREEN}[$(date +'%H:%M:%S')] $1${NC}"; }
warn()  { echo -e "${YELLOW}[WARN] $1${NC}"; }
error() { echo -e "${RED}[ERROR] $1${NC}"; exit 1; }
info()  { echo -e "${BLUE}[INFO] $1${NC}"; }

_domain() { echo "gui/$(id -u)"; }

# ── graph ───────────────────────────────────────────────────────────────────
# Run the integrity tests (every quote in-corpus, no undefined nodes, etc.).
graph_test() {
    log "Running graph integrity tests..."
    ( cd "$SCRIPT_DIR" && python3 tests/test_graph.py )
}

# ── build + deploy ──────────────────────────────────────────────────────────
# Rebuild the atlas from seed.json and deploy a copy to ATLAS_HOME.
build() {
    [ -d "$WEB_DIR" ] || error "web dir not found: $WEB_DIR"
    log "Running integrity tests (quotes, anchors, canaries) before build..."
    python3 "$SCRIPT_DIR/tests/test_graph.py" > /dev/null || error "integrity tests failed — build refused"
    python3 "$SCRIPT_DIR/tools/export_validations.py" > /dev/null 2>&1 || true
    log "Building the Atlas (npm run build regenerates atlas.json from seed.json)..."
    ( cd "$WEB_DIR" && npm run build ) || error "build failed"
    log "Deploying to $ATLAS_HOME (outside ~/Documents so launchd isn't blocked by TCC)..."
    mkdir -p "$ATLAS_HOME"
    rm -rf "$ATLAS_HOME/dist"
    cp -R "$WEB_DIR/dist" "$ATLAS_HOME/dist"
    cp "$WEB_DIR/serve.mjs" "$ATLAS_HOME/serve.mjs"
    log "Deployed -> $ATLAS_HOME/dist"
}

# One-shot: rebuild from current graph data and confirm the live site is healthy.
deploy() { build; health || true; }

# ── launchd service ─────────────────────────────────────────────────────────
_write_plist() {
    local node_bin; node_bin="$(command -v node)"
    [ -n "$node_bin" ] || error "node not found in PATH"
    [ -f "$ATLAS_HOME/serve.mjs" ] || error "serve.mjs not deployed — run: $0 build"
    mkdir -p "$ATLAS_HOME" "$(dirname "$ATLAS_PLIST")"
    cat > "$ATLAS_PLIST" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key><string>${ATLAS_LABEL}</string>
    <key>ProgramArguments</key>
    <array>
        <string>${node_bin}</string>
        <string>${ATLAS_HOME}/serve.mjs</string>
        <string>${ATLAS_PORT}</string>
    </array>
    <key>WorkingDirectory</key><string>${ATLAS_HOME}</string>
    <key>RunAtLoad</key><true/>
    <key>KeepAlive</key><true/>
    <key>StandardOutPath</key><string>${ATLAS_LOG}</string>
    <key>StandardErrorPath</key><string>${ATLAS_LOG}</string>
    <key>ProcessType</key><string>Background</string>
</dict>
</plist>
EOF
    log "Wrote launchd agent: $ATLAS_PLIST"
}

install() {
    [ -f "$ATLAS_HOME/serve.mjs" ] || build
    _write_plist
    launchctl bootout "$(_domain)/${ATLAS_LABEL}" 2>/dev/null || true
    launchctl bootstrap "$(_domain)" "$ATLAS_PLIST" || error "launchctl bootstrap failed"
    log "Installed — serving on :$ATLAS_PORT, starts on reboot, restarts if it dies"
    health || true
}

uninstall() {
    launchctl bootout "$(_domain)/${ATLAS_LABEL}" 2>/dev/null || true
    rm -f "$ATLAS_PLIST"
    log "Atlas agent removed"
}

start() {
    [ -f "$ATLAS_PLIST" ] || _write_plist
    launchctl bootstrap "$(_domain)" "$ATLAS_PLIST" 2>/dev/null \
        || launchctl kickstart "$(_domain)/${ATLAS_LABEL}"
    log "Atlas started on :$ATLAS_PORT"; health || true
}
stop()    { launchctl bootout "$(_domain)/${ATLAS_LABEL}" 2>/dev/null || true; log "Atlas stopped"; }
restart() { launchctl kickstart -k "$(_domain)/${ATLAS_LABEL}" 2>/dev/null || start; log "Atlas restarted"; health || true; }

status() {
    log "Atlas service status:"
    if launchctl print "$(_domain)/${ATLAS_LABEL}" >/dev/null 2>&1; then
        launchctl print "$(_domain)/${ATLAS_LABEL}" | grep -E "state =|pid =|program =" | sed 's/^[[:space:]]*/  /'
    else
        warn "Atlas agent is not loaded (run: $0 install)"
    fi
    health || true
    if curl -fsS --max-time 6 -o /dev/null "https://${PUBLIC_HOST}/" 2>/dev/null; then
        info "✓ Public: https://${PUBLIC_HOST} reachable"
    else
        warn "✗ Public: https://${PUBLIC_HOST} not reachable (tunnel down or not exposed?)"
    fi
}

health() {
    if curl -fsS --max-time 4 "http://localhost:${ATLAS_PORT}/" >/dev/null 2>&1; then
        info "✓ Atlas: healthy on http://localhost:${ATLAS_PORT}"; return 0
    else
        warn "✗ Atlas: not responding on :${ATLAS_PORT}"; return 1
    fi
}

logs() { tail -n "${1:-40}" "$ATLAS_LOG" 2>/dev/null || warn "no log at $ATLAS_LOG"; }

# Cron target: restart if the HTTP endpoint is unreachable (catches hangs that
# KeepAlive won't, since a hung process is still "alive").
monitor() {
    if health >/dev/null 2>&1; then info "Atlas OK"; else warn "Atlas down — restarting"; restart; fi
}
schedule_monitor() {
    local cmd="*/5 * * * * cd \"$SCRIPT_DIR\" && ./manage.sh monitor >> \"$SCRIPT_DIR/.atlas-monitor.log\" 2>&1"
    if crontab -l 2>/dev/null | grep -q "manage.sh monitor"; then warn "Monitor already scheduled"; return; fi
    (crontab -l 2>/dev/null; echo "$cmd") | crontab -
    log "Atlas monitor scheduled — every 5 minutes"
}
unschedule_monitor() {
    crontab -l 2>/dev/null | grep -q "manage.sh monitor" || { warn "No monitor scheduled"; return; }
    crontab -l 2>/dev/null | grep -v "manage.sh monitor" | crontab -
    log "Atlas monitor unscheduled"
}

# ── public exposure (remote-managed Cloudflare tunnel, via API) ──────────────
# Add PUBLIC_HOST -> localhost:ATLAS_PORT to the tunnel's REMOTE config. The
# tunnel is dashboard-managed, so editing ~/.cloudflared/config.yml has no
# effect — the config must be changed through the API.
expose() {
    local host="${1:-$PUBLIC_HOST}"
    [ -f "$CF_CERT" ] || error "cloudflared cert not found: $CF_CERT (run: cloudflared tunnel login)"
    log "Adding $host -> localhost:$ATLAS_PORT to the tunnel's remote config..."
    ATLAS_PORT="$ATLAS_PORT" CF_ACCOUNT="$CF_ACCOUNT" TUNNEL_ID="$TUNNEL_ID" CF_CERT="$CF_CERT" HOST="$host" python3 << 'PY'
import os, re, base64, json, urllib.request
tok=json.loads(base64.b64decode(re.sub(r'\s+','',re.search(r'TOKEN-----(.*?)-----END',open(os.environ['CF_CERT']).read(),re.S).group(1))))['apiToken']
acct=os.environ['CF_ACCOUNT']; tun=os.environ['TUNNEL_ID']; host=os.environ['HOST']; port=os.environ['ATLAS_PORT']
base="https://api.cloudflare.com/client/v4"; H={"Authorization":"Bearer "+tok,"Content-Type":"application/json"}
def req(p,m="GET",d=None):
    r=urllib.request.Request(base+p,headers=H,method=m,data=json.dumps(d).encode() if d else None)
    try: return json.loads(urllib.request.urlopen(r,timeout=20).read())
    except urllib.error.HTTPError as e: return json.loads(e.read())
cur=req(f"/accounts/{acct}/cfd_tunnel/{tun}/configurations")
if not cur.get('success'): raise SystemExit("cannot read tunnel config: %s"%cur.get('errors'))
cfg=cur['result']['config']; ing=cfg['ingress']
if any(r.get('hostname')==host for r in ing): print("already exposed"); raise SystemExit
idx=next(i for i,r in enumerate(ing) if not r.get('hostname'))
ing.insert(idx,{"hostname":host,"service":f"http://localhost:{port}","originRequest":{}})
out=req(f"/accounts/{acct}/cfd_tunnel/{tun}/configurations","PUT",{"config":cfg})
print("exposed" if out.get('success') else "FAILED: %s"%out.get('errors'))
PY
    info "DNS route (run once if not already): cloudflared tunnel route dns oi-misterbig $host"
}

open_site() { open "https://${PUBLIC_HOST}"; }

usage() {
    cat << EOF
The Symbolic World — knowledge-graph & Atlas management

Usage: $0 [command]

Graph:
  test                 Run graph integrity tests (tests/test_graph.py)

Build & deploy:
  build                Rebuild atlas from seed.json + deploy to ~/Library
  deploy               build, then health-check the live service

Website service (launchd — auto-start on reboot, auto-restart on crash):
  install / uninstall  Install / remove the launchd agent
  start / stop / restart
  status               Agent state + local + public health
  health               Local HTTP health probe
  logs [n]             Tail the server log
  monitor              Restart if unreachable (cron target)
  schedule-monitor / unschedule-monitor

Public exposure (Cloudflare tunnel):
  expose [host]        Add hostname to the tunnel's remote config (default: $PUBLIC_HOST)
  open                 Open https://$PUBLIC_HOST in the browser

Examples:
  $0 deploy            # push the current graph to the live site
  $0 status
EOF
}

case "${1:-}" in
    test) graph_test ;;
    build) build ;;
    deploy) deploy ;;
    install) install ;;
    uninstall) uninstall ;;
    start) start ;;
    stop) stop ;;
    restart) restart ;;
    status) status ;;
    health) health ;;
    logs) logs "$2" ;;
    monitor) monitor ;;
    schedule-monitor) schedule_monitor ;;
    unschedule-monitor) unschedule_monitor ;;
    expose) expose "$2" ;;
    open) open_site ;;
    help|--help|-h|"") usage ;;
    *) usage; exit 1 ;;
esac
