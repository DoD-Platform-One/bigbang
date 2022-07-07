from pathlib import Path
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