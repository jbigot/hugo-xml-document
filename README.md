<!--
SPDX-FileCopyrightText: 2026 Julien Bigot <julien@julien-bigot.fr>
SPDX-License-Identifier: MIT
-->

# hugo-xml-document

A Hugo module that reads an XML resource into a tree of plain maps and lists, on every Hugo
release from 0.169, with mixed content kept.

`transform.Unmarshal`'s default XML layout drops mixed content (text interleaved with
elements). [gohugoio/hugo#15485](https://github.com/gohugoio/hugo/issues/15485) proposes a
`targetType: document` layout that keeps it, not merged yet. This module gives that layout
today: it uses the native decoder when your Hugo has it, and a reader written in templates
otherwise, with the same result.

## Usage

Import the module in your site's configuration:

```yaml
module:
  imports:
    - path: github.com/jbigot/hugo-xml-document
```

and read a resource:

```go-html-template
{{ $root := partial "xmldoc/unmarshal.html" (resources.Get "doc.xml") }}
```

`$root` is the root element as `{tag, attributes, children}`: `attributes` maps names to strings,
`children` holds strings and elements. Names lose their prefix, as in Go's `encoding/xml`.
An empty resource gives an empty map. Malformed XML stops the build. The result is cached per
resource, and a `hugo server` rebuild re-parses only the files that changed.

The partials `xmldoc/read.html` (the template reader) and `xmldoc/native.html` (whether this
Hugo has the native decoder) are internals; only `xmldoc/unmarshal.html` is public.

## Tests

`sh tests/run.sh` compares the tree of every file of `tests/corpus/` and `tests/edge/good/` with
expat's, and checks that the files of `tests/edge/bad/` fail the build. Pass `NAME=DIR` to compare
the XML files of a directory too. `READER=unmarshal` checks the native decoder instead of the
template reader, `sh tests/rebuild.sh` that a `hugo server` rebuild re-parses only what changed.
[tests/known-differences.md](tests/known-differences.md) lists where the readers differ from
expat. The tests use the Hugo binary in `HUGO`; without it, they build the `docsygen-native`
branch of the Hugo checkout in `HUGO_SRC` (default: `hugo/` next to this repository).

## License

MIT. Files that come from elsewhere keep their own license; check with `reuse lint`.
