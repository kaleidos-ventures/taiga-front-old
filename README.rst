Taiga Front
===============

.. image:: http://kaleidos.net/static/img/badge.png
    :target: http://kaleidos.net/community/taiga/
.. image:: https://travis-ci.org/taigaio/taiga-front.svg?branch=master
    :target: https://travis-ci.org/taigaio/taiga-front
.. image:: https://coveralls.io/repos/taigaio/taiga-front/badge.png?branch=master
    :target: https://coveralls.io/r/taigaio/taiga-front?branch=master

Setup initial environment
-------------------------

Install requirements:

.. code-block:: console

    sudo npm install -g gulp
    npm install
    sudo npm install -g bower
    bower install
    gulp

And go in your browser to: http://localhost:9001/

How to run e2e tests
--------------------

To run the e2e tests you have to install protractor globaly, update your
web-driver manager, start the web-driver, start de application, and run the e2e
tests:

.. code-block:: console

    sudo npm install -g protractor
    sudo web-driver update
    sudo web-driver start
    # ASSURE THAT YOUR TAIGA INSTANCE IS RUNNING
    gulp e2e-test
