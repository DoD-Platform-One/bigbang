import re
import shutil
import subprocess as sp
from pathlib import Path

import frontmatter
from git import Repo
from rich import print
from rich.console import Console
from ruamel.yaml import YAML
import semver

yaml = YAML(typ="rt")
# indent 2 spaces extra on lists
yaml.indent(mapping=2, sequence=4, offset=2)
# prevent opinionated line wrapping
yaml.width = 1000

c = Console()


class SubmoduleRepo:
    def __init__(self, name):
        self.name = name
        self.path = Path.cwd() / "submodules" / name
        self.repo = Repo(self.path)
        self.upstream = self.repo.remote().url.removesuffix(".git")
        self.ref = "main"

    def pull(self):
        self.repo.git.pull()

    def checkout(self, ref):
        if self.repo.is_dirty():
            print(f"{self.name} repo has pending changes, please commit or stash them")
            return
        self.repo.git.checkout(ref)
        # print(f"{self.name} checked out @{ref}")
        self.ref = ref

    def get_revision_date(self, abspath):
        return self.repo.git.log(abspath, n=1, date="short", format="%ad by %cn")

    def copy_files(self, src_root, dst_root, include):
        for p in include:
            src = Path(src_root / p)
            if src.exists() == False:
                print(
                    f"[yellow]WARNING  -[/yellow] `include` has a bad entry, no such file or directory: '{self.name}/{p}'"
                )
                continue
            dst = dst_root / p
            if src.is_dir():
                shutil.copytree(src, dst, dirs_exist_ok=True)
            else:
                shutil.copy2(src, dst)

    def patch_external_refs(self, md_files_glob, root: Path):
        """
        This method checks for links to external files (ie, files not found within the `include` block of the config)
        It then patches the files to reference the upstream file (found in Repo1) instead of a relative link
        """
        # these look for local and relative links only
        # markdown regex to extract links from [Link label](link url)
        md_regex = r"\]\(([^\)]*)\)"
        md_glob = re.compile(md_regex)
        all_md = root.glob(md_files_glob)
        for md in all_md:
            relative_path = Path(md).resolve().expanduser().relative_to(root)
            if (
                Path(md).name == "values.md"
                and "values" in frontmatter.loads(Path(md).read_text())["tags"]
                or md == "about.md"
            ):
                # dont check the values.md files or about.md
                continue
            with Path(md).open() as f:
                original = f.read()
            without_code = re.sub(
                r"^```[^\S\r\n]*[a-z]*(?:\n(?!```$).*)*\n```",
                "",
                original,
                0,
                re.MULTILINE,
            )
            folder = Path(md).resolve().expanduser().parent
            md_urls = md_glob.findall(without_code)

            paths_to_check = []
            for url in md_urls:
                if url.startswith("mailto:"):
                    # not gonna check email links yet
                    continue
                if url.startswith("#"):
                    # not gonna check header links yet
                    continue
                if url.startswith("<"):
                    # not gonna check alt href pattern
                    continue
                url_pattern = "^https?:\\/\\/(?:www\\.)?[-a-zA-Z0-9@:%._\\+~#=]{1,256}\\.[a-zA-Z0-9()]{1,6}\\b(?:[-a-zA-Z0-9()@:%_\\+.~#?&\\/=]*)$"
                if re.match(url_pattern, url):
                    # not gonna check remote
                    continue
                if " " in url:
                    # url contains spaces, prob a bad url anyways
                    continue
                # remove title link
                if re.match(r"^\w|\.", url):
                    paths_to_check.append(url.rsplit("#", 1)[0])

            paths_to_check: list[str] = list(set(paths_to_check))
            for p in paths_to_check:
                full_path = folder.joinpath(p).resolve()
                if not full_path.exists():
                    # if the path does not exist, but there is a path that matches without the current folder in the path,
                    # replace it with that one
                    if p.startswith(f"./{Path(p).parent.name}") or p.startswith(
                        Path(p).parent.name
                    ):
                        without_parent = (
                            p.removeprefix(Path(p).parent.name)
                            .removeprefix(f"./{Path(p).parent.name}")
                            .removeprefix("/")
                        )
                        without_parent_path_exists = folder.joinpath(
                            without_parent
                        ).exists()

                        if without_parent_path_exists:
                            print(
                                f"INFO     - Patching broken relative link to './docs' in '{self.name}/{str(Path(md).relative_to(root))}': '{p}' --> {without_parent}"
                            )
                            with Path(md).open() as f:
                                old_content = f.read()
                            with Path(md).open("w") as f:
                                patched_content = re.sub(p, without_parent, old_content)
                                f.write(patched_content)
                                f.close()
                            continue

                    relative_to_repo_root = (
                        self.path.joinpath(relative_path)
                        .parent.joinpath(Path(p))
                        .resolve()
                        .relative_to(self.path)
                    )
                    file_actually_exists = self.path.joinpath(
                        relative_to_repo_root
                    ).exists()
                    if file_actually_exists == False:
                        print(
                            f"[yellow]WARNING  -[/yellow] Unable to patch broken relative link in '{self.name}/{str(Path(md).relative_to(root))}', file does not exist: '{p}'"
                        )
                        continue
                    upstream_path = (
                        self.upstream
                        + "/-/tree/"
                        + self.ref
                        + "/"
                        + str(relative_to_repo_root)
                    )
                    print(
                        f"INFO     - Patching broken relative link in '{self.name}/{str(Path(md).relative_to(root))}': '{p}' --> {upstream_path}"
                    )
                    with Path(md).open() as f:
                        old_content = f.read()
                    with Path(md).open("w") as f:
                        patched_content = re.sub(p, upstream_path, old_content)
                        f.write(patched_content)
                        f.close()


class BigBangRepo(SubmoduleRepo):
    def __init__(self):
        SubmoduleRepo.__init__(self, "bigbang")
        self.ref = "master"

    def get_pkgs(self):
        pkgs = {}
        values_path = self.path / "chart" / "values.yaml"
        with open(values_path) as values_yaml:
            values = yaml.load(values_yaml)

        # core
        for _, v in values.items():
            if isinstance(v, dict) and "git" in v:
                pkg = v["git"]
                pkg["name"] = pkg["repo"].split("/")[-1].split(".")[0]
                pkg["title"] = pkg["name"].replace("-", " ").title()
                pkg.pop("path", None)
                pkg["type"] = "Core"
                pkgs[pkg["name"]] = pkg
        # addons
        for _, v in values["addons"].items():
            if isinstance(v, dict) and "git" in v:
                pkg = v["git"]
                pkg["name"] = pkg["repo"].split("/")[-1].split(".")[0]
                pkg["title"] = pkg["name"].replace("-", " ").title()
                pkg.pop("path", None)
                pkg["type"] = "Addon"
                pkgs[pkg["name"]] = pkg

        return pkgs

    def get_tags(self):
        versions = []
        for tag in reversed(
            sorted(self.repo.tags, key=lambda t: t.commit.committed_datetime)
        ):
            if "rc" in tag.name:
                # skip rc versions
                continue
            elif tag.name == "":
                # skip blank version(s)
                continue

            try:
                semver.VersionInfo.parse(tag.name)
                versions.append(tag.name)
            except ValueError:
                continue

        return versions


def pull_latest():
    with c.status("Pulling latest from all submodules...", spinner="aesthetic"):
        sp.run(
            ["./scripts/pull-latest.sh"],
            cwd=Path().cwd(),
            capture_output=True,
            encoding="utf-8",
        )
