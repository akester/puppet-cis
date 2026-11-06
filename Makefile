# Run the test tooling inside the same image CI uses.
#
#   make              # full `rake test` against OpenVox 8
#   make OPENVOX=9    # ... against OpenVox 9
#   make test-all     # both, like the CI matrix
#   make lint spec    # individual steps
#   make fix          # auto-fix puppet-lint and rubocop issues
#   make shell        # interactive shell in the container
#
# Gems are cached in vendor/docker-bundle/ (gitignored), separate from any
# host-side vendor/bundle.

IMAGE   ?= akester/puppet:latest
OPENVOX ?= 8

TTY := $(shell [ -t 1 ] && echo -t)

DOCKER_FLAGS = \
	--user $(shell id -u):$(shell id -g) \
	-v $(CURDIR):/work -w /work \
	-e HOME=/tmp \
	-e LANG=C.UTF-8 \
	-e BUNDLE_PATH=/work/vendor/docker-bundle \
	-e BUNDLE_WITHOUT=development:system_tests:release \
	-e OPENVOX_GEM_VERSION='~> $(OPENVOX).0'

DOCKER_RUN = docker run --rm -i $(TTY) $(DOCKER_FLAGS) $(IMAGE)

BUNDLE = $(DOCKER_RUN) sh -c 'bundle check >/dev/null 2>&1 || bundle install --jobs $$(nproc) --quiet; exec bundle exec "$$@"' --

.DEFAULT_GOAL := test
.PHONY: test test-all syntax validate lint rubocop metadata spec fix shell pull clean

test:
	$(BUNDLE) rake test

test-all:
	$(MAKE) test OPENVOX=8
	$(MAKE) test OPENVOX=9

syntax:
	$(BUNDLE) rake syntax

validate:
	$(BUNDLE) rake validate

lint:
	$(BUNDLE) rake lint

rubocop:
	$(BUNDLE) rake rubocop

metadata:
	$(BUNDLE) rake metadata_lint

spec:
	$(BUNDLE) rake spec

fix:
	$(BUNDLE) rake lint_fix rubocop:autocorrect

shell:
	docker run --rm -it $(DOCKER_FLAGS) $(IMAGE) bash

pull:
	docker pull $(IMAGE)

clean:
	rm -rf vendor/docker-bundle spec/fixtures/modules spec/fixtures/manifests coverage Gemfile.lock
