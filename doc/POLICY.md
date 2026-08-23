# munin-plugins Implementation and Maintenance Policy

This document defines the implementation and maintenance policy of this
repository.

munin-plugins is a collection of independently installable Munin plugins.
The repository contains plugin programs under `plugins/` and one installer
for each plugin under `installer/`.

## 1. Core Principles

### 1.1 Decision Priorities

When requirements compete, make the design decision in this order:

1. **Compatibility**
2. **Safety**
3. **Efficiency**

This is a priority order, not an equally weighted checklist.

**Compatibility** means preserving normal and intended observable behavior
and keeping the supported execution environments working. In this repository
that includes Munin protocol output, plugin names, enabled symlink names,
field identifiers, configuration variable names and defaults, graph
semantics, thresholds, installer paths, installation behavior, and the
documented POSIX shell compatibility target.

Compatibility does not mean preserving whatever the current implementation
happens to do. A clear bug, regression, unintended side effect, or broken
behavior is not preserved merely because it already exists.

**Safety** comes after Compatibility and before Efficiency. In this repository
it includes avoiding unnecessary privilege, keeping monitoring operations from
changing system state unnecessarily, restricting installer changes to their
intended plugin and paths, and avoiding privilege grants broader than the
monitoring operation requires.

**Efficiency** means avoiding unnecessary processing, process creation, I/O,
external command execution, and resource consumption. Efficiency does not
justify weakening Compatibility or Safety.

Changes to supported environments, compatibility interfaces, repository
release versions, deliberate retirement of established behavior, and
repository-wide architecture are maintainer decisions.

### 1.2 Change Discipline for Established Infrastructure

Finding a possible safety, compatibility, portability, maintainability,
cleanup, or refactoring improvement does not by itself authorize an
implementation change.

Documentation work, policy work, review, diagnostics, cleanup, or another
task whose stated scope does not include an implementation change must not
expand into one merely because an improvement opportunity is discovered.

A safety-motivated change is not automatically justified by Safety having
priority over Efficiency. Added complexity can itself create new failure
modes, compatibility risk, operational risk, and maintenance cost. Evaluate
the proposed change as a whole.

Before changing established behavior, weigh the probability and impact of the
failure being prevented against the added complexity, new failure modes,
compatibility risk, operational cost, maintenance cost, and rollback cost.

Behavior that has operated reliably over time is evidence and has value of
its own. Do not refactor established monitoring or installation
infrastructure merely because another design appears cleaner, more modern, or
more defensive.

An implementation change is made only when that change has been explicitly
chosen as part of the work being performed. Before deployment, validate it in
the supported and representative Munin, operating-system, shell, privilege,
and configuration environments affected by the change. A successful check in
one convenient environment is not sufficient evidence for a change whose
compatibility or operational risk extends to other supported environments.

### 1.3 Wording Strength

Reserve absolute wording such as `must`, `always`, and `never` for an
invariant that admits no reasonable exception.

Use wording such as `prefer`, `should`, or `when appropriate` for a design
preference or situational rule.

A rule must not be written so that applying its wording literally produces a
result contrary to Compatibility, Safety, or Efficiency. Where wording and
purpose conflict, the priorities and intended behavior defined above govern.

This is not a formal MUST/SHOULD/MAY taxonomy.

## 2. Documentation Roles and Sources of Truth

The documentation structure of this repository is:

- `doc/POLICY.md` records the repository-wide implementation and maintenance
  policy.
- `doc/FEATURES.md` is the detailed user-facing behavior and capability
  reference.
- `README.md` provides the project overview, supported environments,
  installation, basic configuration, directory structure, and navigation to
  the detailed documents.
- `doc/VERSIONS` records release-level repository history.
- A plugin header records Munin metadata and the local operational contract of
  that plugin.
- An installer header records the local user-facing contract and version
  history of that installer.

