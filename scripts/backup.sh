#!/usr/bin/env bash
set -e

cd ~/noahk-dotfiles

git add .

echo "Checking status..."
git status --short

echo
read -p "Continue and back up? (y/N) " ans
[[ "$ans" == "y" ]] || exit 0

echo "Staging changes..."
git add -A

msg="backup: $(date '+%Y-%m-%d %H:%M')"
git commit -m "$msg" || echo "Nothing to commit"

echo "Pushing to GitHub..."
git push

echo "Backup complete"
