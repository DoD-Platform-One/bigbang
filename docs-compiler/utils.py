import json
import re
import shutil
from pathlib import Path

import frontmatter
from deepmerge import always_merger
from jinja2 import Template
from requests import get
from rich import print
from ruamel.yaml import YAML

yaml = YAML(typ="rt")
# indent 2 spaces extra on lists
yaml.indent(mapping=2, sequence=4, offset=2)
# prevent opinionated line wrapping
yaml.width = 1000


def write_awesome_pages(config, dst):
    dot_pages = {}
    if "nav" in config:
        dot_pages["nav"] = config["nav"]
    else:
        dot_pages["nav"] = ["..."]

    if "title" in config:
        dot_pages["title"] = config["title"]

    with Path(dst).open("w") as f:
        yaml.dump(dot_pages, f)


values_template = Template(
    open(
        Path().cwd().joinpath("docs-compiler/templates/values.j2"),
        "r",
    ).read()
)


def copy_helm_readme(from_readme, to_readme, to_values, title):
    with open(from_readme, "r") as f:
        content = f.read()
        values_tables = re.findall(r"## Values(.*?)## Contributing", content, re.DOTALL)
        if len(values_tables) == 0:
            values_tables = re.findall(r"## Values(.*)", content, re.DOTALL)
        if len(values_tables) == 0:
            print(f"WARNING  -  No values table found in {from_readme}")
            shutil.copy2(from_readme, to_readme)
            return
        table = values_tables[0]

    with open(to_readme, "w") as f:
        content = re.sub(r"^#\s.*?\n", "", content)
        content = content.replace(
            table, "\n\nPlease see the [values](values.md) docs.\n\n"
        )
        f.write(content)
        f.close()

    with open(to_values, "w") as f:
        rows = table.splitlines()[2:-2]
        values = []

        for i, row in enumerate(rows[2:]):
            data = {}
            data["language"] = "yaml"
            data["Key"] = row.split("|")[1].strip()
            data["Type"] = row.split("|")[2].strip()
            data["Description"] = row.split("|")[-2].strip()
            # handle default having | within itself
            data["Default"] = "|".join(row.split("|")[3:-2]).strip()
            if (
                data["Default"].startswith("`") == False
                or data["Default"].endswith("`") == False
            ):
                data["language"] = "text"
                continue
            if r"\n" in data["Default"]:
                data["PrettyPrint"] = "\n".join(data["Default"].split(r"\n")).strip("`")

            if data["Type"] == "list" or data["Type"] == "object":
                data["language"] = "text"
                data["Default"] = data["Default"].strip("`")
                if data["Default"] != "`{}`" and data["Default"] != "`[]`":
                    data["PrettyPrint"] = "\n".join(
                        json.dumps(json.loads(data["Default"]), indent=2).split(r"\n")
                    )
            else:
                data["Default"] = data["Default"].strip("`")

            values.append(data)

        values_rendered = values_template.render(values=values, title=title)
        values_md = re.sub("\n\n\n", "\n", values_rendered)

        f.write(values_md)

        f.close()


def add_frontmatter(path, metadata):
    """
    Add metadata to yaml frontmatter
    """
    with open(path) as f:
        post = frontmatter.loads(f.read())

    m = post.metadata
    if m is None:
        m = metadata
    else:
        m = always_merger.merge(m, metadata)

    with open(path, "w") as f:
        f.write(frontmatter.dumps(post))
        f.close()


def get_release_notes(tag):
    release_url = f"https://repo1.dso.mil/api/v4/projects/2872/releases/{tag}"
    res = get(release_url)
    if res.status_code == 404:
        print(
            f"[yellow]WARNING  -[/yellow] No Big Bang release found for version: '{tag}'"
        )
        return None
    release = res.json()
    notes = release["description"]
    return notes
