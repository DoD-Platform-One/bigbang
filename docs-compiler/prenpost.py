import shutil
import subprocess as sp
from pathlib import Path


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
    for k, _ in pkgs.items():
        base_exists = Path.cwd().joinpath("submodules").joinpath(k).exists()
        if base_exists == False:
            print(f"Base template does not exist in base/packages/{k}")
            print(
                f"You will have to run `./scripts/init-pkg {k}`, commit and try again"
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
