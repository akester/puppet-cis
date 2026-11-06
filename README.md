# baseline (`akester-baseline`)

OS hardening baseline for the kester.cloud fleet (mostly Debian 13), based on
the CIS Debian Linux 13 Benchmark v1.1.0. Replaces `dev-sec/puppet-os-hardening`.

Targets OpenVox 8 and 9.

## An opinionated CIS baseline

This is **not** a complete or certified implementation of the CIS Benchmark.
It follows CIS where that fits a small self-hosted fleet, and deliberately
departs from it elsewhere. Each control lands in one of these buckets:

- **Enforced:** Puppet manages the setting.
- **Monitored:** checked by a Wazuh SCA policy, not changed by Puppet
  (e.g. world-writable files, duplicate UIDs).
- **Replaced:** the intent is covered by a different control. File integrity
  monitoring and audit tracking come from Wazuh instead of AIDE and the CIS
  auditd rule set, and the host firewall is firewalld rather than ufw.
- **Not applicable:** doesn't apply to these hosts (e.g. GNOME on headless servers).
- **Omitted:** intentionally not implemented, with a reason.

The section-by-section status and the reasoning for every departure live in
[docs/cis-coverage.md](docs/cis-coverage.md).

Where a setting is enforced, its Puppet parameter and the matching Wazuh SCA
check share a stable ID (e.g. `hl-sysctl-001`), so an SCA failure points
straight at the code that fixes it.

## Usage

In the Bolt project Puppetfile:

```ruby
mod 'baseline',
  git: 'https://github.com/akester/puppet-cis.git',
  ref: 'main'
```

```puppet
include baseline
```

## Development

Tooling is the Vox Pupuli test stack (`voxpupuli-test`) on the `openvox` gem;
no PDK needed.

### In Docker (same image as CI)

```sh
make              # full `rake test` against OpenVox 8
make OPENVOX=9    # against OpenVox 9
make test-all     # both, like the CI matrix
make lint spec    # individual steps (also: syntax validate rubocop metadata)
make fix          # auto-fix puppet-lint and rubocop issues
make shell        # shell in the container
make clean        # drop cached gems and fixtures
```

Gems are cached in `vendor/docker-bundle/`; the first run takes a few
minutes. Override the image with `make IMAGE=...`.

### On the host

System packages (Debian/Ubuntu): `ruby ruby-dev ruby-bundler libffi-dev
pkg-config build-essential`, and a UTF-8 locale (`LANG=C.UTF-8`).

```sh
bundle config set --local path vendor/bundle
bundle install
bundle exec rake test          # syntax, lint, rubocop, metadata, rspec
bundle exec rake -T            # individual tasks (lint, rubocop, spec, ...)

# against a specific OpenVox major
OPENVOX_GEM_VERSION='~> 9.0' bundle update openvox && bundle exec rake spec
```

CI (`.gitlab-ci.yml`) runs `rake test` against OpenVox 8 and 9 in the
`akester/puppet` image.

## Reference material

`ref/` is gitignored and holds the CIS PDF (licensed, not redistributable)
and working notes. This repository refers to CIS recommendations by number
and title only; it does not reproduce benchmark text.

CIS® and CIS Benchmarks™ are trademarks of the Center for Internet Security.
This project is not affiliated with or endorsed by CIS.

## Use of generative AI

Parts of this repository, including code, tests, CI configuration, and
documentation, were written with the help of generative AI (Anthropic's Claude,
via Claude Code). Everything is human reviewed before commit and release.

## Repository Mirror

The public GitHub repository is a mirror of my local Git repository.  Issues and
merge requests are tracked from the public repo, but know that things like CI
tests are only run locally.
