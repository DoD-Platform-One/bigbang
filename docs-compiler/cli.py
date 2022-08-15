import glob
import shutil
import subprocess as sp
from pathlib import Path

import click
import tabulate
from git import GitCommandError, Repo
from ruamel.yaml import YAML

from .repo import BigBangRepo, SubmoduleRepo
from .utils import add_frontmatter, copy_helm_readme, write_awesome_pages

yaml = YAML(typ="rt")
# indent 2 spaces extra on lists
yaml.indent(mapping=2, sequence=4, offset=2)
# prevent opinionated line wrapping
yaml.width = 1000


@click.group(
    context_settings={"help_option_names": ["-h", "--help"]},
    epilog="Built and maintained by @razzle",
)
def cli():
    pass


@click.command(help="List all bb pkgs")
def pkgs():
    bb = BigBangRepo()
    pkgs = bb.get_pkgs()
    table = []
    headers = ["Name", "Added?", "Type", "Repo", "Tag"]
    for _, v in pkgs.items():
        is_submodule = Path.cwd().joinpath("submodules").joinpath(v["name"]).exists()
        table.append([v["name"], is_submodule, v["type"], v["repo"][49:], v["tag"]])

    print(tabulate.tabulate(table, headers=headers))
    return table


@click.command()
def tags():
    bb = BigBangRepo()
    tags = bb.get_tags()
    import json

    print(json.dumps(tags, indent=2))
    return tags


def setup():
    shutil.rmtree("docs", ignore_errors=True, onerror=None)
    shutil.copytree(
        "base", "docs", ignore=shutil.ignore_patterns("*.yaml"), dirs_exist_ok=True
    )
    print("INFO     -  Pulling latest from all submodules...")
    sp.run(
        ["./scripts/pull-latest.sh"],
        cwd=Path().cwd(),
        capture_output=True,
        encoding="utf-8",
    )


def cleanup():
    shutil.rmtree("docs", ignore_errors=True, onerror=None)


def compiler(bb, tag):
    pkgs = bb.get_pkgs()

    configs = glob.iglob("base/**/config.yaml", recursive=True)

    for fpath in configs:
        dst_root = Path(fpath.replace("base/", "docs/").replace("/config.yaml", ""))

        with open(fpath, "r") as f:
            config = yaml.load(f)

        src_root = Path().cwd().joinpath(config["source"]) or None

        if src_root is None:
            print(f"{fpath} config is missing a `source` key")
            continue

        repo = SubmoduleRepo(str(src_root).split("/")[-1])

        if repo.name != "bigbang":
            if repo.name not in pkgs:
                # this means that we are trying to build a version of the docs that does not have this (newer) pkg
                # skip it
                shutil.rmtree(f"docs/{repo.name}", ignore_errors=True, onerror=None)
                continue
            repo.checkout(pkgs[repo.name]["tag"])

        if repo.name == "bigbang":
            config["nav"][4]["📋 Release Notes"] += "/" + tag

        shutil.copytree(
            src_root,
            dst_root,
            ignore=shutil.ignore_patterns(*config["ignore_patterns"]),
            dirs_exist_ok=True,
        )

        write_awesome_pages(config, dst_root / ".pages")

    shutil.copy2(
        "submodules/bigbang/docs/packages.md",
        "docs/packages/index.md",
    )

    copy_helm_readme(
        "submodules/bigbang/docs/understanding-bigbang/configuration/base-config.md",
        "docs/README.md",
        "docs/values.md",
        "Big Bang",
    )

    shutil.copy2("submodules/bigbang/README.md", "docs/README.md")

    add_frontmatter(
        "docs/README.md",
        {
            "revision_date": bb.get_revision_date("README.md"),
        },
    )

    pkg_readmes = glob.iglob("docs/packages/*/README.md")
    for md in pkg_readmes:
        pkg_name = md.split("/")[2]
        copy_helm_readme(
            md.replace("docs/packages/", "submodules/"),
            f"docs/packages/{pkg_name}/README.md",
            f"docs/packages/{pkg_name}/values.md",
            pkg_name,
        )

    bb_docs = glob.iglob("docs/docs/**/*.md", recursive=True)
    for md in bb_docs:
        add_frontmatter(
            md,
            {
                "tags": ["bigbang"],
                "revision_date": bb.get_revision_date(
                    md.replace("docs/docs/", "./docs/")
                ),
            },
        )

    pkg_docs = glob.iglob("docs/packages/**/*.md", recursive=True)
    for md in pkg_docs:
        pkg_name = md.split("/")[2]
        if (
            md == "docs/packages/index.md"
            or md == f"docs/packages/{pkg_name}/values.md"
        ):
            continue
        add_frontmatter(
            md,
            {
                "tags": ["package", pkg_name],
                "revision_date": SubmoduleRepo(pkg_name).get_revision_date(
                    md.replace(f"docs/packages/{pkg_name}/", "./")
                ),
            },
        )

    # patch docs/docs references
    pkg_docs_glob = glob.iglob("docs/packages/**/docs/*.md", recursive=True)
    for doc in pkg_docs_glob:
        with open(doc, "r") as f:
            content = f.read()

        import re

        without_bad_links = re.sub(r"\]\(\.\/docs", "](", content)
        without_bad_links_ex = re.sub(r"\]\(docs", "](", without_bad_links)

        with open(doc, "w") as f:
            f.write(without_bad_links_ex)
            f.close()
    # end patch

    # patch packages nav
    with open("docs/packages/.pages", "w") as f:
        f.write("nav:\n  - Home: index.md")
        pkg_dirs = sorted(glob.iglob("docs/packages/*/"))
        for dir in pkg_dirs:
            name = dir.split("/")[2]
            f.write(f"\n  - {name}: {name}")
        f.close()
    # end patch


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