The implementation is the primary evidence of what currently happens. It is
not, by itself, proof that the current behavior is the intended
specification.

When implementation and documentation disagree, compare the implementation,
documented interface, component header, history, existing design, and
maintenance intent. If the implementation contains a regression, do not adopt
that regression as the specification merely because it is present in the
current code.

## 3. Repository Architecture

The current architecture is a set of independently installable plugin and
installer pairs.

A plugin lives under:

    plugins/<name>

and its installer lives under:

    installer/install_<name>.sh

Each plugin has one clear monitoring responsibility. A change that belongs to
an existing responsibility remains in that plugin. An independent new
monitoring responsibility uses a new plugin.

Routine changes preserve the ability to install and remove plugins
independently.

Introducing a shared runtime dependency, a common loader, or another
repository-wide runtime layer changes the installation and deployment model
and is therefore an explicit repository architecture decision, not a routine
refactoring.

## 4. Munin Plugin Contract

A Munin plugin in this repository has three operational modes relevant to
Munin:

- `autoconf`
- `config`
- normal data fetch

### 4.1 `autoconf`

`autoconf` reports whether the plugin can determine that its required
capabilities are available in the current environment.

The expected result is `yes` or `no`.

Autoconf checks capabilities that can be established safely and meaningfully
at configuration time. It does not claim to prove that every later data
collection will succeed.

### 4.2 `config`

`config` writes Munin graph and field definitions.

Its standard output is a machine-readable interface consumed by Munin.
Arbitrary human-readable diagnostic text must not be mixed into that output.

### 4.3 Data Fetch

Normal invocation writes Munin field values such as:

    field.value VALUE

A plugin may use Munin's unknown value `U` when it cannot obtain a valid
measurement and that behavior is part of the plugin's established interface.

Standard output used for Munin protocol data is not a general-purpose log
stream. Diagnostic output must not corrupt the protocol consumed by Munin.

## 5. Compatibility Interfaces

The following are compatibility interfaces when they are exposed by an
existing plugin or installer:

- plugin file names
- enabled symlink names
- Munin field identifiers
- graph and field semantics
- warning and critical threshold semantics
- `env.*` configuration names
- built-in configuration defaults
- plugin-conf section naming where the symlink name determines it
- autoconf behavior
- config output semantics
- fetch output semantics
- installation paths
- uninstall paths and scope

Do not rename or repurpose one of these merely as a cleanup or internal
refactoring.

A human-readable label and a Munin field identifier are distinct concepts.
Changing a field identifier can affect the time series associated with that
field and is not treated as an ordinary variable rename.

## 6. Configuration

Site-specific Munin configuration normally lives under:

    /etc/munin/plugin-conf.d/

A plugin may contain built-in defaults. A site-specific override does not
require editing the repository copy when the plugin exposes an `env.*`
configuration interface.

For `process_monitoring`, the built-in target defaults and the corresponding
`env.*` variables are part of the established configuration interface.

Munin plugin-conf directives use whitespace between the directive name and
its value:

    env.NAME VALUE

They do not use shell assignment syntax.

The repository distinguishes:

- built-in plugin defaults,
- site-specific `plugin-conf.d` overrides,
- and source customization that changes the plugin's definitions,
  thresholds, labels, or implementation.

An installed plugin file may be overwritten by its installer. Editing the
installed destination directly is therefore not a persistent configuration
mechanism.

## 7. Privilege and Safety

Monitoring code does not acquire privilege by invoking `sudo` from the plugin
itself.

When a plugin requires a different execution identity, use Munin's per-plugin
execution configuration, such as:

    user root

in `plugin-conf.d`.

Do not introduce a blanket sudoers command grant merely to let a monitoring
plugin perform a privileged read operation. A grant that permits unrestricted
use of a state-changing command creates a larger privilege surface than the
monitoring operation requires.

If a privileged target is optional, disabling that target is a valid
configuration when the required privilege is not acceptable.

