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

The currently included plugins are summarized in
[Included Plugins](#included-plugins). Their detailed behavior,
configuration, defaults, and execution semantics are maintained in
[doc/FEATURES.md](doc/FEATURES.md).

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

Its target definitions, defaults, thresholds, privilege requirements, and
Munin configuration are maintained in
[doc/FEATURES.md](doc/FEATURES.md#3-process_monitoring).

### `systemd_failed`

Reports failed systemd units through Munin.

Its value semantics, thresholds, and autoconf behavior are maintained in
[doc/FEATURES.md](doc/FEATURES.md#8-systemd_failed).

## Installation

Each plugin has its own installer. Use the plugin name shown in
[Included Plugins](#included-plugins) and run the matching file under
`installer/`, whose name is `install_<plugin>.sh`.

The installers:

- copy the matching plugin to `/usr/local/share/munin/plugins/`
- create the matching symlink in `/etc/munin/plugins/`
- create the required directories when they do not already exist
- set the plugin executable permission

Restart munin-node with the service-management mechanism used by the host.
On a systemd-based host:

    sudo systemctl restart munin-node

## Uninstallation

To remove a plugin, run the same matching installer with the `--uninstall`
option.

Each installer removes its matching installed plugin and enabled-plugin
symlink.

Restart munin-node afterward with the service-management mechanism used by
the host. On a systemd-based host:

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
execution environment:

    sudo munin-run <plugin> config
    sudo munin-run <plugin>

Use one of the plugin names shown in
[Included Plugins](#included-plugins). Plugin-specific behavior and
configuration are documented in [doc/FEATURES.md](doc/FEATURES.md).

## Directory Structure

    .
    ├── plugins/              Munin plugin implementations.
    ├── installer/            Matching install/uninstall scripts.
    └── doc/
        ├── POLICY.md
        ├── FEATURES.md
        ├── VERSIONS
        ├── LICENSE
        ├── COPYING
        └── COPYING.LESSER

The README does not duplicate the current file inventory under `plugins/`
and `installer/`. The included plugin names are summarized above, and their
detailed behavior is maintained in
[doc/FEATURES.md](doc/FEATURES.md).

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
