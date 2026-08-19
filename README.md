# munin-plugins

## Contents

1. [Overview](#overview)
2. [Features](#features)
3. [Supported Environments](#supported-environments)
4. [Included Plugins](#included-plugins)
5. [Installation](#installation)
6. [Uninstallation](#uninstallation)
7. [Configuration](#configuration)
8. [Usage Example](#usage-example)
9. [Directory Structure](#directory-structure)
10. [Contribution](#contribution)
11. [License](#license)

## Overview

**munin-plugins** is a collection of custom Munin plugins designed to monitor system processes, services, and application-specific metrics not covered by default Munin plugins.

Each plugin is standalone and managed independently within this single repository. Every plugin ships with its own installer, so you can install or remove only the ones you need.

This repository currently includes `process_monitoring`, which checks the presence of essential processes, and `systemd_failed`, which reports the number of failed systemd units. More plugins may be added in the future to expand monitoring capabilities.

## Features

- **Lightweight and POSIX-compliant shell scripting**
- **Standalone plugins, each with its own installer for independent management**
- **Per-target enable/disable via toggle variables (process_monitoring)**
- **Customizable for monitoring any daemon or system process**
- **Warning and critical threshold support**
- **No sudo required: privileged checks use munin-node's per-plugin `user` setting**

## Supported Environments

This plugin is intended for use on:

- **Linux (Debian, Ubuntu, CentOS, etc.)**
- Munin-node installed and configured
- Environments with `/usr/local/share/munin/plugins` and `/etc/munin/plugins/` available
- Privileged checks (e.g., iptables monitoring) configured via `/etc/munin/plugin-conf.d/`

## Included Plugins

### `process_monitoring`

Monitors the number of active processes or configuration items (like iptables rules) and reports them all in a single graph. Each target (iptables, ntpd, memcached, postgres, mysql, apache2, sshd, xrdp) can be individually enabled or disabled via toggle variables. All targets are enabled by default except `xrdp`, which must be turned on explicitly with `env.xrdp 1`.

Note that the `sshd` target counts running `sshd` processes. If `sshd` is socket-activated (systemd `ssh.socket` / `sshd.socket`, the default on recent Ubuntu releases), no listener runs while the system is idle, so the target reports 0 and trips the critical threshold. Set `env.sshd 0` on such hosts.

### `systemd_failed`

Monitors the number of failed systemd units reported by `systemctl` and reports it in a single graph. A healthy system reports 0, and any value of 1 or more triggers a warning. It detects services that started but later crashed or exited abnormally, which process presence checks cannot catch. Its automatic configuration check enables the plugin only when `systemctl` can query the system manager.

## Installation

Each plugin has its own installer. Run the installer for the plugin you want:

```sh
./installer/install_process_monitoring.sh
./installer/install_systemd_failed.sh
```

This will:

- Copy the plugin to `/usr/local/share/munin/plugins/`
- Create a symlink in `/etc/munin/plugins/`
- Set executable permissions

## Uninstallation

To remove all installed components of a plugin, run its installer with `--uninstall`:

```sh
./installer/install_process_monitoring.sh --uninstall
./installer/install_systemd_failed.sh --uninstall
```

This will:

- Delete the plugin from `/usr/local/share/munin/plugins/`
- Remove the symlink from `/etc/munin/plugins/`

Make sure to restart `munin-node` afterward:

```sh
sudo systemctl restart munin-node
```

## Configuration

Install the plugin with a single symlink:

```sh
sudo ln -s /usr/local/share/munin/plugins/process_monitoring /etc/munin/plugins/process_monitoring
```

Then restart `munin-node`:

```sh
sudo systemctl restart munin-node
```

Each target is enabled or disabled with its own toggle variable, set via
`/etc/munin/plugin-conf.d/local`. The following block lists every target at its
default value, so it can be copied in as-is and edited in place:

```
[process_monitoring]
env.iptables 1
env.ntpd 1
env.memcached 1
env.postgres 1
env.mysql 1
env.apache2 1
env.sshd 1
env.xrdp 0
```

`1` enables a target, `0` disables it. All targets default to `1` except `xrdp`,
which defaults to `0`. Listing every variable is optional — anything left out
keeps its default — so a minimal configuration that turns off the two database
targets and turns on xrdp is just:

```
[process_monitoring]
env.postgres 0
env.mysql 0
env.xrdp 1
```

Restart `munin-node` afterwards, since plugin configuration is read at startup.

**Separate the name and the value with whitespace, not `=`.** Munin's
plugin-conf.d parser accepts only `env.NAME VALUE`. `env.xrdp=1` is rejected,
and `env.xrdp = 1` assigns the literal value `= 1`. This is the most common
reason the toggles appear to be ignored — see
[Troubleshooting](#troubleshooting-the-toggles-have-no-effect) below.

### Granting privileges for iptables monitoring

Listing firewall rules requires root. **The plugin does not call `sudo`.** Instead,
grant the privilege through munin-node itself: munin-node runs as root and drops
privileges separately for each plugin, so it can simply be told to keep root for
this one.

Add the following to `/etc/munin/plugin-conf.d/local` (create the file if it does
not exist; any filename in that directory works, and the section name must match
the plugin's symlink name):

```
[process_monitoring]
user root
```

Restart munin-node so the new setting is read:

```sh
sudo systemctl restart munin-node
```

Then verify that the plugin can actually read the rules. `munin-run` applies the
same `plugin-conf.d` settings that munin-node uses, so this reproduces the real
execution environment:

```sh
sudo munin-run process_monitoring
```

A working setup prints a non-zero `iptables.value`. If it prints `iptables.value 0`
while your firewall is populated, the plugin is still running unprivileged — check
that the section name matches the symlink in `/etc/munin/plugins/` and that
munin-node was restarted.

#### Do not use a sudoers rule

Earlier versions of this plugin invoked `sudo iptables` and documented a sudoers
entry such as:

```sh
# DO NOT USE - kept here only so it can be recognized and removed
munin ALL=(ALL) NOPASSWD: /sbin/iptables
```

That rule is unrestricted: it permits any `iptables` invocation, including
`iptables -F`, which flushes the firewall. Granting it to the munin account turns
a read-only monitoring need into an effective privilege escalation path. If you
configured it for a previous version, remove it:

```sh
sudo visudo
```

If running the whole plugin as root is not acceptable in your environment, disable
the iptables target instead with `env.iptables 0` and monitor the firewall
separately.

#### Narrowing the privilege further (optional)

`user root` applies to the entire plugin, including the process counting targets
that do not need it. If you prefer to keep the privilege scoped, install a second
symlink dedicated to iptables and grant root only to that one:

```sh
sudo ln -s /usr/local/share/munin/plugins/process_monitoring /etc/munin/plugins/process_monitoring_iptables
```

```
[process_monitoring]
user munin
env.iptables 0

[process_monitoring_iptables]
user root
env.iptables 1
env.ntpd 0
env.memcached 0
env.postgres 0
env.mysql 0
env.apache2 0
env.sshd 0
env.xrdp 0
```

This produces two graphs, so adopt it only if the separation is worth the extra
graph.

### Troubleshooting: the toggles have no effect

If the plugin keeps reporting its built-in defaults after you edited
`/etc/munin/plugin-conf.d/local`, check the syntax of the file first. Munin
parses each directive as `NAME VALUE` separated by whitespace:

```
env.xrdp 1      # correct
env.xrdp=1      # rejected: the line does not parse
env.xrdp = 1    # parses, but the value becomes "= 1", not "1"
```

A rejected line is not skipped in isolation. munin-node stops reading the file
at that point and discards every directive after it, so a `user root` placed
below a malformed `env.` line stops applying as well, and the iptables target
starts reporting 0.

Run the plugin the way munin-node does to see the parse error:

```sh
sudo munin-run process_monitoring config
```

A malformed file reports something like:

```
Line is not well formed (env.xrdp=1) at /etc/munin/plugin-conf.d/local line 3. Skipping the rest of the file
```

Once the file parses cleanly, the `config` output reflects the toggles: disabled
targets have no `*.label` line, and enabled ones do. Restart `munin-node` so the
node itself picks up the change:

```sh
sudo systemctl restart munin-node
```

Two further points if `config` already looks right but the graph does not:

- Newly enabled targets appear on the master's next run (up to five minutes).
- Disabled targets keep their existing RRD files, so the master may keep drawing
  the old data series until those files are removed from
  `/var/lib/munin/<group>/<host>-<plugin>-<field>-g.rrd`.

## Usage Example

Once installed and symlinked, Munin will collect and graph the number of monitored processes such as `iptables`, `ntpd`, and `memcached`.

The plugin is invoked as `process_monitoring` and provides a single graph showing the status of all defined targets in one view.

You can customize which processes to monitor by editing the plugin script itself.

## Directory Structure

This section describes the main directories of the repository and what each one
is for. It is not a complete file listing: only the entries worth knowing about
before installing or adding a plugin are shown.

```
.
├── plugins/                           The plugins themselves, one POSIX shell script each.
│   ├── process_monitoring             Counts processes and iptables rules per target.
│   └── systemd_failed                 Counts failed systemd units.
├── installer/                         One installer per plugin, each also handling --uninstall.
│   ├── install_process_monitoring.sh
│   └── install_systemd_failed.sh
└── doc/
    ├── VERSIONS                       Version history of the repository.
    ├── LICENSE                        License notice.
    ├── COPYING                        GPL version 3 text.
    └── COPYING.LESSER                 LGPL version 3 text.
```

The layout is deliberately flat: a plugin is a single file under `plugins/` with
a matching `installer/install_<name>.sh`, and nothing is shared between plugins.
That is what makes them installable and removable one at a time. A new plugin is
added as that same pair of files.

A plugin script carries no configuration of its own. Everything a site changes
lives outside the repository, in `/etc/munin/plugin-conf.d/` — see
[Configuration](#configuration).

## Contribution

Contributions are welcome. You can help by:
- Creating new plugins and submitting pull requests
- Improving installation or configuration scripts
- Reporting bugs or feature requests

Please follow the style and format used in this repository, and include documentation and examples for any new plugin.

## License

This repository is dual licensed under the [GPL version 3](https://www.gnu.org/licenses/gpl-3.0.html) or the [LGPL version 3](https://www.gnu.org/licenses/lgpl-3.0.html), at your option.
For full details, please refer to the [LICENSE](doc/LICENSE) file.  See also [COPYING](doc/COPYING) and [COPYING.LESSER](doc/COPYING.LESSER) for the complete license texts.

Thank you for using and contributing to this repository!
