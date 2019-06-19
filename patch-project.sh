#!/bin/bash -e

FORKMAN_CONFIG="$1"
FORKMAN_REPO="$2"
FORKMAN_UPSTREAM_BRANCH="$3"
FORKMAN_MAIN_BRANCH="${4:-forkman-raw}"
FORKMAN_PATCH_BRANCH="forkman-$(date +%F)"

if [ $# -eq 0 ]; then
    echo "Usage: $0 FORKMAN-CONFIG FORKMAN-REPO FORKMAN-UPSTREAM-BRANCH [FORKMAN-MAIN-BRANCH]"
    echo "FORKMAN-CONFIG: path to yaml config with replacement dictionary"
    echo "FORKMAN-REPO: path to repo you're going to patch"
    echo "FORKMAN-UPSTREAM-BRANCH: which upstream branch to patch"
    echo "FORKMAN-MAIN-BRANCH: which local branch should receieve patches. Default master"
    exit 1
fi

if [ ! -f "$FORKMAN_CONFIG" ]; then
   echo "Config was not found: $FORKMAN_CONFIG"
   exit 1
fi

if [ ! -d "$FORKMAN_REPO/.git" ]; then
    echo "Git repository was not found: $FORKMAN_REPO"
    exit 1
fi

if [ -z "$FORKMAN_UPSTREAM_BRANCH" ]; then
    echo "Upstream branch should not be empty"
    echo "Usually it should look like upstream/master"
    exit 1
fi

echo "WARN: Resseting index and HEAD. Press enter to continue or CTRL+C to abort"
read

pushd "$FORKMAN_REPO" > /dev/null

echo "Resetting index and cleaning"
git reset --hard HEAD
git clean -fdx

# echo "Making patch branch: $FORKMAN_PATCH_BRANCH"
git checkout -B "$FORKMAN_PATCH_BRANCH" "$FORKMAN_UPSTREAM_BRANCH"

popd > /dev/null

echo "Applying forkman:"
ruby forkman.rb --config "$FORKMAN_CONFIG" --repo "$FORKMAN_REPO"
# ruby forkman.rb --config "$FORKMAN_CONFIG" --repo "$FORKMAN_REPO" --preserve-tokens --steps 105

pushd "$FORKMAN_REPO" > /dev/null

echo "Rework patches on main branch: $FORKMAN_MAIN_BRANCH"
echo "WARN: This branch is expected to keep clean and raw"
git reset "$FORKMAN_MAIN_BRANCH"

echo "We are on clean state so safe to add literally everything"
git add .

git commit -m "Backport $FORKMAN_UPSTREAM_BRANCH at $(git rev-parse "$FORKMAN_UPSTREAM_BRANCH")"
git checkout "$FORKMAN_MAIN_BRANCH"

# Should be always fast-forward
git merge --ff-only "$FORKMAN_PATCH_BRANCH"
git branch -D "$FORKMAN_PATCH_BRANCH"

popd > /dev/null

echo "$FORKMAN_MAIN_BRANCH was built."
