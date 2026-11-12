# munin-plugins Implementation and Maintenance Policy

This document defines the implementation and maintenance policy of this
repository.

munin-plugins is a collection of independently installable Munin plugins.
The repository contains plugin programs under `plugins/` and one installer
for each plugin under `installer/`.

This document stands on its own. It is the whole implementation policy of this
repository, and no rule here is completed by a document kept somewhere else. A
subject it does not cover is a gap in this document, to be filled here rather
than looked up elsewhere.

## 0. Governing Principle

**Simplicity is robustness.**

This is the governing principle for every rule below. It does not authorize
dropping required behavior, compatibility, security, safety, documentation, or
validation. It requires satisfying those requirements with no more complexity
than the actual problem justifies.

Complexity is itself a source of failure, compatibility risk, operational risk,
security risk, and maintenance cost. Do not add a branch, state variable,
helper, abstraction, dependency, network boundary, retry, fallback, validation,
configuration state, or framework unless the specification requires it or it
addresses a realistic failure mode with meaningful consequence.

Do not re-check a condition already guaranteed by a preceding successful
operation or an established invariant. Do not create a layer merely to resemble
a possible future architecture.

When two designs satisfy the same requirements, choose the one with less
control flow, less state, fewer dependencies, fewer side effects, fewer moving
parts, and fewer operational assumptions. Simplicity is judged by the number of
necessary concepts and behaviors, not by line count alone.

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
its own. Do not refactor established infrastructure merely because another
design appears cleaner, more modern, or more defensive.

An implementation change is made only when that change has been explicitly
chosen as part of the work being performed. Before deployment, validate it in
the supported and representative environments affected by the change. A
successful check in one convenient environment is not sufficient evidence for
a change whose compatibility risk extends to other supported environments.

### 1.3 Wording Strength

Use `must`, `always`, and `never` only for invariants that admit no reasonable
exception. Express preferences and situational decisions with `prefer`,
`should`, or other qualified wording.

Do not apply a rule literally where doing so would defeat the repository's
stated purpose, intended behavior, compatibility, safety, or approved change
scope.

Where the applicable specifications and policy leave a legitimate choice
open, an explicit maintainer decision governs that choice. General
conventions do not override it.

This is not a formal MUST/SHOULD/MAY taxonomy.

### 1.4 Failure, Continuation, and Reporting

The result of an operation, whether later work continues, and whether anything
is reported are separate decisions.

A missing required capability, invalid configuration, or another condition
that makes correct plugin or installer behavior impossible must use the
established failure or unknown-value behavior. Do not invent a plausible value
or downgrade the condition to a warning merely to keep processing.

An optional or independent target may be skipped only when the plugin or
installer contract permits the remaining work to stay coherent. A normal
no-op, an intentionally inapplicable target, or a supported absence is not a
warning merely because no work was performed and may be silent.

Emit diagnostics only when the operator needs them. Use warning-level reporting
for degraded but recoverable conditions and error-level reporting for failures
that prevent the affected logical operation from completing correctly. Never
add human-readable diagnostics to Munin protocol stdout; Sections 4.2 and 4.3
remain authoritative for machine-readable output.

### 1.5 Pull Request Scope and History

A pull request carries one coherent higher-level purpose, which may require
coordinated changes across several files or responsibilities.

Do not split one approved purpose mechanically by individual finding, file,
or review comment, and do not include unrelated cleanup, formatting, or
feature work.

Represent one coherent change as one commit and amend review corrections
instead of accumulating follow-up commits.

Rewriting the history of a branch under review requires an explicit
instruction from the maintainer. When such a rewrite is authorized, use
`--force-with-lease` and limit the operation to the branch under review.

Check the final branch against its base to remove abandoned intermediate
wording and work. Merge only with explicit maintainer approval.

Unless explicitly instructed otherwise by the maintainer, an automated agent
must commit authorized changes to a work branch and submit them through a
pull request targeting the approved base branch.

An automated agent must not commit or push directly to `master` without
explicit instructions from the maintainer authorizing that operation.

Creating or updating a pull request does not authorize the agent to merge it
or enable auto-merge. Either action requires an explicit instruction from
the maintainer.

Authorization for one operation does not imply authorization for another.
These rules do not change a human maintainer's authority.

## 2. Documentation Roles and Sources of Truth

A concrete specification has exactly one authoritative home appropriate to the
responsibility that owns it. Other documents may link to or summarize that
specification for navigation, but they do not create a competing normative
copy.

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
not, by itself, proof that the current behavior is the intended specification.

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

