# munin-plugins Feature Reference

This document is the detailed user-facing behavior and capability reference
for munin-plugins.

The README provides the project overview, supported environments,
installation, basic configuration, and directory structure.

`doc/POLICY.md` defines the repository-wide implementation and maintenance
policy.

The implementation is the primary evidence of what each component currently
does, while the component header records its local operational contract and
this document records the intended user-facing behavior. A mismatch is
resolved by comparing the implementation, documented interface, history, and
maintenance intent rather than by treating an accidental implementation
detail as the specification.

## 1. Repository Structure

munin-plugins contains independently installable Munin plugins.

| Path | Role |
| --- | --- |
| `plugins/<plugin>` | Munin plugin implementation |
| `installer/install_<plugin>.sh` | Matching installer and uninstaller |
| `doc/POLICY.md` | Implementation and maintenance policy |
| `doc/VERSIONS` | Repository release history |

Each plugin can be installed and removed independently.

## 2. Munin Execution Modes

The plugins implement the Munin execution modes used by this repository.

### 2.1 Autoconf

Run:

    ./plugins/<plugin> autoconf

A successful automatic configuration check prints:

    yes

and a failed prerequisite check prints:

    no

Autoconf determines whether the plugin can establish the required
capabilities in the current environment. It does not guarantee that every
future fetch will succeed.

### 2.2 Config

Run:

    ./plugins/<plugin> config

The plugin prints Munin graph and field definitions.

This output is intended for Munin and defines graph metadata, field labels,
types, drawing style, and thresholds.

### 2.3 Fetch

Run the plugin without `autoconf` or `config` to collect values.

The result uses Munin's:

    field.value VALUE

format.

A plugin may emit:

    field.value U

when the current value cannot be determined.

## 3. `process_monitoring`

`process_monitoring` reports configured process or configuration-item counts
in one graph.

The graph is:

    graph_category processes
    graph_title Required processes
    graph_vlabel Number of required processes

The current fields are:

| Field | Default | Measurement |
| --- | ---: | --- |
| `iptables` | enabled | Count of matching iptables rules |
| `ntpd` | enabled | Processes named exactly `ntpd` |
| `memcached` | enabled | Processes named exactly `memcached` |
| `postgres` | enabled | Processes named `postgres` or `postmaster` |
| `mysql` | enabled | Processes named `mysqld` or `mariadbd` |
| `apache2` | enabled | Processes named exactly `apache2` |
| `sshd` | enabled | Processes named exactly `sshd` |
| `xrdp` | disabled | Processes named exactly `xrdp` |

Each enabled field is a GAUGE drawn as `LINE2`.

The current warning and critical threshold for each enabled target is:

    1:

so a value below 1 is considered unhealthy.

## 4. `process_monitoring` Configuration

Each target can be enabled or disabled through Munin plugin configuration.

The built-in defaults are equivalent to:

    [process_monitoring]
    env.iptables 1
    env.ntpd 1
    env.memcached 1
    env.postgres 1
    env.mysql 1
    env.apache2 1
    env.sshd 1
    env.xrdp 0

`1` enables the target.

`0` disables the target.

Only values that differ from the defaults need to be listed.

For example:

    [process_monitoring]
    env.postgres 0
    env.mysql 0
    env.xrdp 1

Munin plugin-conf syntax uses whitespace:

    env.xrdp 1

Do not write:

    env.xrdp=1

or:

    env.xrdp = 1

A malformed directive can cause munin-node to stop reading the remainder of
that plugin configuration file.

Verify parsing with:

    sudo munin-run process_monitoring config

Disabled targets do not appear as fields in the plugin's `config` output.

## 5. iptables Monitoring and Privilege

The iptables target reads firewall rules.

The plugin itself does not invoke `sudo`.

When iptables monitoring requires root privileges, configure munin-node to
run the plugin as root:

    [process_monitoring]
    user root

Restart munin-node after changing plugin configuration:

    sudo systemctl restart munin-node

Then verify the real Munin execution environment with:

    sudo munin-run process_monitoring

Do not grant the munin account unrestricted sudo access to `/sbin/iptables`.

A rule such as:

    munin ALL=(ALL) NOPASSWD: /sbin/iptables

permits state-changing commands such as:

    iptables -F

and is broader than the read-only monitoring requirement.

If an earlier installation added that sudoers rule, remove it.

If running the complete plugin as root is not acceptable, disable the target:

    [process_monitoring]
    env.iptables 0

### 5.1 Separate Privileged Symlink

A deployment can split the privileged iptables collection into another Munin
plugin instance by creating a second symlink:

    sudo ln -s /usr/local/share/munin/plugins/process_monitoring \
        /etc/munin/plugins/process_monitoring_iptables

