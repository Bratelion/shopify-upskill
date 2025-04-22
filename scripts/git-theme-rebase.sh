#!/bin/bash
set -e

THEME_PATH="themes/dawn"
REBASE_BRANCH="theme"
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)

# Check if theme exists
if [[ ! -d "$THEME_PATH" ]]; then
  echo "❌ Theme directory '$THEME_PATH' not found. Aborting."
  exit 1
fi

echo "🔁 You are on branch: $CURRENT_BRANCH"
echo "💾 Stashing uncommitted theme changes (if any)..."
git add "$THEME_PATH"
git stash push -m "temp: theme rebase stash" || true

echo "🌐 Fetching live Shopify theme into temporary branch: $REBASE_BRANCH"
git checkout -B $REBASE_BRANCH

# Pull latest Shopify theme
yarn theme:pull

# Only commit if there are actual changes
if [[ -n $(git status --porcelain "$THEME_PATH") ]]; then
  git add "$THEME_PATH"
  git commit -m "Pull: latest Shopify theme on $(date '+%Y-%m-%d %H:%M:%S')"
else
  echo "⚠️  No changes from Shopify theme pull. Skipping commit."
fi

# Rebase feature branch onto latest theme
git checkout "$CURRENT_BRANCH"
git rebase "$REBASE_BRANCH"

# Clean up the "Pull: latest Shopify theme" commit if present
if git log -1 --pretty=%B | grep -q "Pull: latest Shopify theme"; then
  echo "🧹 Squashing theme pull commit from history..."
  git reset --soft HEAD~1
  echo "✅ Theme pull hidden — your branch remains clean."
fi

# Restore any stashed changes
git stash pop || echo "No stash to apply."

echo "✅ Theme rebase complete!"
