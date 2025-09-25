#!/usr/bin/env bash
set -euo pipefail

# Reads the latest tag (current version); if not found, assumes 0.0.0
last_version=$(git describe --tags --abbrev=0 2>/dev/null || echo "0.0.0")
last_version="${last_version#v}"

major=$(echo "$last_version" | cut -d. -f1)
minor=$(echo "$last_version" | cut -d. -f2)
patch=$(echo "$last_version" | cut -d. -f3)

# Gathers all commits since the latest version
commits=$(git log "v${last_version}..HEAD" --pretty=format:%s || true)

breaking=0
feat=0
fix=0

while IFS= read -r msg; do
  if echo "$msg" | grep -q "BREAKING CHANGE"; then
    breaking=1
    break
  elif [ $feat -eq 0 ] && echo "$msg" | grep -qE "^feat(\(|:)" ; then
    feat=1
  elif [ $fix -eq 0 ] && echo "$msg" | grep -qE "^fix(\(|:)" ; then
    fix=1
  fi
done <<< "$commits"

if [[ $breaking -eq 1 ]]; then
  major=$((major + 1))
  minor=0
  patch=0
elif [[ $feat -eq 1 ]]; then
  minor=$((minor + 1))
  patch=0
elif [[ $fix -eq 1 ]]; then
  patch=$((patch + 1))
else
  echo "No relevant changes found, version will not be updated"
  echo "needs_rebuild=false" >> "$GITHUB_OUTPUT"
  echo "version=$last_version" >> "$GITHUB_OUTPUT"
  exit 0
fi

echo "needs_rebuild=true" >> "$GITHUB_OUTPUT"

new_version="${major}.${minor}.${patch}"

echo "New version: $new_version"

echo "version=$new_version" >> "$GITHUB_OUTPUT"
