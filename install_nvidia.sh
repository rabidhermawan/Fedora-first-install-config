#!/bin/bash
# NVIDIA Driver Installation Script for Fedora Workstation

# Check if the script is run with sudo
if [ "$EUID" -ne 0 ]; then
    echo "Please run this script with sudo"
    exit 1
fi

# Funtion to echo colored text
color_echo() {
    local color="$1"
    local text="$2"
    case "$color" in
        "red")     echo -e "\033[0;31m$text\033[0m" ;;
        "green")   echo -e "\033[0;32m$text\033[0m" ;;
        "yellow")  echo -e "\033[1;33m$text\033[0m" ;;
        "blue")    echo -e "\033[0;34m$text\033[0m" ;;
        *)         echo "$text" ;;
    esac
}

# Set variables
ACTUAL_USER=$SUDO_USER
ACTUAL_HOME=$(eval echo ~$SUDO_USER)
LOG_FILE="/var/log/nvidia_driver_installation.log"

# Function to generate timestamps
get_timestamp() {
    date +"%Y-%m-%d %H:%M:%S"
}

# Function to handle errors
handle_error() {
    local exit_code=$?
    local message="$1"
    if [ $exit_code -ne 0 ]; then
        color_echo \"red\" "ERROR: $message"
        exit $exit_code
    fi
}

color_echo "blue" "Installing NVIDIA Driver (RPMFusion)"

# Add RPM Fusion repositories
color_echo "yellow" "Adding RPM Fusion repositories..."
dnf install -y https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm
dnf install -y https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm
handle_error "Failed to add RPM Fusion repositories"
# Update the system
color_echo "yellow" "Updating the system..."
dnf update -y
handle_error "Failed to update the system"
# Install NVIDIA drivers
color_echo "yellow" "Installing NVIDIA drivers..."
dnf install -y akmod-nvidia
handle_error "Failed to install NVIDIA drivers"

# Install CUDA (optional)
read -p "Do you want to install CUDA? (y/n): " install_cuda
if [[ $install_cuda =~ ^[Yy]$ ]]; then
color_echo "yellow" "Installing CUDA..."
dnf install -y xorg-x11-drv-nvidia-cuda
handle_error "Failed to install CUDA"
fi

color_echo "green" "NVIDIA driver installation completed."
echo "Installation complete. Please run:"
color_echo "yellow" "modinfo -F version nvidia"
echo "To check if kmod is built, if not then wait 5 minutes then run the command above again"

