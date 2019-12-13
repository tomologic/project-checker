.PHONY: build flake8-test project-check pylint-test syntax-test
.PHONY: system-test unit-test verify

build:
	docker-compose build

flake8-test: build
	docker-compose run \
	--entrypoint "flake8 --verbose --statistics --show-source --exclude test ." \
	project-checker

# since project-checker is a project checker it can be used to check
# it self
project-check: build
	docker-compose run -v ${PWD}:/project:ro project-checker

pylint-test: build
	docker-compose run \
	--entrypoint "pylint --rcfile=.pylintrc project-checker.py pathexclusion" \
	project-checker

syntax-test: pylint-test flake8-test

system-test: build
	bats system-test

unit-test: build
	docker-compose run \
	--entrypoint "python -m pytest --verbose" project-checker

verify: project-check syntax-test system-test unit-test
