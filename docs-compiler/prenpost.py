import os
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
        with Path().cwd().joinpath("docs-compiler.yaml").open("r") as f:
            meta = YAML().load(f)
        for folder in meta.keys():
            if folder != "/":
                os.makedirs(Path().cwd() / "docs" / folder, exist_ok=True)


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
