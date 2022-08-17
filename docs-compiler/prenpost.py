import shutil
import subprocess as sp
from pathlib import Path

from rich import print
from rich.console import Console
from ruamel.yaml import YAML

c = Console()


def cleanup():
    shutil.rmtree("docs", ignore_errors=True, onerror=None)


def preflight(bb):
    with c.status("Running preflight steps...", spinner="aesthetic"):
        shutil.rmtree("docs", ignore_errors=True, onerror=None)
        shutil.copytree("base", "docs", dirs_exist_ok=True)
        pkgs = bb.get_pkgs()
        with Path().cwd().joinpath("docs-compiler.yaml").open("r") as f:
            meta = YAML().load(f)
        pkgs_from_meta = meta["packages"]
        for pkg in pkgs.keys():
            config_exists = pkg in pkgs_from_meta
            if config_exists == False:
                print(
                    f"[red]ERROR[/red]    - Package config '.packages.{pkg}' does not exist in 'bb-docs-compiler.yaml'"
                )
                print(
                    f"You will have to add a new config entry for this package, commit and try again"
                )
                exit()


def postflight():
    with c.status("Running postflight steps...", spinner="aesthetic"):
        sp.run(
            ["./scripts/remove-gitlab-toc.sh"],
            cwd=Path().cwd(),
            capture_output=True,
            encoding="utf-8",
        )
        sp.run(
            ["./scripts/prettier.sh"],
            cwd=Path().cwd(),
            encoding="utf-8",
        )
