# ForkMan

This script helps you to refactor whole repositories by replacing all tokens using a user defined dictionary.

## ORDER

**Dictionary order is important!**

## How it works

It uses the provided dictionary and replaces each occurance of `term` with unique `token` with each file name and file content. Then it replaces `token` with new `term`.

This helps to modify or keep unmodified content from the most unique `term` (better match) to general pattern.

## Why not just sed?

consider the following example:

``` text
I want to preserve original site: www.habitat.sh
But replace this habitat with new name
And use new hab binary
```

And we have the following naive dictionary:

``` text
www.habitat.sh -> www.habitat.sh (I want to preserve this)
habitat -> biome
hab -> bio
```

You'll get wrong site:

``` text
I want to preserve original site: www.biome.sh
But replace this biome with new name
And use new bio binary
```

# Usage Example

The script [forkman-patch-git](forkman-patch-git) shows how it is possible to make a "hard-update" of new changes.

It reverts local changes, so you should be careful. It takes `FORKMAN-UPSTREAM-BRANCH` branch and applies `forkman`. Then it resets to `FORKMAN_MAIN_BRANCH`, adds everything and commits.

This emulates "manual project refactoring". If you satisfied with result you can merge this to your branch (or master).

# Full example

First ensure that you have forked the repository you want to operate on. (Eg: Fork habitat-sh/habitat to biome-sh/biome)

Clone a repository:

```
git clone https://github.com/biome-sh/biome.git
```

Add an upstream repository:

```
cd biome
git remote add habitat https://github.com/habitat-sh/habitat.git
git remote update
```

Create translate dictionary `.forkman.yaml`. If you create file directly in repository, make sure you commit changes, because `forkman-patch-git` reverts all local changes. For experiments, you can keep config somewhere outside for a while:

```
cat <<EOF > .forkman.yaml
---

patterns:
  pattern1: replacement1
  pattern2: replacement2
  pattern3: replacement3

deletes:
  - any
  - files
  - you
  - want
  - to
  - delete

excludes:
  - files
  - you
  - dont
  - want
  - to
  - patch

EOF
```

Create a `forkman-raw` branch:

```
git branch forkman-raw habitat/master
git push origin forkman-raw
```

Install `forkman` using native way:

```
# install ruby
gem install bundler
bundle install
```

or via `habitat`/`biome`:

```
# Habitat
sudo hab pkg install -fb jsirex/forkman

# Biome
sudo bio pkg install -fb jsirex/forkman
```

Run patches:

```
forkman-patch-git -u habitat/master
```

# Tip

First patch on existing project will be huge and requires lots of your attention, but if you're using `forkman-patch-git` any further run will show only diffs related to a new code or dictionary changes.