and configuring:

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

This separates the privileged target but also creates a separate Munin graph.

## 6. sshd Monitoring

The `sshd` target counts processes whose command name is exactly:

    sshd

On traditional OpenSSH operation, the listener is counted.

On OpenSSH versions before 9.8, active connections may also appear as
additional `sshd` processes.

OpenSSH 9.8 and later uses the `sshd-session` name for per-connection child
processes, so those children are not included in the exact `sshd` count.

When SSH is socket-activated through `ssh.socket` or `sshd.socket`, no
persistent `sshd` listener may exist while the system is idle. In that
environment the target can report zero even though SSH is intentionally
available.

Disable the target on such a host with:

    [process_monitoring]
    env.sshd 0

## 7. xrdp Monitoring

The `xrdp` target is disabled by default.

Enable it with:

    [process_monitoring]
    env.xrdp 1

The target counts processes named exactly:

    xrdp

The separate `xrdp-sesman` process is not counted.

## 8. `systemd_failed`

`systemd_failed` reports the number of failed systemd units.

Its graph is:

    graph_category system
    graph_title Failed systemd units
    graph_vlabel Number of failed units

The field is:

    failed

and is a GAUGE drawn as `LINE2`.

A healthy system reports:

    failed.value 0

The warning threshold is:

    failed.warning 0

so a value above zero is warning state.

## 9. `systemd_failed` Autoconf

Autoconf requires the commands used by the plugin and verifies that
`systemctl` can query the system manager.

Run:

    ./plugins/systemd_failed autoconf

A usable systemd environment reports:

    yes

A missing or unreachable system manager reports:

    no

The check is capability-based: the presence of the `systemctl` executable
alone is not treated as sufficient.

## 10. `systemd_failed` Fetch Failure

During normal data collection, the plugin runs:

    systemctl list-units --state=failed --no-legend --plain

If the system manager cannot be queried, the plugin reports the Munin unknown
value:

    failed.value U

rather than inventing a numeric count.

## 11. Installation

Each plugin has its own installer.

Install `process_monitoring` with:

    ./installer/install_process_monitoring.sh

Install `systemd_failed` with:

    ./installer/install_systemd_failed.sh

The installers use the following default paths:

    /usr/local/share/munin/plugins
    /etc/munin/plugins

The plugin file is copied to the first directory and an enabled-plugin symlink
is created in the second.

The installers create the directories when they do not already exist.

After installation, restart munin-node with the service-management mechanism
used by the host. On a systemd-based host:

    sudo systemctl restart munin-node

## 12. Uninstallation

Remove `process_monitoring` with:

    ./installer/install_process_monitoring.sh --uninstall

Remove `systemd_failed` with:

    ./installer/install_systemd_failed.sh --uninstall

Each installer removes only its matching plugin file and matching enabled
symlink.

## 13. Installed Files and Local Customization

An installer overwrites the installed destination plugin when that plugin file
already exists.

Therefore, editing:

    /usr/local/share/munin/plugins/<plugin>

directly is not a persistent site-configuration mechanism.

Use `plugin-conf.d` for settings that the plugin exposes through environment
variables.

Changing target definitions, field labels, thresholds, or implementation
logic is source customization rather than ordinary site configuration and
belongs in the maintained source when it is intended to survive
reinstallation.

## 14. Troubleshooting `plugin-conf.d`

If a target continues to use its built-in default after editing
`/etc/munin/plugin-conf.d/`, first verify directive syntax.

Correct:

    env.xrdp 1

Incorrect:

    env.xrdp=1

Incorrect:

    env.xrdp = 1

Run:

    sudo munin-run process_monitoring config

and confirm that no malformed-line warning is printed.

When configuration parses correctly, enabled targets appear in the `config`
output and disabled targets do not.

Restart munin-node with the service-management mechanism used by the host
after changing its configuration.

## 15. Existing RRD Data

Disabling a target stops new field definition and collection from the plugin,
but existing Munin RRD data is not automatically removed.

As a result, an old graph series can remain visible until the corresponding
RRD data is removed or ages out according to the Munin deployment.

## 16. Finding a Capability

| Goal | Plugin or component |
| --- | --- |
| Monitor process counts | `process_monitoring` |
| Monitor matching iptables rules | `process_monitoring` |
| Enable or disable a process target | `plugin-conf.d` `env.*` setting |
| Run iptables monitoring with privilege | `plugin-conf.d` `user root` |
| Detect failed systemd units | `systemd_failed` |
| Verify plugin configuration through Munin | `munin-run` |
| Install `process_monitoring` | `installer/install_process_monitoring.sh` |
| Install `systemd_failed` | `installer/install_systemd_failed.sh` |
| Remove a plugin | Matching installer with `--uninstall` |
