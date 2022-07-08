import json
import re
import shutil
from pathlib import Path

import frontmatter
from deepmerge import always_merger
from jinja2 import Template
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
            print(f":warning:  No values table found in {from_readme}")
            shutil.copy2(from_readme, to_readme)
            return

    with open(to_readme, "w") as f:
        content = re.sub(r"^#\s.*?\n", "", content)
        for table in values_tables:
            content = content.replace(
                table, "\n\nPlease see the [values](values.md) docs.\n\n"
            )
        f.write(content)
        f.close()

    with open(to_values, "w") as f:
        for table in values_tables:
            rows = table.split("\n")[2:-2]
            header = [ele.strip() for ele in rows[0].split("|")[1:-1]]
            values = []

            for i, row in enumerate(rows[2:]):
                data = dict(zip(header, [ele.strip() for ele in row.split("|")[1:-1]]))
                data["Default"] = data["Default"].replace("`", "")
                if data["Type"] == "list" or data["Type"] == "object":
                    data["Default"] = json.dumps(data["Default"])

                    if len(data["Default"]) == 4:
                        data["Default"] = data["Default"][1:-1]
                    data["language"] = "json"
                else:
                    data["language"] = "yaml"

                values.append(data)

            f.write(values_template.render(values=values, title=title))

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
