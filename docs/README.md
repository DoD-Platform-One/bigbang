# Big Bang Documentation Structure

_This file is intentionally excluded from .pages as an internal maintainer guidance document._

This directory is the source for the Big Bang documentation site. Treat it as a
docs-as-code project: Markdown files, directory names, and navigation files all
contribute to the published site.

This guide is for writers and reviewers who are adding, moving, or reorganizing
documentation.

The docs in this repository are compiled nightly using the [bb-docs-compiler repository](https://repo1.dso.mil/big-bang/team/tools/bb-docs-compiler) and a [compiler pipeline definition](https://repo1.dso.mil/big-bang/pipeline-templates/pipeline-templates/-/blob/master/pipelines/bigbang-docs.yaml).

## Core Concepts

### Pages and URLs

Each Markdown file under `docs/` is a documentation page. The file path usually
determines the page URL.

Examples:

| Source file | Expected page path |
| --- | --- |
| `docs/index.md` | `/` |
| `docs/configuration/gateways.md` | `/configuration/gateways/` |
| `docs/community/adrs/index.md` | `/community/adrs/` |
| `docs/community/adrs/0001-public-adrs.md` | `/community/adrs/0001-public-adrs/` |

An `index.md` file is the landing page for a directory. If a directory is used
as a documentation section, it should normally have an `index.md`.

### Navigation Files

Files named `.pages` define the sidebar order and labels for the files and
folders in the same directory.

Example:

```yaml
nav:
  - Overview: index.md
  - Community: community
  - Concepts: concepts
  - Configuration: configuration
```

In this example:

- `Overview` is the display label.
- `index.md` is the file path.
- `Community` is the display label.
- `community` is the directory path.

The label before the colon does not create a file or directory. Creating a
directory named `Overview` only makes sense if the intended URL section is
actually `/overview/`.

### Directory Sections

When a parent `.pages` file points to a directory, that directory should be a
real documentation section.

Example from `docs/.pages`:

```yaml
nav:
  - Getting Started: getting-started
```

This means the site expects a `docs/getting-started/` section. That section
should have:

- `docs/getting-started/index.md` as its landing page.
- `docs/getting-started/.pages` to order pages inside the section.
- Any additional pages listed in `docs/getting-started/.pages`.

Do not keep both a section directory and a same-named top-level page unless the
site intentionally needs both URLs. For example, having both
`docs/getting-started.md` and `docs/getting-started/` is usually confusing.

## Big Bang Conventions

Follow these conventions unless the docs maintainers agree to a different
structure.

- Every public Markdown page should be represented in the `.pages` file for its
  immediate directory. Exceptions, e.g. internal maintainer documentation, should be noted in those files and excluded from `.pages`.
- Every public documentation section should have an `index.md`.
- A directory with multiple public pages should have its own `.pages` file.
- The display label in `.pages` should be human-friendly; the path after the
  colon must match the actual file or directory name.
- File and directory names should be lowercase and hyphenated where practical.
- Do not create folders only to group labels. Create folders only when a new URL
  section is intended.
- Keep reference assets, scripts, and config examples under `docs/reference/`.
  If reference Markdown pages should be visible in the site, add appropriate
  `index.md` and `.pages` files for that section.

## Linking Rules

Markdown links are relative to the file they appear in.

Examples from `docs/getting-started/index.md`:

```markdown
[Prerequisites](prerequisites.md)
[Installation](../installation/)
[Configuration](../configuration/)
```

Examples from `docs/index.md`:

```markdown
[Getting Started](getting-started/)
[Configuration](configuration/)
[What is Big Bang?](what.md)
```

Use these rules when writing links:

- Link to a page in the same directory with `page-name.md`.
- Link to a sibling section with `../section-name/` from a nested page.
- Link to a root-level section with `section-name/` from `docs/index.md` or
  another root-level page.
- Link to directories only when the target directory has an `index.md`.
- Recheck every relative link after moving a file, because `./` and `../`
  change meaning when the file location changes.

## Moving or Adding a Page

Use this checklist before opening a merge request.

1. Decide the intended section and URL.
2. Place the Markdown file in the matching directory.
3. If the page is the section landing page, name it `index.md`.
4. Add the page to the `.pages` file in the same directory.
5. If you add a new directory section, add that directory to the parent
   `.pages` file.
6. If the new directory has public Markdown pages, add an `index.md` and a
   `.pages` file inside it.
7. Update links inside the moved file.
8. Search for inbound links to the old location and update them.
9. Run the review checks below.

## Review Checks

These commands are useful before asking for review.

List Markdown files:

```shell
rg --files docs -g '*.md'
```

List navigation files:

```shell
find docs -name .pages -print
```

Search for links that may need review:

```shell
rg -n '\]\([^)]+\)' docs -g '*.md'
```

Search for references to a moved page:

```shell
rg -n 'old-file-name|old/path' docs
```

After reorganizing docs, reviewers should verify:

- No `.pages` entry points to a missing file or directory.
- No public Markdown file is accidentally omitted from navigation.
- Directory links target directories that have `index.md`.
- Relative links still resolve from the file they are written in.
- Renamed or moved pages have no stale inbound links.

## Common Fix Patterns

### A Section Has a `.pages` Entry but No `index.md`

Problem:

```yaml
nav:
  - Getting Started: getting-started
```

but `docs/getting-started/index.md` does not exist.

Fix:

- Move the section overview content to `docs/getting-started/index.md`.
- Keep `docs/getting-started/.pages` pointing to `index.md`.
- Update links from `getting-started.md` to `getting-started/` or
  `getting-started/index.md`.

### A `.pages` Entry Uses the Wrong Filename

Problem:

```yaml
nav:
  - Fluent Bit: fluent-bit.md
```

but the actual file is `fluentbit.md`.

Fix one of the following:

- Rename the file to `fluent-bit.md` and update inbound links.
- Update `.pages` to point to `fluentbit.md`.

Choose the option that best matches the repo's naming convention and existing
links.

### A Page Exists but Is Missing from Navigation

Problem:

```text
docs/configuration/ambient.md
```

exists, but `docs/configuration/.pages` does not list it.

Fix:

```yaml
nav:
  - Overview: index.md
  - Ambient: ambient.md
```

Place the new entry where it belongs in the section order.

## Writer and Engineer Responsibilities

Technical writers working in this repository should be comfortable with:

- Markdown.
- Directory-based documentation structure.
- `index.md` landing pages.
- `.pages` navigation files.
- Relative Markdown links.
- Searching for stale links after moving content.

Engineers should generally own:

- Site build tooling.
- CI link-check configuration.
- Theme or plugin behavior.
- Redirects and automation.

For normal content reorganization, the expected workflow is that writers update
the Markdown files, `.pages` files, and links together.

## Further Reading

- MkDocs writing guide: <https://www.mkdocs.org/user-guide/writing-your-docs/>
- MkDocs Awesome Pages plugin: <https://pypi.org/project/mkdocs-awesome-pages-plugin/>
- GitHub relative links in Markdown: <https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/customizing-your-repository/about-readmes#relative-links-and-image-paths-in-markdown-files>
- Write the Docs, Docs as Code: <https://www.writethedocs.org/guide/docs-as-code/>
