#!/bin/sh

########################################################################
# install_process_monitoring.sh: Installer for Munin Plugin
#
#  Description:
#  This script installs the Munin plugin 'process_monitoring' into the
#  appropriate plugin directory, creates a symbolic link in Munin's
#  plugin list, and provides instructions for further configuration.
#
#  Author: id774 (More info: https://id774.net)
#  Source Code: https://github.com/id774/munin-plugins
#  License: The GPL version 3, or LGPL version 3 (Dual License).
#  Contact: idnanashi@gmail.com
#
#  Usage:
#      ./installer/install_process_monitoring.sh
#      ./installer/install_process_monitoring.sh --uninstall
#
#  Notes:
#  - This script copies 'process_monitoring' to /usr/local/share/munin/plugins
#    and creates a symlink in /etc/munin/plugins.
#  - Existing plugin file at destination will be overwritten.
#  - Grant root to the plugin via 'user root' in /etc/munin/plugin-conf.d/local
#    if you monitor iptables rules. The plugin does not call sudo, and no
#    sudoers entry is required.
#  - Use --uninstall to remove the plugin and its symlink.
#
#  Version History:
#  v3.3 2026-09-12
#       Fail on uninstall removal errors, reject destination symlinks, and
#       set deployed file and newly created directory modes explicitly.
#  v3.2 2026-09-09
#       Reject unknown options and validate pre-existing enabled-plugin symlinks.
#       Align post-install guidance with persistent configuration.
#  v3.1 2026-08-23
#       Improve installer portability and prerequisite command validation.
#  v3.0 2026-07-29
#       Replace the sudoers guidance in the post-install message with the munin-node 'user root' setting, matching
#       the plugin's removal of sudo. Drop the unused id and rm checks from the install path command list.
#  v2.2 2026-07-11
#       Replace the awk {n,} interval expression in usage() with a portable
#       equivalent, since mawk on some systems matches it incorrectly.
#  v2.1 2025-09-22
#       Overwrite existing plugin file on install and explicitly prompt the user
#       to edit the installed plugin in the final message.
#  v2.0 2025-08-01
#       Add --uninstall option to remove installed plugin and symlink.
#  v1.2 2025-06-23
#       Unified usage output to display full script header and support common help/version options.
#  v1.1 2025-04-27
#       Add error handling and skip logic for plugin installation.
#  v1.0 2025-03-26
#       Initial release.
#
########################################################################

# Display full script header information extracted from the top comment block
usage() {
    check_commands awk
    awk '
        BEGIN { in_header = 0 }
        /^#+$/ && length($0) >= 10 { if (!in_header) { in_header = 1; next } else exit }
        in_header && /^# ?/ { print substr($0, 3) }
    ' "$0"
    exit 0
}

# Check if the system is Linux
check_system() {
    check_commands uname
    if [ "$(uname -s)" != "Linux" ]; then
        echo "[ERROR] This script is intended for Linux systems only." >&2
        exit 1
    fi
}

# Check if required commands are available and executable
check_commands() {
    for cmd in "$@"; do
        cmd_path=$(command -v "$cmd" 2>/dev/null)
        if [ -z "$cmd_path" ]; then
            echo "[ERROR] Command '$cmd' is not installed. Please install $cmd and try again." >&2
            exit 127
        elif [ ! -x "$cmd_path" ]; then
            echo "[ERROR] Command '$cmd' is not executable. Please check the permissions." >&2
            exit 126
        fi
    done
}

# Check if the user has sudo privileges (password may be required)
check_sudo() {
    check_commands sudo
    if ! sudo -v 2>/dev/null; then
        echo "[ERROR] This script requires sudo privileges. Please run as a user with sudo access." >&2
        exit 1
    fi
}

# Create plugin and symlink directories if they do not exist
create_directory() {
    if [ ! -d "$PLUGIN_DIR" ]; then
        echo "[INFO] Creating plugin directory: $PLUGIN_DIR"
        sudo mkdir -p "$PLUGIN_DIR" || {
            echo "[ERROR] Failed to create $PLUGIN_DIR." >&2
            exit 1
        }
        sudo chmod 755 "$PLUGIN_DIR" || {
            echo "[ERROR] Failed to set permissions on $PLUGIN_DIR." >&2
            exit 1
        }
    else
        echo "[INFO] Plugin directory already exists: $PLUGIN_DIR"
    fi

    if [ ! -d "$LINK_DIR" ]; then
        echo "[INFO] Creating symlink directory: $LINK_DIR"
        sudo mkdir -p "$LINK_DIR" || {
            echo "[ERROR] Failed to create $LINK_DIR." >&2
            exit 1
        }
        sudo chmod 755 "$LINK_DIR" || {
            echo "[ERROR] Failed to set permissions on $LINK_DIR." >&2
            exit 1
        }
    else
        echo "[INFO] Symlink directory already exists: $LINK_DIR"
    fi
}

# Copy the plugin to the target plugin directory and make it executable
install_plugin() {
    if [ -L "$PLUGIN_DST" ]; then
        echo "[ERROR] Plugin destination is a symbolic link: $PLUGIN_DST" >&2
        exit 1
    fi

    if [ -f "$PLUGIN_DST" ]; then
        echo "[INFO] Existing plugin found. Overwriting: $PLUGIN_DST"
    else
        echo "[INFO] Installing $PLUGIN_NAME to $PLUGIN_DST."
    fi
    sudo cp "$PLUGIN_SRC" "$PLUGIN_DST" || {
        echo "[ERROR] Failed to copy plugin to $PLUGIN_DST." >&2
        exit 1
    }
    sudo chmod 755 "$PLUGIN_DST" || {
        echo "[ERROR] Failed to set permissions on $PLUGIN_DST." >&2
        exit 1
    }
}

