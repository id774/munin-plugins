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
#  Version History:
#  v1.0 2025-03-26
#       Initial release.
#
#  Usage:
#      ./install_process_monitoring.sh
#
#  Notes:
#  - This script copies 'process_monitoring' to /usr/local/share/munin/plugins
#    and creates a symlink in /etc/munin/plugins.
#  - You must manually configure /etc/sudoers for iptables access if needed.
#
########################################################################

# Display script usage information
usage() {
    awk '
        BEGIN { in_usage = 0 }
        /^#  Usage:/ { in_usage = 1; print substr($0, 4); next }
        /^#{10}/ { if (in_usage) exit }
        in_usage && /^#/ { print substr($0, 4) }
    ' "$0"
    exit 0
}

# Function to check if the system is Linux
check_system() {
    if [ "$(uname -s)" != "Linux" ]; then
        echo "Error: This script is intended for Linux systems only." >&2
        exit 1
    fi
}

# Function to check required commands
check_commands() {
    for cmd in "$@"; do
        cmd_path=$(command -v "$cmd" 2>/dev/null)
        if [ -z "$cmd_path" ]; then
            echo "Error: Command '$cmd' is not installed. Please install $cmd and try again." >&2
            exit 127
        elif [ ! -x "$cmd_path" ]; then
            echo "Error: Command '$cmd' is not executable. Please check the permissions." >&2
            exit 126
        fi
    done
}

# Check if the user has sudo privileges (password may be required)
check_sudo() {
    if ! sudo -v 2>/dev/null; then
        echo "Error: This script requires sudo privileges. Please run as a user with sudo access." >&2
        exit 1
    fi
}

# Create plugin and symlink directories if they do not exist
create_directory() {
    if [ ! -d "$PLUGIN_DIR" ]; then
        echo "Creating plugin directory: $PLUGIN_DIR"
        sudo mkdir -p "$PLUGIN_DIR"
    fi

    if [ ! -d "$LINK_DIR" ]; then
        echo "Creating symlink directory: $LINK_DIR"
        sudo mkdir -p "$LINK_DIR"
    fi
}

# Copy the plugin to the target plugin directory and make it executable
install_plugin() {
    echo "Installing $PLUGIN_NAME to $PLUGIN_DST"
    sudo cp "$PLUGIN_SRC" "$PLUGIN_DST"
    sudo chmod +x "$PLUGIN_DST"
}

# Create a symbolic link in /etc/munin/plugins pointing to the installed plugin
create_symlink() {
    if [ ! -L "$PLUGIN_LINK" ]; then
        echo "Creating symlink: $PLUGIN_LINK"
        sudo ln -s "$PLUGIN_DST" "$PLUGIN_LINK"
    else
        echo "Symlink already exists: $PLUGIN_LINK"
    fi
}

# Print post-installation instructions and next steps
final_message() {
    echo ""
    echo " Installation complete."
    echo ""
    echo " Edit the plugin if you wish to monitor additional processes (e.g., postgres, apache2):"
    echo "   $PLUGIN_DST"
    echo ""
    echo " If you use iptables monitoring, ensure the following line exists in /etc/sudoers:"
    echo "  munin ALL=(ALL) NOPASSWD: /sbin/iptables"
    echo "   You can edit safely using: sudo visudo"
    echo ""
    echo " After editing, reload munin-node:"
    echo "   sudo systemctl restart munin-node"
}

# Main function to execute the script
main() {
    case "$1" in
        -h|--help) usage ;;
    esac

    check_system
    check_commands sudo cp mkdir chmod chown ln rm id dirname uname
    check_sudo

    PLUGIN_NAME="process_monitoring"
    PLUGIN_SRC="$HOME/munin-plugins/$PLUGIN_NAME"
    PLUGIN_DST="/usr/local/share/munin/plugins/$PLUGIN_NAME"
    PLUGIN_LINK="/etc/munin/plugins/$PLUGIN_NAME"
    PLUGIN_DIR=$(dirname "$PLUGIN_DST")
    LINK_DIR=$(dirname "$PLUGIN_LINK")

    # Check and create plugin install directory
    create_directory

    install_plugin
    create_symlink
    final_message
}

# Execute main function
main "$@"
