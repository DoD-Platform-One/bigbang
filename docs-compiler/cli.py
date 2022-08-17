import copy
import glob
import os
import re
import shutil
import subprocess as sp
from copy import deepcopy
from pathlib import Path

import click
from deepmerge import always_merger as merge
from git import GitCommandError, Repo
from rich import print
from ruamel.yaml import YAML

from .prenpost import cleanup, postflight, preflight
from .repo import BigBangRepo, SubmoduleRepo, pull_latest
from .utils import (
    add_frontmatter,
    get_release_notes,
    parse_values_table_from_helm_docs,
    patch_values_table_from_helm_docs,
    write_awesome_pages,
    write_values_md,
)

yaml = YAML(typ="rt")
# indent 2 spaces extra on lists
yaml.indent(mapping=2, sequence=4, offset=2)
# prevent opinionated line wrapping
yaml.width = 1000


def compile(bb, tag):
    pkgs = bb.get_pkgs()
    docs_root = Path().cwd() / "docs"

    with Path().cwd().joinpath("docs-compiler.yaml").open("r") as f:
        meta = yaml.load(f)

    ## bigbang section
    bb_config = meta["/"]
    notes = get_release_notes(tag)
    if notes != None:
        bb_config["pages"]["nav"][4]["📋 Release Notes"] = "release-notes.md"
        with open("docs/release-notes.md", "w") as f:
            f.write(notes)
            f.close()
    bb.copy_files(
        Path().cwd() / "submodules" / "bigbang", docs_root, bb_config["include"]
    )
    write_awesome_pages(bb_config["pages"], docs_root / ".pages")

    bb_values_table = parse_values_table_from_helm_docs(
        "submodules/bigbang/docs/understanding-bigbang/configuration/base-config.md",
        r"## Values(.*)",
    )

    write_values_md("docs/values.md", bb_values_table, "Big Bang")

    root_level_md = glob.iglob("docs/*.md")
    for md in root_level_md:
        if md == "docs/about.md" or md == "docs/values.md":
            continue
        else:
            add_frontmatter(
                md,
                {
                    "hide": ["navigation"],
                    "revision_date": bb.get_revision_date(md.replace("docs/", "", 1)),
                },
            )

    pkgs_configs = meta["packages"]
    template_config = meta["packages"]["_template"]
    del meta["packages"]["_template"]
    for pkg in pkgs_configs:
        tmpl = deepcopy(template_config)
        pkg_config = merge.merge(tmpl, meta["packages"][pkg])
        pkg_name = pkg_config["source"].split("/")[-1]
        if pkg_name not in pkgs.keys():
            # this means that we are trying to build a version of the docs that does not have this (newer) pkg
            # skip it
            continue
        repo = SubmoduleRepo(pkg_name)
        dst_root = docs_root / "packages" / pkg
        os.makedirs(dst_root)
        src_root = Path().cwd().joinpath(pkg_config["source"])
        repo.copy_files(src_root, dst_root, pkg_config["include"])
        write_awesome_pages(pkg_config["pages"], dst_root / ".pages")

    shutil.copy2(
        "submodules/bigbang/docs/packages.md",
        "docs/packages/index.md",
    )

    pkg_readmes = glob.iglob("docs/packages/*/README.md")
    for md in pkg_readmes:
        pkg_name = md.split("/")[2]
        values_table = parse_values_table_from_helm_docs(
            md.replace("docs/packages/", "submodules/", 1),
            r"## Values(.*?)## Contributing",
        )
        patch_values_table_from_helm_docs(
            f"docs/packages/{pkg_name}/README.md", values_table
        )
        write_values_md(f"docs/packages/{pkg_name}/values.md", values_table, pkg_name)
        add_frontmatter(
            f"docs/packages/{pkg_name}/values.md", {"tags": ["values", pkg_name]}
        )

    bb_docs = glob.iglob("docs/docs/**/*.md", recursive=True)
    for md in bb_docs:
        add_frontmatter(
            md,
            {
                "tags": ["bigbang"],
                "revision_date": bb.get_revision_date(
                    md.replace("docs/docs/", "./docs/", 1)
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
                    md.replace(f"docs/packages/{pkg_name}/", "./", 1)
                ),
            },
        )

    # patch docs/docs references
    pkg_docs_glob = glob.iglob("docs/packages/**/docs/*.md", recursive=True)
    for doc in pkg_docs_glob:
        with open(doc, "r") as f:
            content = f.read()

        without_bad_links = re.sub(r"\]\(\.\/docs", "](", content)
        without_bad_links_ex = re.sub(r"\]\(docs", "](", without_bad_links)

        if len(content) != len(without_bad_links_ex):
            print(
                f"[yellow]WARNING  -[/yellow] File has bad links to '/docs' or './docs' when already in the docs directory: '{doc}'"
            )

        with open(doc, "w") as f:
            f.write(without_bad_links_ex)
            f.close()
    # end patch

    # patch packages nav
    with open("docs/packages/.pages", "w") as f:
        dot_pages = {}
        dot_pages["nav"] = [{"Home": "index.md"}]
        sorted_pkgs = sorted(meta["packages"])
        for pkg in sorted_pkgs:
            dot_pages["nav"].append({pkg: pkg})
        yaml.dump(dot_pages, f)
        f.close()
    # end patch


@click.command(
    context_settings={"help_option_names": ["-h", "--help"]},
    epilog="Built and maintained by @razzle",
)
@click.option(
    "-l",
    "--last-x-tags",
    help="Build for last x Big Bang tags",
    default=1,
    type=click.IntRange(1, 9, clamp=True),
)
@click.option(
    "--pre-release",
    help="Build for `release-1.X.0` (only for release engineering)",
    is_flag=True,
)
@click.option(
    "-c", "--clean", help="Destroy + reset resources after build", is_flag=True
)
@click.option(
    "-o",
    "--outdir",
    help="Output build folder, default (site)",
    default="site",
    type=click.STRING,
)
@click.option(
    "--no-build",
    help="Generate a `docs` folder but do not render w/ mkdocs",
    is_flag=True,
)
@click.option("-d", "--dev", help="Run `mkdocs serve` after build", is_flag=True)
def compiler(last_x_tags, pre_release, clean, outdir, no_build, dev):
    pull_latest()
    bb = BigBangRepo()
    tags = bb.get_tags()
    tags_to_compile = tags[:last_x_tags]
    tags_to_compile.reverse()
    if "1.38.0" in tags_to_compile:
        print("ERROR   - Only versions 1.39.0+ are supported via this docs generator")
        exit(1)

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
        print(f"INFO     -  Compiling docs for Big Bang version '{tags_to_compile[0]}'")
        preflight(bb)
        compile(bb, tags_to_compile[0])
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
            bb.checkout(tag)
            print(f"INFO     -  Compiling docs for Big Bang version '{tag}'")
            preflight(bb)
            compile(bb, tag)
            postflight()

            shutil.move("docs", f"site/{tag}")
        shutil.move("site", f"docs")
        print(f"INFO     -  Documentation saved to (./docs/{tag})")

    else:
        for tag in tags_to_compile:
            bb.checkout(tag)
            print(f"INFO     -  Compiling docs for Big Bang version {tag}")
            preflight(bb)
            compile(bb, tag)
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
