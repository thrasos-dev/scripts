#!/usr/bin/env bash
# System maintenance script — updates Homebrew, Claude Code & skills

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

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✨ All updates complete!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
