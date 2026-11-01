# SPDX-FileCopyrightText: 2026 Julien Bigot <julien@julien-bigot.fr>
# SPDX-License-Identifier: MIT
# Shared by the test scripts, which source it: . "$(dirname "$0")/lib.sh"
# It sets:
#   root  the repository root
#   hugo  the Hugo binary: HUGO, else the Hugo fork's docsygen-native (native_hugo)
#   tmp   a scratch directory, removed on exit unless XMLDOC_KEEP is set (a script that sets its
#         own EXIT trap removes it)
# It defines native_hugo and site_config, below.

root=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
tmp=$(mktemp -d)
if [ -n "${XMLDOC_KEEP:-}" ]; then echo "lib.sh: keeping $tmp" >&2; else trap 'rm -rf "$tmp"' EXIT; fi

# native_hugo: print the path of the Hugo fork's binary, the one that has the native decoder of
# gohugoio/hugo#15485. HUGO_SRC is the fork (default: the hugo directory next to this
# repository). Its branch docsygen-native is built into /tmp/docsygen-hugo-doc/<commit>/hugo when
# that is missing (the binary docsygen's tests use too), then Go's build cache is cleaned.
native_hugo() {
  src=${HUGO_SRC:-$(dirname "$root")/hugo}
  commit=$(git -C "$src" rev-parse --short=9 docsygen-native) || return 1
  bin=/tmp/docsygen-hugo-doc/$commit/hugo
  if [ ! -x "$bin" ]; then
    echo "lib.sh: building docsygen-native ($commit) into $bin" >&2
    git -C "$src" worktree add -q -d "$tmp/hugo-src" "$commit" >&2 || return 1
    mkdir -p "$(dirname "$bin")"
    built=0
    (cd "$tmp/hugo-src" && CGO_ENABLED=1 go build -o "$bin.new" .) >&2 && built=1
    git -C "$src" worktree remove --force "$tmp/hugo-src"
    go clean -cache >&2
    [ $built -eq 1 ] || { echo "lib.sh: the build of docsygen-native failed" >&2; return 1; }
    mv "$bin.new" "$bin"
  fi
  printf '%s\n' "$bin"
}
if [ -n "${HUGO:-}" ]; then hugo=$HUGO; else hugo=$(native_hugo) || exit 1; fi

# site_config FILE [SOURCE=TARGET ...]: write to FILE the module configuration of a test site
# that imports this module from this repository. Each SOURCE (absolute, or relative to the site)
# is mounted at TARGET; project mounts replace the site's default ones. Append the rest of the
# configuration to FILE.
site_config() {
  config=$1; shift
  {
    printf 'module:\n'
    printf '  replacements: "github.com/jbigot/hugo-xml-document -> %s"\n' "$root"
    printf '  imports:\n    - path: github.com/jbigot/hugo-xml-document\n'
    if [ $# -gt 0 ]; then
      printf '  mounts:\n'
      for mount in "$@"; do
        printf '    - {source: "%s", target: "%s"}\n' "${mount%%=*}" "${mount#*=}"
      done
    fi
  } > "$config"
}