Each version history entry's description is at most two lines, and a single
line at or under 80 columns is preferred whenever practical.

The first entry, at the lowest version the plugin's own history reaches,
reads only `Initial release.` and nothing else.

A comment preserves a reason, constraint, non-obvious intent, or decision that
a later change could otherwise undo. Do not use comments merely to restate code
whose operation is already evident.

When a comment or header describes observable behavior, keep it consistent
with the implementation when that implementation is deliberately changed.

Write English explanatory prose in clear, natural sentences. Do not replace a
sentence with a label and a colon, a status prefix such as `Implement:` or
`Incompatible:`, a symbol, or an unexplained abbreviation.

Apply this to English prose in comments, docstrings, documentation, version
histories, release notes, commit messages, and pull request descriptions.

This rule does not alter the established forms of headings, list labels,
tables, code, configuration syntax, machine-readable fields, literal
interface strings, or non-English content required by the repository's
purpose.

Wrap ordinary prose at approximately 80 columns where practical. Preserve
the logical structure of paragraphs, lists, and other document elements.
Do not break URLs, code, tables, identifiers, or other elements whose
structure requires a longer line.

Shared boilerplate must retain its common wording, line breaks, blank lines,
and formatting. Do not reformat it independently in individual repositories.
Its established common form takes precedence over the ordinary line-wrapping
guideline.

Do not rewrite historical entries or unrelated text merely to align their
style.

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
- A helper owns the external-command prerequisites it directly uses. The
  standard header-extracting `usage()` calls `check_commands awk` immediately
  before invoking `awk`.
- A `check_system()` function that invokes `uname` calls
  `check_commands uname` before its first use of `uname`; callers do not carry
  `uname` solely on behalf of that `check_system()` call.
- A `check_sudo()` function that invokes `sudo -v` calls
  `check_commands sudo` immediately before its first use of `sudo`; callers do
  not carry `sudo` solely on behalf of that `check_sudo()` call.
- Moving usage-only `awk` ownership into `usage()`, `uname` ownership into
  `check_system()`, or `sudo` ownership into `check_sudo()`, including removal
  of the corresponding redundant caller check, is prerequisite ownership
  normalization. By maintainer decision, that normalization alone does not
  increment an installer version or add a `Version History` entry.

Each entry in that version history is at most two lines, and a single line
at or under 80 columns is preferred whenever practical.

The first entry, at the lowest version the installer's own history reaches,
reads only `Initial release.` and nothing else.

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

Before accepting a change, ask whether it is the smallest coherent change that
serves its purpose, whether it alters behavior outside that purpose, whether it
adds an unnecessary dependency or side effect, whether it exposes private
information, and whether directly affected documentation remains correct.

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

These rules apply to individual source files that carry their own version
history. Repository release versions are governed separately.

- Source file versions use a two-level `major.minor` scheme.
- When incrementing `minor` would reach `10`, roll over instead: increment
  `major` by 1 and reset `minor` to `0` (for example `v0.9` -> `v1.0`,
  `v1.9` -> `v2.0`, `v2.9` -> `v3.0`).
- Do not continue `minor` past `9` as in standard semantic versioning
  (do not use `v1.10`, `v1.11`, ...).
- Raising `major` for a reason other than the rollover is a decision the
  maintainer makes, not one this document derives from the change.
- Removing or renaming an option, changing what an existing argument means,
  changing a default so that an unchanged invocation does something else, and
  changing how a path or a configuration value is resolved are all incompatible
  changes. Say so in the `Version History` entry, so that the number the change
  is released under can be chosen knowing that.

A version history records release-level changes rather than every commit,
review correction, formatting change, or implementation detail.

Related changes within the same unreleased repository version are combined
and described at the level necessary to understand their externally relevant
effect.

Follow the Version History Guidelines at the end of `doc/VERSIONS`.
The established form of an existing history takes precedence over the ordinary
two-line, 80-column limit.

The initial release entry reads only `Initial release.` and nothing else.
Historical First Commit records are not release entries.

A documentation-only change does not require a plugin or installer version
increment.

## 13. License

Follow the applicable terms in `doc/LICENSE`, `doc/COPYING`, and
`doc/COPYING.LESSER`.

Content adapted from an external article, answer, documentation example, source
file, dataset, or other third-party material credits its source and respects
the license or redistribution terms that apply to it.
