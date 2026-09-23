#!/bin/sh
# runs before nginx starts (nginx image entrypoint hook)
# 1. create the shared git repo from /seed on first start
# 2. serve it over git:// so the framework can clone and push
# 3. keep /shared/site (the page) and /shared/specs (read-only spec mirror)
#    at the latest main, in the background
set -e
REPO=/shared/webapp.git
SITE=/shared/site
SPECS=/shared/specs

if [ ! -d "$REPO" ]; then
  echo "[webapp] seeding $REPO"
  git init -q --bare -b main "$REPO"
  tmp=$(mktemp -d)
  cp -r /seed/. "$tmp"
  git -C "$tmp" init -q -b main
  git -C "$tmp" add -A
  git -C "$tmp" -c user.name=seed -c user.email=seed@demo commit -qm "initial web app"
  git -C "$tmp" push -q "$REPO" main
  rm -rf "$tmp"
fi
git config --file "$REPO/config" daemon.receivepack true
# framework runs as uid 10001: it needs to create shared/framework and push to the repo
chmod a+rwX /shared
chmod -R a+rwX "$REPO"

git daemon --reuseaddr --export-all --enable=receive-pack --base-path=/shared /shared &

(
  last=""
  while true; do
    rev=$(git --git-dir="$REPO" rev-parse -q --verify main 2>/dev/null || true)
    if [ -n "$rev" ] && [ "$rev" != "$last" ]; then
      tmp=$(mktemp -d)
      git --git-dir="$REPO" archive main | tar -x -C "$tmp"
      # specs go to the host-visible mirror, never to the public site
      mkdir -p "$tmp/specs" "$SPECS"
      rsync -a --delete "$tmp/specs/" "$SPECS/"
      rm -rf "$tmp/specs" "$tmp/tests" "$tmp/test-results"  # not part of the public page
      git --git-dir="$REPO" log -1 --format='%h %s' main > "$tmp/.version"
      rsync -a --delete "$tmp/" "$SITE/"
      rm -rf "$tmp"
      echo "[webapp] now serving $(cat "$SITE/.version")"
      last="$rev"
    fi
    sleep 2
  done
) &
