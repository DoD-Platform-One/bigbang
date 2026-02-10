# Testing Shell Scripts

[[_TOC_]]

## Overview

Big Bang uses [BATS (Bash Automated Testing System)](https://bats-core.readthedocs.io/) to unit-test shell scripts in the repository. The primary test suite covers `k3d-dev.sh`, the script that automates remote k3d development environments on AWS.

These tests verify pure functions and argument parsing -- no real AWS API calls, SSH connections, or network requests are made. Each test sources the script, calls a function, and checks a variable.

Optionally, [Lefthook](https://github.com/evilmartians/lefthook) can run these tests automatically as git hooks so you catch regressions before they leave your machine.

## Prerequisites

### Install BATS

**macOS (Homebrew):**

```bash
brew install bats-core
```

**Linux and other platforms:** See the [official BATS installation guide](https://bats-core.readthedocs.io/en/stable/installation.html) for options including `apt`, `dnf`, `npm`, and building from source.

### Install Lefthook (optional)

Lefthook is not required to run BATS tests directly, but it wires them into your git workflow so they fire on commit and push.

**macOS (Homebrew):**

```bash
brew install lefthook
```

**Linux and other platforms:** See the [Lefthook installation docs](https://lefthook.dev/installation/) for options including `apt`, `rpm`, `npm`, standalone binaries, and building from source.

## Running Tests

### Run tests directly

```bash
bats tests/bats/k3d-dev/k3d-dev.bats
```

To run all BATS test suites recursively (useful as more suites are added):

```bash
bats --recursive tests/bats/
```

### Run tests in parallel

BATS supports parallel execution with the `--jobs` flag:

```bash
bats --jobs 4 --recursive tests/bats/
```

### Expected output

A passing run looks like this:

```console
k3d-dev/k3d-dev.bats
 ✓ k3dsshcmd builds correct SSH command
 ✓ set_kubeconfig uses PublicIP when not provisioning
 ✓ set_kubeconfig uses AWSUSERNAME when provisioning
 ✓ process_arguments -b sets BIG_INSTANCE=true
 ✓ process_arguments -M sets METAL_LB=false
 ✓ process_arguments -p sets PRIVATE_IP=true
 ✓ process_arguments -d sets action=destroy_instances
 ✓ process_arguments -t sets PROJECTTAG
 ✓ process_arguments -K sets RESET_K3D=true
 ✓ process_arguments -H sets PublicIP and disables cloud provisioning
 ✓ process_arguments -H without -P sets PrivateIP=PublicIP
 ✓ process_arguments -D and --domain set BASE_DOMAIN
 ✓ process_arguments handles multiple flags
 ✓ process_arguments reports unknown option
 ✓ set_domains builds PUBLIC_DOMAINS and PASSTHROUGH_DOMAINS
 ✓ set_domains uses default BASE_DOMAIN
 ✓ set_domains clears stale values before rebuilding
 ✓ run_batch_add fails if no batch started
```

## Enabling Lefthook

Lefthook is opt-in. It does nothing until you explicitly install its hooks into your local clone.

### One-time setup

```bash
lefthook install
```

This writes git hooks into `.git/hooks/` that delegate to `lefthook.yaml` in the repo root. If you later want to remove them, run `lefthook uninstall`.

### What the hooks do

| Hook         | Trigger              | Runs when                                            |
|--------------|----------------------|------------------------------------------------------|
| `pre-commit` | `git commit`         | `k3d-dev.sh` or a `tests/bats/**/*.bats` file is staged |
| `pre-push`   | `git push`           | Any `*.sh` or `*.bats` file changed vs. the remote   |

Both hooks run `bats --jobs 4 --recursive tests/bats/`. The glob filters mean they only fire when shell or test files are involved -- a commit that only touches YAML or Markdown skips them entirely.

### Running hooks manually

You can invoke the hooks by name without actually committing or pushing:

```bash
# Run the pre-commit hook against all files
lefthook run pre-commit --all-files

# Run the pre-push hook
lefthook run pre-push
```

## Test structure

Test files live under `tests/bats/`, organized by the script they cover:

```
tests/bats/
└── k3d-dev/
    └── k3d-dev.bats    # Tests for docs/reference/scripts/developer/k3d-dev.sh
```

Each `.bats` file is a valid Bash script annotated with `@test` blocks. A helper function `_source_k3d_dev()` loads the script under test, and `_reset_globals()` restores default variable state between tests so they stay independent.

The test suite covers four areas:

- **Pure functions** -- `k3dsshcmd`, `set_kubeconfig`
- **Argument parsing** -- common flags accepted by `process_arguments`
- **Domain configuration** -- `set_domains` building FQDN lists from subdomains
- **Error guards** -- batch-file operations fail cleanly when misused

## Additional Resources

- [BATS documentation](https://bats-core.readthedocs.io/)
- [Lefthook documentation](https://github.com/evilmartians/lefthook)
- [k3d-dev.sh script](../../reference/scripts/developer/k3d-dev.sh)
- [AWS K3d Script usage](aws-k3d-script.md)
- [Development Environment setup](development-environment.md)
