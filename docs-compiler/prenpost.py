import shutil
import subprocess as sp
from pathlib import Path

from rich import print
from ruamel.yaml import YAML


def setup():
    shutil.rmtree("docs", ignore_errors=True, onerror=None)
    shutil.copytree("base", "docs", dirs_exist_ok=True)
    print("INFO     -  Pulling latest from all submodules...")
    sp.run(
        ["./scripts/pull-latest.sh"],
        cwd=Path().cwd(),
        capture_output=True,
        encoding="utf-8",
    )


def cleanup():
    shutil.rmtree("docs", ignore_errors=True, onerror=None)


def preflight(bb):
    pkgs = bb.get_pkgs()
    with Path().cwd().joinpath("docs-compiler.yaml").open("r") as f:
        meta = YAML().load(f)
    pkgs_from_meta = meta["packages"]
    for k, _ in pkgs.items():
        config_exists = k in pkgs_from_meta
        if config_exists == False:
            print(
                f"[red]ERROR[/red]    - Package config '.packages.{k}' does not exist in 'bb-docs-compiler.yaml'"
            )
            print(
                f"You will have to add a new config entry for this package, commit and try again"
            )
            exit()


def postflight():
    sp.run(
        ["./scripts/remove-gitlab-toc.sh"],
        cwd=Path().cwd(),
        capture_output=True,
        encoding="utf-8",
    )
    sp.run(
        ["./scripts/prettier.sh"],
        cwd=Path().cwd(),
        capture_output=True,
        encoding="utf-8",
    )
