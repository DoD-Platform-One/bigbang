import click
from rich.console import Console

from .repo import BigBangRepo

c = Console()


@click.group()
def info():
    pass


@info.command()
def all_bb_tags():
    bb = BigBangRepo()
    tags = bb.get_tags()
    c.print(tags)
    return tags


@info.command()
def latest_bb_tag():
    bb = BigBangRepo()
    tags = bb.get_tags()
    latest = tags[0]
    c.print(latest)
    return latest