Running an entire plugin under a privileged identity and splitting a
privileged target into a separately enabled symlink have different
operational costs. The repository documents those choices without declaring
one universally correct for every deployment.

## 8. POSIX Shell and Environment Detection

Project-owned shell syntax, parameter expansion, function syntax, and
shell-language behavior target POSIX `/bin/sh`.

Do not introduce bash-only constructs such as arrays, `[[ ... ]]`, the
`function` keyword, `source`, or process substitution into plugin or installer
code.

POSIX shell compatibility does not mean that every external utility and every
utility option used by every plugin must itself be specified by POSIX.

A plugin may depend on an external facility required by the capability it
monitors.

Detect an optional capability from what the environment can actually provide
rather than from a distribution name when capability detection answers the
question directly.

`systemd_failed`, for example, depends on a reachable systemd system manager
and therefore checks whether `systemctl` can query it.

Repository-level Linux support does not imply that every plugin is applicable
to every Linux installation. Plugin-specific requirements are documented by
the plugin and the feature reference.

## 9. Plugin Headers and Comments

Munin metadata such as:

    #%# family=contrib
    #%# capabilities=autoconf

is machine-readable plugin metadata and is not an ordinary explanatory
comment.

Do not remove, reformat into another meaning, or treat such metadata as
decorative prose.

A plugin header records the plugin's purpose, configuration, operating notes,
examples, relevant privilege requirements, and its own version history.

Ordinary implementation comments explain reasons, constraints, or
non-obvious behavior. Do not add comments that merely restate the code.

When a comment or header describes observable behavior, keep it consistent
with the implementation when that implementation is deliberately changed.

## 10. Installer Policy

Each plugin currently has its own installer.

An installer:

- is an executable POSIX `/bin/sh` program,
- installs only its matching plugin,
- creates the matching Munin enabled-plugin symlink,
- supports uninstallation of that plugin and symlink,
- checks the commands and privilege required by its execution path,
- uses the established installation paths documented by the repository,
- and keeps its own version history independently of the repository release
  version.

The current default plugin source installation directory is:

    /usr/local/share/munin/plugins

and the enabled-plugin symlink directory is:

    /etc/munin/plugins

The installer may create these directories when they do not already exist.
Their prior existence is not a repository support prerequisite.

Uninstallation removes only the matching plugin and matching symlink managed
by that installer.

A documentation-only, comment-only, or formatting-only change does not
require an installer version increment.

A user-visible installation, uninstallation, CLI, safety, or significant
structural change may form an installer release.

## 11. Validation

Validation is selected according to the files and behavior changed.

A shell implementation change includes an applicable POSIX shell syntax
check.

A plugin protocol change is checked in the operational mode that it changes:

- `autoconf`
- `config`
- data fetch

When behavior depends on Munin's execution environment or `plugin-conf.d`,
validate through `munin-run` in addition to any direct execution needed by
the change.

A privilege-sensitive change is validated with the execution identity and
Munin configuration that the change affects.

A platform-specific change is validated in the supported and representative
environment affected by that change.

A successful check in one environment is not evidence for unaffected
environments, and it is not sufficient for a change whose compatibility risk
extends to other supported environments.

A documentation-only change does not require unrelated runtime execution
merely to satisfy a checklist.

## 12. Repository Versions and Change History

The repository version uses `<year>.<month>` and is recorded in
`doc/VERSIONS`.

Plugin and installer component versions remain independent of the repository
release version.

A version history records release-level changes rather than every commit,
review correction, formatting change, or implementation detail.

Related changes within the same unreleased repository version are combined
and described at the level necessary to understand their externally relevant
effect.

A documentation-only change does not require a plugin or installer version
increment.

## 13. License

This repository is dual licensed under the GPL version 3 or the LGPL version
3, at the user's option.

See:

- `doc/LICENSE`
- `doc/COPYING`
- `doc/COPYING.LESSER`
