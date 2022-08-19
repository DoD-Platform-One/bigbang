import json
import re
from pathlib import Path

import frontmatter
from deepmerge import always_merger
from jinja2 import Template
from requests import get
from rich import print

values_template = Template(
    open(
        Path().cwd().joinpath("docs-compiler/templates/values.j2"),
        "r",
    ).read()
)


def parse_values_table_from_helm_docs(readme, regex):
    with open(readme, "r") as f:
        content = f.read()
        values_tables = re.findall(regex, content, re.DOTALL)
        if len(values_tables) == 0:
            print(f"[yellow]WARNING  -[/yellow] No values table found in {readme}")
            return None
        table = values_tables[0]
        return table


def patch_values_table_from_helm_docs(readme, table):
    with open(readme, "r") as f:
        content = f.read()
    with open(readme, "w") as f:
        content = re.sub(r"^#\s.*?\n", "", content)
        content = content.replace(
            table, "\n\nPlease see the [values](values.md) docs.\n\n"
        )
        f.write(content)
        f.close()


def write_values_md(fpath, table, title):
    with open(fpath, "w") as f:
        rows = table.splitlines()
        values = []
        header = "| Key | Type | Default | Description |"
        alignment_header = "|-----|------|---------|-------------|"

        for i, row in enumerate(rows):
            if row == header or row == alignment_header or len(row) == 0:
                continue
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
    elif m == {}:
        m = always_merger.merge(m, metadata)
    else:
        m = always_merger.merge(m, metadata)
        if m["tags"]:
            m["tags"] = list(set(m["tags"]))

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
