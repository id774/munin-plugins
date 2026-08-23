# munin-plugins

## Contents

1. [Overview](#overview)
2. [Features](#features)
3. [Supported Environments](#supported-environments)
4. [Included Plugins](#included-plugins)
5. [Installation](#installation)
6. [Uninstallation](#uninstallation)
7. [Configuration](#configuration)
8. [Policy](#policy)
9. [Feature Reference](#feature-reference)
10. [Usage Example](#usage-example)
11. [Directory Structure](#directory-structure)
12. [Contribution](#contribution)
13. [License](#license)

## Overview

**munin-plugins** is a collection of custom Munin plugins for monitoring
system processes, services, and application-specific conditions not covered
by the default Munin plugins used by a deployment.

Each plugin is independently installable and has its own installer.

The repository currently provides:

- `process_monitoring` for configured process and iptables counts
- `systemd_failed` for failed systemd units

## Features

- POSIX `/bin/sh` plugin and installer code
- Independently installable plugins
- Munin `autoconf`, `config`, and data-fetch support
- Per-target enable/disable configuration in `process_monitoring`
- Warning and critical threshold support
- Capability-based automatic configuration checks
- Plugin runtime does not invoke `sudo`; privileged collection uses
  munin-node's per-plugin execution identity

## Supported Environments

The repository targets Linux systems with Munin-node installed and configured.

The default installation paths are:

- `/usr/local/share/munin/plugins`
- `/etc/munin/plugins`

The installers create these directories when they do not already exist.

Individual plugins can have additional capability requirements.
For example, `systemd_failed` requires a reachable systemd system manager.

## Included Plugins

### `process_monitoring`

Monitors configured process and iptables targets in one Munin graph.

The current targets are:

- iptables
- ntpd
- memcached
- postgres / postmaster
- mysqld / mariadbd
- apache2
- sshd
- xrdp

All are enabled by default except xrdp.

Target enable/disable settings are exposed through Munin `env.*`
configuration.

### `systemd_failed`

Reports the number of failed systemd units.

A healthy system reports zero. A value above zero triggers a warning.

Its autoconf check verifies that `systemctl` can query the system manager,
not merely that the executable exists.

## Installation

Each plugin has its own installer.

Install `process_monitoring`:

    ./installer/install_process_monitoring.sh

Install `systemd_failed`:

    ./installer/install_systemd_failed.sh

The installers:

- copy the matching plugin to `/usr/local/share/munin/plugins/`
- create the matching symlink in `/etc/munin/plugins/`
- create the required directories when they do not already exist
- set the plugin executable permission

Restart munin-node after installation:

    sudo systemctl restart munin-node

## Uninstallation

Remove `process_monitoring`:

    ./installer/install_process_monitoring.sh --uninstall

Remove `systemd_failed`:

    ./installer/install_systemd_failed.sh --uninstall

Each installer removes its matching installed plugin and enabled-plugin
symlink.

Restart munin-node afterward:

    sudo systemctl restart munin-node

## Configuration

Site-specific Munin plugin configuration normally lives under:

    /etc/munin/plugin-conf.d/

For example:

    [process_monitoring]
    env.postgres 0
    env.mysql 0
    env.xrdp 1

Munin plugin-conf syntax separates the directive and value with whitespace:

    env.xrdp 1

It does not use shell assignment syntax.

The plugins can contain built-in defaults. Site-specific overrides should use
the plugin's exposed `env.*` interface rather than editing the installed copy
when such an interface exists.

For the complete configuration reference, target defaults, privilege model,
systemd behavior, and troubleshooting information, see
[doc/FEATURES.md](doc/FEATURES.md).

## Policy

The repository's implementation and maintenance policy is defined in
[doc/POLICY.md](doc/POLICY.md).

It covers:

- Compatibility, Safety, and Efficiency
- change discipline for established monitoring infrastructure
- Munin protocol compatibility
- plugin and installer architecture
- configuration interfaces
- privilege and safety
- POSIX shell requirements
- validation
- versioning and documentation roles

## Feature Reference

The detailed user-facing behavior reference is
[doc/FEATURES.md](doc/FEATURES.md).

It documents:

- Munin execution modes
- plugin fields and defaults
- process target behavior
- iptables privilege configuration
- sshd and xrdp behavior
- systemd failure reporting
- installation and uninstallation
- plugin-conf syntax and troubleshooting

## Usage Example

After installation and configuration, verify a plugin through Munin's real
execution environment.

For `process_monitoring`:

    sudo munin-run process_monitoring config
    sudo munin-run process_monitoring

For `systemd_failed`:

    sudo munin-run systemd_failed config
    sudo munin-run systemd_failed

## Directory Structure

    .
    ├── plugins/
    │   ├── process_monitoring
    │   └── systemd_failed
    ├── installer/
    │   ├── install_process_monitoring.sh
    │   └── install_systemd_failed.sh
    └── doc/
        ├── POLICY.md
        ├── FEATURES.md
        ├── VERSIONS
        ├── LICENSE
        ├── COPYING
        └── COPYING.LESSER

`plugins/` contains the Munin plugins.

`installer/` contains one installer per plugin.

`doc/POLICY.md` defines repository-wide implementation and maintenance rules.

`doc/FEATURES.md` contains the detailed user-facing behavior reference.

`doc/VERSIONS` records repository release history.

The current architecture keeps each plugin independently installable with a
matching installer.

## Contribution

Contributions are welcome.

Changes must follow [doc/POLICY.md](doc/POLICY.md).

A plugin or installer implementation change should include validation for the
Munin, operating-system, shell, privilege, and configuration environments
affected by that change.

Documentation work does not expand into implementation refactoring merely
because an unrelated improvement opportunity is noticed.

## License

This repository is dual licensed under the
[GPL version 3](https://www.gnu.org/licenses/gpl-3.0.html) or the
[LGPL version 3](https://www.gnu.org/licenses/lgpl-3.0.html), at your option.

See:

- [LICENSE](doc/LICENSE)
- [COPYING](doc/COPYING)
- [COPYING.LESSER](doc/COPYING.LESSER)
