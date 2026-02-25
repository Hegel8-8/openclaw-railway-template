#!/bin/bash
set -e

# Auto-configure gateway and Steel browser profile
node -e "
const fs = require('fs');
const path = '/data/.openclaw/openclaw.json';
try {
  const config = JSON.parse(fs.readFileSync(path, 'utf8'));

  // Gateway config
  if (!config.gateway) config.gateway = {};
  if (!config.gateway.controlUi) config.gateway.controlUi = {};
  config.gateway.controlUi.dangerouslyDisableDeviceAuth = true;
  config.gateway.controlUi.allowedOrigins = ['https://openclaw-main-production-cb6d.up.railway.app'];

  // Steel browser profile
  const steelKey = process.env.STEEL_API_KEY;
  if (steelKey) {
    if (!config.browser) config.browser = {};
    if (!config.browser.profiles) config.browser.profiles = {};
    config.browser.profiles.steel = {
      cdpUrl: 'https://connect.steel.dev?apiKey=' + steelKey,
      color: '#336699'
    };
    console.log('[entrypoint] Steel browser profile configured');
  } else {
    console.log('[entrypoint] STEEL_API_KEY not found, skipping Steel profile');
  }

  fs.writeFileSync(path, JSON.stringify(config, null, 2));
  console.log('[entrypoint] Gateway config patched');
} catch(e) { console.log('[entrypoint] Config patch skipped:', e.message); }
"

# Fix volume permissions
chown -R openclaw:openclaw /data 2>/dev/null || true
chmod -R 755 /data 2>/dev/null || true

# Persist Homebrew to Railway volume so it survives container rebuilds
BREW_VOLUME="/data/.linuxbrew"
BREW_SYSTEM="/home/openclaw/.linuxbrew"

if [ -d "$BREW_VOLUME" ]; then
  if [ ! -L "$BREW_SYSTEM" ]; then
    rm -rf "$BREW_SYSTEM"
    ln -sf "$BREW_VOLUME" "$BREW_SYSTEM"
    echo "[entrypoint] Restored Homebrew from volume symlink"
  fi
else
  if [ -d "$BREW_SYSTEM" ] && [ ! -L "$BREW_SYSTEM" ]; then
    mv "$BREW_SYSTEM" "$BREW_VOLUME"
    ln -sf "$BREW_VOLUME" "$BREW_SYSTEM"
    echo "[entrypoint] Persisted Homebrew to volume on first boot"
  fi
fi

exec gosu openclaw node src/server.js
