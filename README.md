# munin-plugins

## Overview

**munin-plugins** is a collection of custom Munin plugins designed to monitor system processes, services, and application-specific metrics not covered by default Munin plugins.

Currently, this repository includes the `process_monitoring` plugin, which checks for the presence and status of essential processes such as `iptables`, `ntpd`, and `memcached`. It helps ensure that critical services are running and properly configured on your server.

More plugins may be added in the future to expand monitoring capabilities.

## Features

- **Lightweight and POSIX-compliant shell scripting**
- **Pluggable architecture using symlinks**
- **Customizable to monitor any daemon or process**
- **Warning and critical threshold support**
- **Sudo-aware for iptables rule checks**

## Supported Environments

This plugin is intended for use on:

- **Linux (Debian, Ubuntu, CentOS, etc.)**
- Munin-node installed and configured
- `/usr/local/share/munin/plugins` and `/etc/munin/plugins/` available
- `sudo` privileges configured if required for certain checks (e.g., iptables)

## Included Plugin

### `process_monitoring`

Monitors the number of active processes or configuration items (like iptables rules). This plugin can be symlinked multiple times with different names (e.g., `files_iptables`, `files_ntpd`, etc.) to monitor specific components individually.

## Installation

To install `process_monitoring`, execute the provided installation script:

```sh
./install_process_monitoring.sh
```

This will:

- Copy the plugin to `/usr/local/share/munin/plugins/`
- Create a symlink in `/etc/munin/plugins/`
- Set executable permissions

## Configuration

To enable monitoring of specific services, create symbolic links with appropriate names:

```sh
sudo ln -s /usr/local/share/munin/plugins/process_monitoring /etc/munin/plugins/process_monitoring
```

Then restart `munin-node`:

```sh
sudo systemctl restart munin-node
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

Once installed and symlinked, Munin will collect and graph the number of running processes (or presence of iptables rules) for each defined target.

Each target is graphed separately (e.g., `files_iptables`, `files_ntpd`) with warning/critical thresholds defined in the plugin.

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