@click.command()
@click.option("-l", "--last-x-tags", default=1, type=click.IntRange(1, 9, clamp=True))
@click.option("--pre-release", is_flag=True)
@click.option("-c", "--clean", is_flag=True)
@click.option("-o", "--outdir", default="site", type=click.STRING)
@click.option("--no-build", is_flag=True)
@click.option("-d", "--dev", is_flag=True)
def compile(last_x_tags, pre_release, clean, outdir, no_build, dev):
    bb = BigBangRepo()
    tags = bb.get_tags()
    tags_to_compile = tags[:last_x_tags]
    tags_to_compile.reverse()
    setup()

    ### TEMP MANUAL OVERRIDE TO USE `1272-draft-follow-on-follow-on-docs-design-update` branch
    tags_to_compile = ["1272-draft-follow-on-follow-on-docs-design-update"]

    if pre_release:
        latest_release_tag = tags_to_compile[0]
        next_release_tag_x = (
            "release-1." + str(int(latest_release_tag.split(".")[1]) + 1) + ".x"
        )
        tags_to_compile = [next_release_tag_x]
        try:
            bb.checkout(next_release_tag_x)
        except GitCommandError as e:
            if "did not match any file(s) known to git" in e.stderr:
                print(
                    f"ERROR    -  Failed to checkout ({next_release_tag_x}) on bigbang, verify you have correctly run R2-D2"
                )
                exit(1)

    if last_x_tags == 1:
        bb.checkout(tags_to_compile[0])
        print(f"INFO     -  Compiling docs for Big Bang version {tags_to_compile[0]}")
        preflight(bb)
        compiler(bb, tags_to_compile[0])
        postflight()

        if dev and no_build == False:
            sp.run(["mkdocs", "serve"])
        elif no_build:
            print(
                "INFO     -  Documentation (./docs) ready to be built w/ `mkdocs build --clean`"
            )
            print("INFO     -  Documentation (./docs) can be served w/ `mkdocs serve`")
        else:
            sp.run(["mkdocs", "build", "--clean"])

    elif last_x_tags > 1 and no_build:
        shutil.rmtree("site", ignore_errors=True, onerror=None)
        for tag in tags_to_compile:
            setup()
            bb.checkout(tag)
            print(f"INFO     -  Compiling docs for Big Bang version {tag}")
            preflight(bb)
            compiler(bb, tag)
            postflight()

            shutil.move("docs", f"site/{tag}")
        shutil.move("site", f"docs")
        print(f"INFO     -  Documentation saved to (./docs/{tag})")

    else:
        for tag in tags_to_compile:
            setup()
            bb.checkout(tag)
            print(f"INFO     -  Compiling docs for Big Bang version {tag}")
            preflight(bb)
            compiler(bb, tag)
            postflight()
            sp.run(
                [
                    "mike",
                    "deploy",
                    "--branch",
                    "mike-build",
                    "--update-aliases",
                    "--template",
                    "docs-compiler/templates/redirect.html",
                    "--prefix",
                    "build",
                    tag,
                    "latest",
                ]
            )
        repo = Repo(".")
        shutil.rmtree("site", ignore_errors=True, onerror=None)
        repo.git.checkout("mike-build", "build")
        sp.run(["git", "branch", "-D", "mike-build"])
        sp.run(["git", "rm", "-r", "--cached", "build", "--quiet"])
        shutil.move("build", "site")
        shutil.copy2("docs-compiler/templates/index.html", "site/index.html")

    if outdir != "site" and Path("site").exists():
        shutil.move("site", outdir)
        print(f"INFO     -  Build assets located in {outdir}")

    if clean:
        cleanup()
        sp.run(
            ["git", "submodule", "update", "--init", "--recursive"], capture_output=True
        )


cli.add_command(pkgs)
cli.add_command(tags)
cli.add_command(compile)
