#!/bin/bash
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
LOG_FILE="/var/log/fedora_things_to_do.log"
INITIAL_DIR=$(pwd)

# Function to generate timestamps
get_timestamp() {
    date +"%Y-%m-%d %H:%M:%S"
}

# Function to log messages
log_message() {
    local message="$1"
    echo "$(get_timestamp) - $message" | tee -a "$LOG_FILE"
}

# Function to handle errors
handle_error() {
    local exit_code=$?
    local message="$1"
    if [ $exit_code -ne 0 ]; then
        color_echo "red" "ERROR: $message"
        exit $exit_code
    fi
}

# Function to prompt for reboot
prompt_reboot() {
    sudo -u $ACTUAL_USER bash -c 'read -p "It is time to reboot the machine. Would you like to do it now? (y/n): " choice; [[ $choice == [yY] ]]'
    if [ $? -eq 0 ]; then
        color_echo "green" "Rebooting..."
        reboot
    else
        color_echo "red" "Reboot canceled."
    fi
}

# Function to backup configuration files
backup_file() {
    local file="$1"
    if [ -f "$file" ]; then
        cp "$file" "$file.bak"
        handle_error "Failed to backup $file"
        color_echo "green" "Backed up $file"
    fi
}

echo "Scripts for installing stuff"
echo "ver. 25.03"

# System Upgrade
color_echo "blue" "Performing system upgrade... This may take a while..."
dnf upgrade -y


# System Configuration

# Replace Fedora Flatpak Repo with Flathub for better package management and apps stability
color_echo "yellow" "Replacing Fedora Flatpak Repo with Flathub..."
dnf install -y flatpak
flatpak remote-delete fedora --force || true
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
sudo flatpak repair
flatpak update

# Enable RPM Fusion repositories to access additional software packages and codecs
color_echo "yellow" "Enabling RPM Fusion repositories..."
dnf install -y https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm
dnf install -y https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm
dnf group update core -y

# Install multimedia codecs to enhance multimedia capabilities
color_echo "yellow" "Installing multimedia codecs..."
dnf swap ffmpeg-free ffmpeg --allowerasing -y
dnf update @multimedia --setopt="install_weak_deps=False" --exclude=PackageKit-gstreamer-plugin -y
dnf update @sound-and-video -y


# App Installation
# Install essential applications
color_echo "yellow" "Installing essential applications..."
dnf install -y btop fastfetch unzip git wget curl
color_echo "green" "Essential applications installed successfully."

# Install Internet & Communication applications
color_echo "yellow" "Installing Vesktop..."
flatpak install -y flathub dev.vencord.Vesktop
color_echo "green" "Vesktop installed successfully."

# Install Coding and DevOps applications
color_echo "yellow" "Installing Visual Studio Code..."

rpm --import https://packages.microsoft.com/keys/microsoft.asc &&
echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\nautorefresh=1\ntype=rpm-md\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" | sudo tee /etc/yum.repos.d/vscode.repo > /dev/null

dnf check-update
dnf install -y code

color_echo "green" "Visual Studio Code installed successfully."
color_echo "yellow" "Installing GitHub Desktop..."

# Install Github
flatpak install -y flathub io.github.shiftey.Desktop
color_echo "green" "GitHub Desktop installed successfully."

# Install Docker
# Remove old docker stuff if exists
color_echo "yellow" "Installing Docker"
dnf remove docker \
    docker-client \
    docker-client-latest \
    docker-common \
    docker-latest \
    docker-latest-logrotate \
    docker-logrotate \
    docker-selinux \
    docker-engine-selinux \
    docker-engine -y

# Add Docker repo
dnf config-manager addrepo --from-repofile https://download.docker.com/linux/fedora/docker-ce.repo

# Install all Docker stuff
dnf install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
color_echo "green" "Docker installed successfully."

# Install Media & Graphics applications
color_echo "yellow" "Installing Spotify..."
flatpak install -y flathub com.spotify.Client
color_echo "green" "Spotify installed successfully."

color_echo "yellow" "Installing OBS Studio..."
dnf install -y obs-studio
color_echo "green" "OBS Studio installed successfully."

# Install Gaming & Emulation applications
# color_echo "yellow" "Installing Steam..."
# dnf install -y steam
# color_echo "green" "Steam installed successfully."

# color_echo "yellow" "Installing Lutris..."
# dnf install -y lutris
# color_echo "green" "Lutris installed successfully."

# color_echo "yellow" "Installing Heroic Games Launcher..."
# flatpak install -y flathub com.heroicgameslauncher.hgl
# color_echo "green" "Heroic Games Launcher installed successfully."

# color_echo "yellow" "Installing Dolphin..."
# flatpak install -y flathub org.DolphinEmu.dolphin-emu
# color_echo "green" "Dolphin installed successfully."

# color_echo "yellow" "Installing ProtonUp-Qt..."
# flatpak install -y flathub net.davidotek.pupgui2
# color_echo "green" "ProtonUp-Qt installed successfully."

# Install File Sharing & Download applications
color_echo "yellow" "Installing qBittorrent..."
dnf install -y qbittorrent
color_echo "green" "qBittorrent installed successfully."

# Install System Tools applications
color_echo "yellow" "Installing Flatseal..."
flatpak install -y flathub com.github.tchx84.Flatseal
color_echo "green" "Flatseal installed successfully."


# Customization
# Install Microsoft Windows fonts (core)
color_echo "yellow" "Installing Microsoft Fonts (core)..."
dnf install -y curl cabextract xorg-x11-font-utils fontconfig
rpm -i https://downloads.sourceforge.net/project/mscorefonts2/rpms/msttcore-fonts-installer-2.6-1.noarch.rpm
color_echo "green" "Microsoft Fonts (core) installed successfully."

# Install Google fonts collection
color_echo "yellow" "Installing Google Fonts..."
wget -O /tmp/google-fonts.zip https://github.com/google/fonts/archive/main.zip
mkdir -p $ACTUAL_HOME/.local/share/fonts/google
unzip /tmp/google-fonts.zip -d $ACTUAL_HOME/.local/share/fonts/google
rm -f /tmp/google-fonts.zip
fc-cache -fv
color_echo "green" "Google Fonts installed successfully."


# Custom user-defined commands

# Before finishing, ensure we're in a safe directory
cd /tmp || cd $ACTUAL_HOME || cd /

# Finish
color_echo "green" "All steps completed."

# Prompt for reboot
prompt_reboot
