#!/usr/bin/env bash
# System maintenance script — updates Homebrew, Claude Code, skills & the container engine

set -e

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🚀 System Update & Maintenance"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

echo "▸ Homebrew"
echo "────────────────────────────────────────"
echo "🍺 Updating Homebrew..."
brew update
echo "⬆️  Upgrading packages..."
brew upgrade --yes
echo "🧹 Cleaning up..."
brew cleanup

echo "▸ Claude Code"
echo "────────────────────────────────────────"
echo "🤖 Updating Claude Code..."
claude update

echo "▸ Skills"
echo "────────────────────────────────────────"
echo "📦 Updating skills..."
npx skills update -g

# ── The container engine ─────────────────────────────────────────────────────
# socktainer serves Docker's API on top of Apple's `container`. Neither comes
# from Homebrew, whose build of `container` keeps only one container network
# up. Notes: ~/repos/web/rantevo/docs/development.md § The container engine.

CONTAINER="/usr/local/bin/container" # Apple's signed package
SOCKTAINER="$HOME/.local/bin/socktainer"
SOCKTAINER_AGENT="com.rantevo.socktainer"
SOCKTAINER_TEAM="HYSCB8KRL2" # Red Hat's Developer ID, which signs the releases
ENGINE_CHANGED=""

# True when version $1 is newer than version $2.
newer() {
  [ "$1" != "$2" ] && [ "$(printf '%s\n%s\n' "$1" "$2" | sort -V | tail -1)" = "$1" ]
}

# Replace the binary with the latest release's and restart its agent.
# Containers that are running keep running across the restart.
update_socktainer() {
  local release latest installed url digest dir
  release=$(curl -fsSL https://api.github.com/repos/socktainer/socktainer/releases/latest) || return 1
  latest=$(jq -r '.tag_name // empty' <<<"$release")
  [ -n "$latest" ] || return 1
  installed=$("$SOCKTAINER" --version | awk '{print $2}')
  if ! newer "${latest#v}" "${installed#v}"; then
    echo "✅ socktainer $installed is up to date."
    return 0
  fi

  echo "⬆️  socktainer $installed → $latest"
  url=$(jq -r '.assets[] | select(.name == "socktainer") | .browser_download_url' <<<"$release")
  digest=$(jq -r '.assets[] | select(.name == "socktainer") | .digest // empty' <<<"$release")
  dir=$(mktemp -d)
  curl -fSL --progress-bar "$url" -o "$dir/socktainer" || { rm -rf "$dir"; return 1; }
  # It has to match the release's checksum and carry the publisher's signature.
  if [ -n "$digest" ] && [ "sha256:$(shasum -a 256 "$dir/socktainer" | cut -d' ' -f1)" != "$digest" ]; then
    echo "❌ The download does not match the release's checksum."
    rm -rf "$dir"
    return 1
  fi
  if ! codesign --verify --strict "$dir/socktainer" 2>/dev/null ||
    [ "$(codesign -dv "$dir/socktainer" 2>&1 | sed -nE 's/^TeamIdentifier=//p')" != "$SOCKTAINER_TEAM" ]; then
    echo "❌ The download is not signed by socktainer's publisher."
    rm -rf "$dir"
    return 1
  fi
  install -m 755 "$dir/socktainer" "$SOCKTAINER" || { rm -rf "$dir"; return 1; }
  rm -rf "$dir"
  ENGINE_CHANGED=1
  launchctl kickstart -k "gui/$(id -u)/$SOCKTAINER_AGENT" || true
}

# Load socktainer's agent again, which starts it.
load_socktainer() {
  launchctl bootstrap "gui/$(id -u)" "$HOME/Library/LaunchAgents/$SOCKTAINER_AGENT.plist" 2>/dev/null || true
}

# Move Apple's `container` to the version socktainer is built for, never past
# it: socktainer only warns about another version, it does not support one.
update_container() {
  local installed tag built_for latest status=0
  installed=$("$CONTAINER" --version | awk '{print $4}')
  tag=$("$SOCKTAINER" --version | awk '{print $2}')
  built_for=$(curl -fsSL "https://raw.githubusercontent.com/socktainer/socktainer/$tag/Package.swift" |
    sed -nE 's/.*apple\/container\.git", exact: "([0-9.]+)".*/\1/p' | head -1)
  if [ -z "$built_for" ]; then
    echo "❌ Could not read which container version socktainer $tag is built for."
    return 1
  fi
  if ! newer "$built_for" "$installed"; then
    latest=$(curl -fsSL https://api.github.com/repos/apple/container/releases/latest | jq -r '.tag_name // empty')
    if [ -n "$latest" ] && newer "$latest" "$installed"; then
      echo "⏸  container $latest is out, but socktainer $tag is built for $built_for. Staying on $installed."
    else
      echo "✅ container $installed is up to date."
    fi
    return 0
  fi
  if [ -n "$("$CONTAINER" ls --quiet 2>/dev/null)" ]; then
    echo "⏸  container $built_for is ready to install, but containers are running."
    echo "   Stop them (\`pnpm dev:local --stop\` in rantevo) and run this again."
    return 0
  fi

  echo "⬆️  container $installed → $built_for (asks for your password)"
  # Apple's script refuses while the service runs, and socktainer would start
  # it again, so socktainer is unloaded for the update and loaded afterwards,
  # also when the update is interrupted.
  trap 'load_socktainer; exit 130' INT TERM
  launchctl bootout "gui/$(id -u)/$SOCKTAINER_AGENT" 2>/dev/null || true
  "$CONTAINER" system stop >/dev/null 2>&1 || true
  /usr/local/bin/update-container.sh -v "$built_for" || status=1
  load_socktainer
  trap - INT TERM
  ENGINE_CHANGED=1
  return $status
}

if [ -x "$SOCKTAINER" ] && [ -x "$CONTAINER" ]; then
  echo "▸ Containers"
  echo "────────────────────────────────────────"
  echo "🚢 Updating socktainer and Apple container..."
  update_socktainer || echo "⚠️  socktainer was not updated."
  update_container || echo "⚠️  Apple container was not updated."
  if [ -n "$ENGINE_CHANGED" ]; then
    # socktainer starts container's service itself; give it a moment.
    for i in $(seq 1 30); do
      docker --context socktainer info >/dev/null 2>&1 && break
      sleep 1
    done
    if docker --context socktainer info >/dev/null 2>&1; then
      echo "✅ The container engine answers."
    else
      echo "⚠️  The container engine is not answering."
      echo "   Notes: ~/repos/web/rantevo/docs/development.md § The container engine"
    fi
  fi
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✨ All updates complete!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
