greenmine-front
===============

Setup initial environment
-------------------------

Install requirements:

.. code-block:: console

    pip install -r requirements.txt
    python app/app.py


Also, you can serve this congent over nginx, for this way you
need compile a index.html from jinja2 template. Do this executing
make on repo root directory:

.. code-block:: console

    make


Point your nginx or apache to **app/** directory.