# Create a symbolic link in /etc/munin/plugins pointing to the installed plugin
create_symlink() {
    if [ -L "$PLUGIN_LINK" ]; then
        check_commands readlink
        LINK_TARGET=$(readlink -f "$PLUGIN_LINK" 2>/dev/null)
        EXPECTED_TARGET=$(readlink -f "$PLUGIN_DST" 2>/dev/null)
        if [ -n "$LINK_TARGET" ] && [ -n "$EXPECTED_TARGET" ] && [ "$LINK_TARGET" = "$EXPECTED_TARGET" ]; then
            echo "[INFO] Symlink already exists: $PLUGIN_LINK"
        else
            echo "[ERROR] Existing symlink does not point to $PLUGIN_DST: $PLUGIN_LINK" >&2
            exit 1
        fi
    else
        echo "[INFO] Creating symlink: $PLUGIN_LINK"
        sudo ln -s "$PLUGIN_DST" "$PLUGIN_LINK" || {
            echo "[ERROR] Failed to create symlink at $PLUGIN_LINK." >&2
            exit 1
        }
    fi
}

# Install munin plugins
install() {
    check_system
    check_commands cp mkdir chmod ln
    check_sudo
    create_directory
    install_plugin
    create_symlink
    final_message
}

# Uninstall munin plugins
uninstall() {
    check_system
    check_commands rm
    check_sudo

    echo "[INFO] Uninstalling $PLUGIN_NAME..."
    if [ -L "$PLUGIN_LINK" ]; then
        if sudo rm "$PLUGIN_LINK"; then
            echo "[INFO] Removed symlink: $PLUGIN_LINK"
        else
            echo "[ERROR] Failed to remove symlink: $PLUGIN_LINK" >&2
            exit 1
        fi
    else
        echo "[INFO] Symlink not found: $PLUGIN_LINK"
    fi

    if [ -f "$PLUGIN_DST" ]; then
        if sudo rm "$PLUGIN_DST"; then
            echo "[INFO] Removed plugin: $PLUGIN_DST"
        else
            echo "[ERROR] Failed to remove plugin: $PLUGIN_DST" >&2
            exit 1
        fi
    else
        echo "[INFO] Plugin not found: $PLUGIN_DST"
    fi

    echo "[INFO] Uninstallation complete."
}

# Print post-installation instructions and next steps
final_message() {
    echo ""
    echo "[INFO] Installation complete."
    echo ""
    echo " The plugin file has been installed or overwritten:"
    echo "   $PLUGIN_DST"
    echo ""
    echo " Configure supported site-specific settings under /etc/munin/plugin-conf.d/."
    echo " Do not edit the installed plugin for persistent customization; this"
    echo " installer overwrites $PLUGIN_DST on the next installation."
    echo " Changes to process names, thresholds, or labels belong in the maintained"
    echo " source rather than the installed copy."
    echo ""
    echo " If you use iptables monitoring, the plugin must run as root."
    echo " It does NOT call sudo. Grant the privilege through munin-node by adding"
    echo " the following to /etc/munin/plugin-conf.d/local:"
    echo ""
    echo "   [process_monitoring]"
    echo "   user root"
    echo ""
    echo " Do NOT add a sudoers rule such as 'munin ALL=(ALL) NOPASSWD: /sbin/iptables'."
    echo " It would let the munin account flush the firewall with 'iptables -F'."
    echo " If an earlier installation added that line, remove it with: sudo visudo"
    echo ""
    echo " Restart munin-node with the service-management mechanism used by this host."
    echo " On a systemd-based host:"
    echo "   sudo systemctl restart munin-node"
    echo ""
    echo " Then verify the output with:"
    echo "   sudo munin-run process_monitoring"
}

# Main entry point of the script
main() {
    PLUGIN_NAME="process_monitoring"

    case "$1" in
        -h|--help|-v|--version)
            usage
            ;;
        -u|--uninstall)
            ACTION="uninstall"
            ;;
        "")
            ACTION="install"
            ;;
        *)
            echo "[ERROR] Unknown option: $1" >&2
            return 1
            ;;
    esac

    check_commands dirname

    SCRIPT_PATH=$0
    case "$SCRIPT_PATH" in
        */*) ;;
        *)
            if [ ! -f "$SCRIPT_PATH" ]; then
                SCRIPT_PATH=$(command -v "$SCRIPT_PATH" 2>/dev/null)
            fi
            ;;
    esac
    SCRIPT_DIR=$(CDPATH= cd -P "$(dirname "$SCRIPT_PATH")" && pwd)
    REPO_ROOT=$(CDPATH= cd -P "$SCRIPT_DIR/.." && pwd)
    PLUGIN_SRC="$REPO_ROOT/plugins/$PLUGIN_NAME"
    PLUGIN_DST="/usr/local/share/munin/plugins/$PLUGIN_NAME"
    PLUGIN_LINK="/etc/munin/plugins/$PLUGIN_NAME"
    PLUGIN_DIR=$(dirname "$PLUGIN_DST")
    LINK_DIR=$(dirname "$PLUGIN_LINK")

    case "$ACTION" in
        install)
            install
            ;;
        uninstall)
            uninstall
            ;;
    esac

    return $?
}

# Execute main function
main "$@"
