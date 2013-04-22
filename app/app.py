# -*- coding: utf-8 -*-

import os
import sys
import random

from werkzeug import SharedDataMiddleware

from flask import Flask
from flask import render_template


app = Flask(__name__)
app.wsgi_app = SharedDataMiddleware(app.wsgi_app, {
    '/js': os.path.join(os.path.dirname(__file__), 'js'),
    '/less': os.path.join(os.path.dirname(__file__), 'less'),
    '/img': os.path.join(os.path.dirname(__file__), 'img'),
    '/fonts': os.path.join(os.path.dirname(__file__), 'fonts'),
    '/partials': os.path.join(os.path.dirname(__file__), 'partials'),
    '/tmpresources': os.path.join(os.path.dirname(__file__), 'tmpresources'),
})


@app.route('/')
def index():
    ctx = {"n": random.randint(1, 20000), "development": app.debug}
    return render_template('index.jinja', **ctx)


if __name__ == '__main__':
    if len(sys.argv) == 2 and sys.argv[1] == "pro":
        app.debug = False
    else:
        app.debug = True
    app.run()

