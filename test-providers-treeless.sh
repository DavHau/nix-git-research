#!/usr/bin/env bash
set -euo pipefail

declare -a repos=(
  "https://github.com/nixos/nixpkgs"            # github
  "https://gitlab.com/tomatocream/nixpkgs"      # gitlab
  "https://bitbucket.org/davhau/nixpkgs"        # bitbucket
  "https://git.clan.lol/DavHau/nixpkgs"         # gitea
)

# set a default for workdir
WORKDIR=${WORKDIR:-/tmp/nix-git-benchmark}

echo "Git version: $(git --version)"
echo "date: $(date)"
csvFile="$WORKDIR/result.csv"
GITDIR="$WORKDIR/repo"
mkdir -p "$WORKDIR"
echo "repo,shallow duration,treeless duration,combined duration" > "$csvFile"

writeCsv() {
  echo "$1,$2,$3,$4" >> "$csvFile"
}

for repo in "${repos[@]}"; do
  echo "Running benchmark on $repo"
  # get latest revision
  rev=$(git ls-remote "$repo" HEAD | head -n 1 | cut -f1)
  echo "rev: $rev"
  rm -rf "$GITDIR"
  mkdir -p "$GITDIR"
  cd "$GITDIR"
  git init
  git remote add origin "$repo"

  echo "Fetching tree for $rev with --depth 1"
  start=$(date +%s%N)
  if git fetch origin "$rev" --depth 1; then
    shallowDuration=$((($(date +%s%N) - $start)/1000000000))
    echo Fetching tree took $shallowDuration seconds.
  else
    echo "Fetching tree failed"
    writeCsv "$repo" failed failed failed
    continue
  fi

  echo "Fetching treeless history for $rev with --filter=tree:0"
  start=$(date +%s%N)
  if git fetch origin $rev --filter=tree:0 --unshallow; then
    treelessDuration=$((($(date +%s%N) - $start)/1000000000))
    echo Fetching treeless history took $treelessDuration seconds.
    revCount=$(git rev-list --count "$rev")
    echo "revCount: $revCount"
    # error if revCount is lower than 2
    if [ "$revCount" -lt 2 ]; then
      echo "revCount is lower than 2"
      exit 1
    fi
  else
    echo "Fetching treeless history failed"
    writeCsv "$repo" "$shallowDuration" failed failed
  fi

  # write results to csv file
  writeCsv "$repo" "$shallowDuration" "$treelessDuration" "$((shallowDuration + treelessDuration))"
done

