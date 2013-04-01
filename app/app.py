# -*- coding: utf-8 -*-

import os
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
})


@app.route('/')
def index():
    return render_template('index.jinja')


if __name__ == '__main__':
    app.debug = True
    app.run()

