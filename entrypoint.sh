#!/bin/bash
set -e

node -e "
const fs = require('fs');
const p = '/data/.openclaw/openclaw.json';
try {
  const c = JSON.parse(fs.readFileSync(p, 'utf8'));
  if (!c.gateway) c.gateway = {};
  if (!c.gateway.controlUi) c.gateway.controlUi = {};
  c.gateway.controlUi.dangerouslyDisableDeviceAuth = true;
  c.gateway.controlUi.allowedOrigins = ['https://openclaw-main-production-cb6d.up.railway.app'];
  if (!c.agents) c.agents = {};
  if (!c.agents.defaults) c.agents.defaults = {};
  if (!c.agents.defaults.model) c.agents.defaults.model = {};
  c.agents.defaults.model.primary = 'google/gemini-3-pro-preview';
  c.agents.defaults.model.fallback = 'anthropic/claude-sonnet-4-6';
  const k = process.env.STEEL_API_KEY;
  if (k) {
    if (!c.browser) c.browser = {};
    if (!c.browser.profiles) c.browser.profiles = {};
    c.browser.profiles.steel = { cdpUrl: 'https://connect.steel.dev?apiKey=' + k, color: '#336699' };
  }
  fs.writeFileSync(p, JSON.stringify(c, null, 2));
  console.log('[entrypoint] Config patched');
} catch(e) { console.log('[entrypoint] patch skipped:', e.message); }
"

chown -R openclaw:openclaw /data 2>/dev/null || true
chmod -R 755 /data 2>/dev/null || true

BREW_VOLUME="/data/.linuxbrew"
BREW_SYSTEM="/home/openclaw/.linuxbrew"

if [ -d "$BREW_VOLUME" ]; then
  if [ ! -L "$BREW_SYSTEM" ]; then
    rm -rf "$BREW_SYSTEM"
    ln -sf "$BREW_VOLUME" "$BREW_SYSTEM"
  fi
else
  if [ -d "$BREW_SYSTEM" ] && [ ! -L "$BREW_SYSTEM" ]; then
    mv "$BREW_SYSTEM" "$BREW_VOLUME"
    ln -sf "$BREW_VOLUME" "$BREW_SYSTEM"
  fi
fi

exec gosu openclaw node src/server.js
