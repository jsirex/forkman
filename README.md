# ForkMan

This script helps you to refactor whole repositories by replacing all tokens using user defined dictionary.

# How it works

It uses provided dictionary and replaces each occurance of `term` with uniq `token` with each file name and file content. Then it replaces `token` with new `term`.
This helps to modify or keep unmodified content from the most uniq `term` (better match) to general pattern.

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

# ORDER

**Dictionary order is important!**
