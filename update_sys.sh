#!/usr/bin/env bash
# System maintenance script — updates Homebrew & TeX Live packages

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
brew upgrade
echo "🧹 Cleaning up..."
brew cleanup

echo ""
echo "▸ TeX Live"
echo "────────────────────────────────────────"
echo "📦 Updating TeX Live Manager..."
sudo tlmgr update --self
echo "📚 Updating all packages..."
sudo tlmgr update --all

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✨ All updates complete!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
