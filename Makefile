ENVBIN=$(CURDIR)/.env/bin
PIP=$(ENVBIN)/pip
PYTHON=$(ENVBIN)/python
PYBABEL=$(ENVBIN)/pybabel
BABELDIR=$(CURDIR)/base/translations
MODULE=base
CONFIG=$(MODULE).config.develop

all: .env db

# target: help - Display callable targets
help:
	@egrep "^# target:" [Mm]akefile

.env: requirements.txt $(ENVBIN)
	$(PIP) install -M -r requirements.txt
	touch .env

$(ENVBIN):
	virtualenv --no-site-packages .env

# target: shell - Open application shell
.PHONY: shell
shell: .env/ manage.py
	$(PYTHON) manage.py shell -c $(CONFIG)


# target: run - Run application server
.PHONY: run
run: .env/ manage.py
	$(PYTHON) manage.py runserver -c $(CONFIG)


# target: db - Init and migrate application db
.PHONY: db
db: .env/ manage.py
	$(PYTHON) manage.py alembic upgrade head -c $(CONFIG)


# target: audit - Audit source code
.PHONY: audit
audit:
	pylama $(MODULE) -i E501


# target: test - Run tests
.PHONY: t
t: .env manage.py clean
	$(PYTHON) manage.py test -c $(MODULE).config.test


# target: clean - Clean repo
.PHONY: clean
clean:
	rm -f *.py[co] *.orig
	rm -f */*.py[co] */*.orig


# target: babel - Recompile language files
.PHONY: babel
babel: $(BABELDIR)/ru
	$(PYBABEL) extract -F $(BABELDIR)/babel.ini -k _gettext -k _ngettext -k lazy_gettext -o $(BABELDIR)/babel.pot --project Flask-base $(CURDIR)
	$(PYBABEL) update -i $(BABELDIR)/babel.pot -d $(BABELDIR)
	$(PYBABEL) compile -d $(BABELDIR)

$(BABELDIR)/ru:
	$(PYBABEL) init -i $(BABELDIR)/babel.pot -d $(BABELDIR) -l ru

.PHONY: chown
chown:
	sudo chown $(USER):$(USER) -R $(CURDIR)

.PHONY: upload
upload:
	git push
	makesite update foundation -p /var/www -H ubuntu@foundation.node42.org
