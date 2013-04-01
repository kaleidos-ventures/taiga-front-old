#!/usr/bin/env python

import sys
import getopt
import io

from jinja2 import Environment, DictLoader


def compile(args):
    try:
        _, _env = args
    except ValueError:
        _env = "dev"

    with io.open("app/templates/index.jinja", "rt") as f:
        env = Environment(loader=DictLoader({"index.html": f.read()}))

    template = env.get_template("index.html")
    ctx = {"environment": "pro" if _env == "pro" else "dev"}

    with io.open("app/index.html", "wt") as f:
        f.write(template.render(**ctx))

    print("Compilation succesfull!")
    return 0


if __name__ == "__main__":
    sys.exit(compile(sys.argv))
