.PHONY: all less extern app template production development

include config.mk

all: development

development: template

production: less extern app template_prod

less:
	lessc --yui-compress app/less/greenmine-main.less app/less/style.css

extern:
	uglifyjs $(EXTERN_SOURCES) -c -o app/js/extern.min.js

app:
	uglifyjs $(APP_SOURCES) -c -o app/js/greenmine.min.js

template:
	python compile.py

template_prod:
	python compile.py pro
