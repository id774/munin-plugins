# munin-plugins

## Overview

**munin-plugins** is a collection of custom Munin plugins designed to monitor system processes, services, and application-specific metrics not covered by default Munin plugins.

Currently, this repository includes the `process_monitoring` plugin, which checks for the presence and status of essential processes such as `iptables`, `ntpd`, and `memcached`. It helps ensure that critical services are running and properly configured on your system.

More plugins may be added in the future to expand monitoring capabilities.

## Features

- **Lightweight and POSIX-compliant shell scripting**
- **Single plugin with per-target enable/disable via toggle variables**
- **Customizable for monitoring any daemon or system process**
- **Warning and critical threshold support**
- **Sudo-aware for iptables rule checks**

## Supported Environments

This plugin is intended for use on:

- **Linux (Debian, Ubuntu, CentOS, etc.)**
- Munin-node installed and configured
- Environments with `/usr/local/share/munin/plugins` and `/etc/munin/plugins/` available
- `sudo` privileges configured for Munin if necessary (e.g., iptables monitoring)

## Included Plugin

### `process_monitoring`

Monitors the number of active processes or configuration items (like iptables rules) and reports them all in a single graph. Each target (iptables, ntpd, memcached, postgres, mysql, apache2) can be individually enabled or disabled via toggle variables.

## Installation

To install `process_monitoring`, execute the provided installation script:

```sh
./install_process_monitoring.sh
```

This will:

- Copy the plugin to `/usr/local/share/munin/plugins/`
- Create a symlink in `/etc/munin/plugins/`
- Set executable permissions

## Uninstallation

To remove all installed components of `process_monitoring`, run:

```sh
./install_process_monitoring.sh --uninstall
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

To enable or disable specific targets (`iptables`, `ntpd`, `memcached`, `postgres`, `mysql`, `apache2`), set the corresponding toggle variable via `/etc/munin/plugin-conf.d/local`:

```
[process_monitoring]
env.iptables=0
env.mysql=0
```

If monitoring iptables rules, ensure you configure `sudoers` accordingly:

```sh
sudo visudo
```

Add the following line:

```sh
munin ALL=(ALL) NOPASSWD: /sbin/iptables
```

## Usage Example

Once installed and symlinked, Munin will collect and graph the number of monitored processes such as `iptables`, `ntpd`, and `memcached`.

The plugin is invoked as `process_monitoring` and provides a single graph showing the status of all defined targets in one view.

You can customize which processes to monitor by editing the plugin script itself.

## Repository Structure

```
.
├── process_monitoring             # Munin plugin script
├── install_process_monitoring.sh  # Installer script
```

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
