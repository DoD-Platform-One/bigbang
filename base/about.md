# About

_Author_: [`@razzle`](https://razzle.cloud)

## How it works

1. Add `bigbang` as a Git submodule.
1. Use `bigbang/chart/values.yaml` to pull in all the packages as submodules.
1. Use Git to list all of `bigbang`'s tagged versions.
1. Checkout that release of `bigbang`.
1. Use `bigbang/chart/values.yaml` as the source of truth for each package's version for that release.
1. Copy each packages' docs over using declarative config from `base/packages/<package>/config.yaml`.
1. Copy Big Bang's docs over, using `base/bigbang/config.yaml`.
1. Reformat Helm docs contained in the `README`s. Creates a separate `values.md` file that is accessible via site search.
1. Add certain tags to YAML frontmatter to aid in easier site search. Also patch in revision date back into page footer.
1. Build that version of the docs.
1. Repeat steps 4-9 for each version specified.

## Demo GIF

![Demo GIF](static/img/demo.gif)

## Comparisons to other tools

In my pursuit to write this, I did look at alternative build tools to MkDocs. The below contain a **subjective** comparison betweeen MkDocs and other static site generators.

!!! note

    It is worth noting that whichever tool I went with, I would also build the pre, and post build steps in whichever language the tool was written in. This would ensure maximum interop across the build process.

### Gatsby

_"Gatsby is the fast and flexible framework that makes building websites with any CMS, API, or database fun again. Build and deploy headless websites that drive more traffic, convert better, and earn more revenue!"[^1]_

Pros:

- Very mature plugin ecosystem
- React based, so very easy to extend (for me)
- Widely used as a docs static site generator

Cons:

- Personally, I have had some bad experiences with Gatsby and their design decisions / DX
- Too verbose / complex for simple sites

> **Verdict**: A large inspiration to this project was [Cloudflare's Developer Docs](https://developers.cloudflare.com/), which (formerly) used Gatsby in its [docs-engine](https://github.com/cloudflare/cloudflare-docs-engine). However, my past experiences with Gatsby, and the complexity that would be required to build a simple docs site, led me to look elsewhere.

### Hugo

_"Hugo is one of the most popular open-source static site generators. With its amazing speed and flexibility, Hugo makes building websites fun again."[^2]_

Pros:

- Fast (written in Go)
- Container already approved and in Iron Bank
- Powerful and versatile templating system

Cons:

- No good documentation themes (imo)
- Confusing naming conventions
- API has changed rapidly within last few months
- Go has a higher barrier to entry vs Python or JavaScript

> **Verdict**: While Hugo is insanely powerful, I don't think it fits this use case. I did not relish the idea of building my own docs site using Go templates, and would rather use a batteries included theme like Material, and tweak it to my liking.

### MkDocs

_"MkDocs is a fast, simple and downright gorgeous static site generator that's geared towards building project documentation. Documentation source files are written in Markdown, and configured with a single YAML configuration file."[^3]_

Pros:

- Written in Python (essentially no learning curve)
- Simple (single YAML file configuration)
- Material for Mkdocs theme is insanely good

Cons:

- Python is slower than Go/NodeJS so build times are longer
- Less configurable than building a site from scratch using Hugo/Gatsby

[^1]: https://www.gatsbyjs.org/
[^2]: https://gohugo.io/
[^3]: https://www.mkdocs.org/
