# Documentation Review Tools

Tools to identify and manage potentially outdated markdown documentation across BigBang GitLab projects.

## Prerequisites

- **glab** - GitLab CLI (authenticated)
- **jq** - JSON processor

## Tools

### 1. doc-review.sh - Create Documentation Review Issues

Scans for outdated markdown files and creates tracking issues.

```bash
./doc-review.sh [OPTIONS]
```

### Options

| Flag | Description | Default |
|------|-------------|---------|
| `-t, --time MONTHS` | Files older than MONTHS | 6 |
| `-c, --count NUMBER` | Max files to check, or "all" | all |
| `-i, --input FILE` | Use existing scan results JSON (skip scan) | - |
| `-d, --dry-run` | Preview mode - shows what would happen | false |
| `--team TEAM` | Filter by team name | all |
| `--epic EPIC_IID` | Add created issues to specified epic | none |
| `--ignore-commit SHA` | Ignore commit when determining file age (repeatable) | none |
| `-h, --help` | Show help | - |

### Project Selection

Specify which projects/groups to scan. If none specified, all are scanned.

| Flag | Description |
|------|-------------|
| `--packages` | Scan `big-bang/product/packages` |
| `--maintained` | Scan `big-bang/product/maintained` |
| `--sandbox` | Scan `big-bang/apps/sandbox` |
| `--umbrella` | Scan `big-bang/bigbang` (umbrella project) |

You can combine multiple flags: `--packages --maintained`

## Examples

```bash
# Dry run - preview what would be created (all projects)
./doc-review.sh -d

# Scan only umbrella project
./doc-review.sh --umbrella -d --epic 495

# Scan packages and maintained only
./doc-review.sh --packages --maintained -d

# Find files older than 12 months, create issues, add to epic 495
./doc-review.sh -t 12 --epic 495

# Dry run with epic
./doc-review.sh -d --epic 495

# Use existing scan results (skip scanning phase)
./doc-review.sh -i old_markdown_20251217.json -d --epic 495

# Create issues from existing scan
./doc-review.sh -i old_markdown.json --epic 495

# Dry run for specific team
./doc-review.sh -d --team service_mesh

# Ignore a refactor commit when determining file age
./doc-review.sh --umbrella -d --ignore-commit da91e59f

# Ignore multiple commits
./doc-review.sh --umbrella -d --ignore-commit da91e59f --ignore-commit abc123
```

## Features

### Issue Grouping by Project Type

| Project | Issue Creation |
|---------|----------------|
| Packages, Maintained, Sandbox | **1 issue per file** |
| Umbrella (bigbang) | **1 issue per directory** (groups all files in each directory) |

This reduces backlog clutter for the umbrella project which has many nested directories.

**Example umbrella directory issue:**
```
Title: Documentation Review Needed for docs/guides/
Description:
  - [ ] getting-started.md - Last modified: 2024-01-15 (11 months ago)
  - [ ] installation.md - Last modified: 2024-02-20 (10 months ago)
  - [ ] upgrade.md - Last modified: 2024-03-10 (9 months ago)
```

### Input File Mode (`-i, --input`)

Skip the scanning phase and use existing scan results:
- Useful for retrying failed runs
- Allows reviewing scan results before creating issues
- Works with dry-run mode
- **Project flags still apply**: Use `--umbrella`, `--packages`, etc. to filter the input file

### Idempotent Operation

Safe to run multiple times:
- **Duplicate detection**: Skips issues that already exist (checks by title)
- **Epic membership check**: Won't re-add issues already in the epic
- Existing issues can still be added to an epic if not previously added

### Dry Run Mode (`-d`)

Shows exactly what would happen without making changes:
- Lists all files/directories that would have issues created
- Shows which issues already exist
- Shows which issues would be added to the epic
- Outputs scan results JSON for review

### Optional Epic (`--epic`)

- Without `--epic`: Creates issues only
- With `--epic 495`: Creates issues AND adds them to epic #495

### Ignore Commits (`--ignore-commit`)

