from pathlib import Path

from git import Repo
from ruamel.yaml import YAML

yaml = YAML(typ="rt")
# indent 2 spaces extra on lists
yaml.indent(mapping=2, sequence=4, offset=2)
# prevent opinionated line wrapping
yaml.width = 1000


class SubmoduleRepo:
    def __init__(self, name):
        self.name = name
        self.path = Path.cwd() / "submodules" / name
        self.repo = Repo(self.path)

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


class BigBangRepo(SubmoduleRepo):
    def __init__(self):
        SubmoduleRepo.__init__(self, "bigbang")

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

            versions.append(tag.name)

        return versions
