#!/bin/sh

########################################################################
# install_process_monitoring.sh: Installer for Munin Plugin
#
#  Description:
#  This script installs the Munin plugin 'process_monitoring' into the
#  appropriate plugin directory, creates a symbolic link in Munin's
#  plugin list, and provides instructions for further configuration.
#
#  Author: id774 (More info: http://id774.net)
#  Source Code: https://github.com/id774/munin-plugins
#  License: The GPL version 3, or LGPL version 3 (Dual License).
#  Contact: idnanashi@gmail.com
#
#  Usage:
#      ./install_process_monitoring.sh
#      ./install_process_monitoring.sh --uninstall
#
#  Notes:
#  - This script copies 'process_monitoring' to /usr/local/share/munin/plugins
#    and creates a symlink in /etc/munin/plugins.
#  - You must manually configure /etc/sudoers for iptables access if needed.
#  - Use --uninstall to remove the plugin and its symlink.
#
#  Version History:
#  v1.3 2025-07-31
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
    awk '
        BEGIN { in_header = 0 }
        /^#{10,}$/ { if (!in_header) { in_header = 1; next } else exit }
        in_header && /^# ?/ { print substr($0, 3) }
    ' "$0"
    exit 0
}

# Check if the system is Linux
check_system() {
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
    else
        echo "[INFO] Plugin directory already exists: $PLUGIN_DIR"
    fi

    if [ ! -d "$LINK_DIR" ]; then
        echo "[INFO] Creating symlink directory: $LINK_DIR"
        sudo mkdir -p "$LINK_DIR" || {
            echo "[ERROR] Failed to create $LINK_DIR." >&2
            exit 1
        }
    else
        echo "[INFO] Symlink directory already exists: $LINK_DIR"
    fi
}

# Copy the plugin to the target plugin directory and make it executable
install_plugin() {
    if [ -f "$PLUGIN_DST" ]; then
        echo "[INFO] Plugin already installed at: $PLUGIN_DST"
    else
        echo "[INFO] Installing $PLUGIN_NAME to $PLUGIN_DST."
        sudo cp "$PLUGIN_SRC" "$PLUGIN_DST" || {
            echo "[ERROR] Failed to copy plugin to $PLUGIN_DST." >&2
            exit 1
        }
        sudo chmod +x "$PLUGIN_DST" || {
            echo "[ERROR] Failed to set executable permission on $PLUGIN_DST." >&2
            exit 1
        }
    fi
}

# Create a symbolic link in /etc/munin/plugins pointing to the installed plugin
create_symlink() {
    if [ -L "$PLUGIN_LINK" ]; then
        echo "[INFO] Symlink already exists: $PLUGIN_LINK"
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
    check_commands sudo cp mkdir chmod ln rm id dirname
    check_sudo
    create_directory
    install_plugin
    create_symlink
    final_message
}

# Uninstall munin plugins
uninstall() {
    check_system
    check_commands sudo rm
    check_sudo

    echo "[INFO] Uninstalling $PLUGIN_NAME..."
    if [ -L "$PLUGIN_LINK" ]; then
        sudo rm "$PLUGIN_LINK" && echo "[INFO] Removed symlink: $PLUGIN_LINK"
    else
        echo "[INFO] Symlink not found: $PLUGIN_LINK"
    fi

    if [ -f "$PLUGIN_DST" ]; then
        sudo rm "$PLUGIN_DST" && echo "[INFO] Removed plugin: $PLUGIN_DST"
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
    echo " Edit the plugin if you wish to monitor additional processes (e.g., postgres, apache2):"
    echo "   $PLUGIN_DST"
    echo ""
    echo " If you use iptables monitoring, ensure the following line exists in /etc/sudoers:"
    echo "   munin ALL=(ALL) NOPASSWD: /sbin/iptables"
    echo " You can edit safely using: sudo visudo"
    echo ""
    echo " After editing, reload munin-node:"
    echo "   sudo systemctl restart munin-node"
}

# Main entry point of the script
main() {
    PLUGIN_NAME="process_monitoring"
    PLUGIN_SRC="$HOME/munin-plugins/$PLUGIN_NAME"
    PLUGIN_DST="/usr/local/share/munin/plugins/$PLUGIN_NAME"
    PLUGIN_LINK="/etc/munin/plugins/$PLUGIN_NAME"
    PLUGIN_DIR=$(dirname "$PLUGIN_DST")
    LINK_DIR=$(dirname "$PLUGIN_LINK")

    case "$1" in
        -h|--help|-v|--version)
            usage
            ;;
        -u|--uninstall)
            uninstall
            ;;
        ""|*)
            install
            ;;
    esac

    return 0
}

# Execute main function
main "$@"
exit $?
