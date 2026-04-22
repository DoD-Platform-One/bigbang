# GitLab Triage Tools

Utilities in this folder to triage Big Bang GitLab work.

## Prerequisites

- `glab` (authenticated)
- `jq`
- `bash`

## Tools At A Glance

| Tool                                | Purpose                                            | Safe Default           |
| ----------------------------------- | -------------------------------------------------- | ---------------------- |
| `doc-review.sh`                     | Find stale markdown docs and create review issues  | Dry run only with `-d` |
| `remove-stale.sh`                   | Remove stale labels from docs issues               | Dry run only with `-d` |
| `attach-renovate-issues-to-epic.sh` | Attach closed Renovate issues to an epic/work item | Dry run by default     |

## Common Project Scope Flags

Used by `doc-review.sh` and `remove-stale.sh`:

| Flag           | Scope                         |
| -------------- | ----------------------------- |
| `--packages`   | `big-bang/product/packages`   |
| `--maintained` | `big-bang/product/maintained` |
| `--sandbox`    | `big-bang/apps/sandbox`       |
| `--umbrella`   | `big-bang/bigbang`            |

If no scope flags are provided, all scopes are included.

---

## 1) `doc-review.sh`

Scans markdown files for age-based staleness and creates tracking issues.

```bash
./doc-review.sh [OPTIONS]
```

### Key Options

| Flag                  | Description                             | Default |
| --------------------- | --------------------------------------- | ------- |
| `-t, --time MONTHS`   | Files older than MONTHS                 | `6`     |
| `-c, --count NUMBER`  | Max files to check, or `all`            | `all`   |
| `-i, --input FILE`    | Use existing scan JSON (skip scan)      | none    |
| `-d, --dry-run`       | Preview actions only                    | `false` |
| `--team TEAM`         | Filter by team                          | `all`   |
| `--epic EPIC_IID`     | Add issues to an epic                   | none    |
| `--ignore-commit SHA` | Ignore commit for age calc (repeatable) | none    |
| `-h, --help`          | Help                                    | -       |

### Notes

- Idempotent: skips duplicate titles and already-linked epic items.
- Umbrella behavior: creates 1 issue per directory, while other scopes create 1 issue per file.
- Automatic exclusions: `chart/`, `blog/`, `adr/`, `ADR/`.

### Examples

```bash
# Preview everything
./doc-review.sh -d

# Umbrella only, with epic link
./doc-review.sh --umbrella -d --epic 495

# Create issues from existing scan results
./doc-review.sh -i old_markdown.json --epic 495
```

### Output Files

| File Pattern            | Description                         |
| ----------------------- | ----------------------------------- |
| `old_markdown_*.json`   | Scan results (scan mode only)       |
| `created_issues_*.json` | Created issue URLs (real runs only) |
| `failed_issues_*.json`  | Failures for retry (real runs only) |

---

## 2) `remove-stale.sh`

Removes stale labels from documentation issues.

```bash
./remove-stale.sh [OPTIONS]
```

### Key Options

| Flag                | Description                                       | Default |
| ------------------- | ------------------------------------------------- | ------- |
| `-d, --dry-run`     | Preview actions only                              | `false` |
| `-l, --label LABEL` | Stale label to remove                             | `stale` |
| `-a, --all`         | Process all docs issues (not only script-created) | `false` |
| `-h, --help`        | Help                                              | -       |

### Notes

- Default behavior targets issues created by `doc-review.sh` (title starts with `Documentation Review Needed for`).
- With `-a`, processes all open issues with `kind::docs` + stale label.
- Idempotent and safe to re-run.

### Examples

```bash
# Preview default behavior (script-created docs issues)
./remove-stale.sh -d

# Remove stale from all docs issues
./remove-stale.sh -a

# Custom stale label, dry run
./remove-stale.sh -l "Status::Stale" -d
```

---

## 3) `attach-renovate-issues-to-epic.sh`

Attaches closed Renovate issues to a target epic/work item by date range.

```bash
./attach-renovate-issues-to-epic.sh [OPTIONS]
```

### Matching Rules

- Strict title match: issue title must start with `Renovate:`
- Closed-state filter: only issues with `closed_at`
- Date filter: inclusive range based on `closed_at[0:10]`

### Key Options

| Flag                      | Description                             |
| ------------------------- | --------------------------------------- |
| `--start-date YYYY-MM-DD` | Closed date lower bound (inclusive)     |
| `--end-date YYYY-MM-DD`   | Closed date upper bound (inclusive)     |
| `--group PATH`            | GitLab group path                       |
| `--epic-iid IID`          | Parent epic/work item IID               |
| `--apply`                 | Perform attachments (otherwise dry run) |
| `--dry-run`               | Force dry run mode                      |
| `-h, --help`              | Help                                    |

### Notes

- Dry run is default.
- Existing epic children are detected and skipped.
- Uses group epic endpoint: `groups/:id/epics/:epic_iid/issues/:issue_id`.

### Examples

```bash
# Preview with script defaults
./attach-renovate-issues-to-epic.sh

# Apply with script defaults
./attach-renovate-issues-to-epic.sh --apply

# Apply with explicit bounds and target
./attach-renovate-issues-to-epic.sh \
  --start-date 2026-02-02 \
  --end-date 2026-05-01 \
  --group big-bang \
  --epic-iid 638 \
  --apply
```