Skip specific commits when determining file age (useful for refactor/reorganization commits):
- Pass short or full SHA: `--ignore-commit da91e59f`
- Can be used multiple times for multiple commits
- When a file's last commit matches an ignored SHA, the script looks back in history for the actual last content update

**Example:** If a file was reorganized on Nov 25 but last updated on July 24, ignoring the reorg commit will show July 24 as the real age.

## Automatic Exclusions

The scanner skips:
- Files in `chart/` directories (package charts)
- Files in `blog/` directories (point-in-time content)
- Files in `adr/` or `ADR/` directories (Architecture Decision Records)

These exclusions apply to both scanning and input file filtering.

## Issue Details

Created issues include:
- **Labels:** `kind::docs`, `priority::3`, and team label (if mapped)
- **Weight:** 1 for single-file issues, N for directory issues (N = file count)
- **Description:** Link to file(s), last modified date, epic reference (if applicable)

## Output Files

| File Pattern | Description | When Created |
|--------------|-------------|--------------|
| `old_markdown_*.json` | Scan results | Scan mode only (not with `-i`) |
| `created_issues_*.json` | Successfully created issue URLs | Real runs only (not dry run) |
| `failed_issues_*.json` | Failed issues (for retry) | Real runs only (not dry run) |

**Note:** Output files are only created if they contain data. Empty files are never created.

---

### 2. remove-stale.sh - Remove Stale Labels from Documentation Issues

Finds documentation review issues (labeled `kind::docs`) that have been marked as stale and removes the stale label.

```bash
./remove-stale.sh [OPTIONS]
```

#### Options

| Flag | Description | Default |
|------|-------------|---------|
| `-d, --dry-run` | Preview mode - shows what would happen | false |
| `-l, --label LABEL` | Stale label to remove | stale |
| `-a, --all` | Process ALL documentation issues (not just script-created) | false |
| `-h, --help` | Show help | - |

**Default Behavior:** By default, only processes issues created by `doc-review.sh` (identified by title prefix "Documentation Review Needed for"). Use `-a/--all` to process all `kind::docs` issues.

#### Project Selection

Specify which projects/groups to scan. If none specified, all are scanned.

| Flag | Description |
|------|-------------|
| `--packages` | Scan `big-bang/product/packages` |
| `--maintained` | Scan `big-bang/product/maintained` |
| `--sandbox` | Scan `big-bang/apps/sandbox` |
| `--umbrella` | Scan `big-bang/bigbang` (umbrella project) |

#### Examples

```bash
# Dry run - preview what would be removed (script-created issues only)
./remove-stale.sh -d

# Remove stale labels from script-created documentation issues (default)
./remove-stale.sh

# Remove stale labels from ALL documentation issues
./remove-stale.sh -a

# Dry run for all docs issues
./remove-stale.sh -a -d

# Scan only umbrella project (script-created issues)
./remove-stale.sh --umbrella

# Scan packages and maintained, all docs issues
./remove-stale.sh --packages --maintained -a

# Use custom stale label
./remove-stale.sh -l "Status::Stale" -d
```

#### How It Works

The script:
1. Searches for open issues with both `kind::docs` and the stale label (default: `stale`)
2. **By default**, filters to only issues created by `doc-review.sh` (title starts with "Documentation Review Needed for")
3. With `-a/--all` flag, processes ALL documentation issues regardless of how they were created
4. Removes the stale label from matching issues
5. Is idempotent - safe to run multiple times

#### Use Cases

**Script-created issues only (default, no `-a` flag):**
- Only processes issues created by the `doc-review.sh` script
- Identifies them by title prefix: "Documentation Review Needed for"
- **Recommended default** - keeps the automated doc review process active without affecting manually created documentation issues
- Safe to run regularly without impacting other documentation work

**All documentation issues (`-a` flag used):**
- Removes stale labels from ANY documentation issue that has been marked stale
- Useful for broader documentation issue management
- Use when you want to mass-remove stale labels from all docs-related issues
