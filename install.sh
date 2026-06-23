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

C_CODING=false
F_SYS_FIX=false
G_GAME_EMU=false
I_INTERNET=false
M_MEDIA=false
N_NETWORK=false
O_OFFICE=false
S_SYS_CFG=false
T_SYS_KIT=false

# For help usage
usage() {
  echo 'Usage: fedora_things_to_do [-(a|..|t)]]'
  echo "-a, All apps installed"
  echo "-b, All apps installed (incl. games & emulation)"
  echo "-h, Help"
  echo "-c, Coding and DevOps"
  echo "-f, Fix"
  echo "-g, Gaming & Emulation"
  echo "-i, Internet, Communication, and File Download"
  echo "-m, Media & Graphics"
  echo "-n, Networking & Remote"
  echo "-o, Office"
  echo "-s, System Configuration"
  echo "-t, System Toolkit"
}


# Load in arguments
while getopts 'abhcfgimnost' opt; do
  case "$opt" in
    a)
        C_CODING=true
        F_SYS_FIX=true
        I_INTERNET=true
        M_MEDIA=true
        N_NETWORK=true
        O_OFFICE=true
        S_SYS_CFG=true
        T_SYS_KIT=true
    ;;

    b)
        C_CODING=true
        F_SYS_FIX=true
        G_GAME_EMU=true
        I_INTERNET=true
        M_MEDIA=true
        N_NETWORK=true
        O_OFFICE=true
        S_SYS_CFG=true
        T_SYS_KIT=true

    ;;
    h)
      usage
      exit 0
    ;;
    c)
    C_CODING=true

    ;;
    f)
    F_SYS_FIX=true

    ;;
    g)
    G_GAME_EMU=true

    ;;
    i)
    I_INTERNET=true

    ;;
    m)
    M_MEDIA=true

    ;;
    n)
    N_NETWORK=true

    ;;
    o)
    O_OFFICE=true

    ;;
    s)
    S_SYS_CFG=true

    ;;
    t)
    T_SYS_KIT=true
    ;;

    *) usage >&2; exit 1;;
  esac
done

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

# ---------------------- System Upgrade ----------------------
color_echo "blue" "Performing system upgrade... This may take a while..."
dnf upgrade -y


# ---------------------- System Configuration (-s) ----------------------
# Set the system hostname
if $S_SYS_CFG; then
    color_echo "yellow" "Setting hostname..."
    hostnamectl set-hostname rabidh-fedora

    color_echo "yellow" "Configuring DNF Package Manager..."
    backup_file "/etc/dnf/dnf.conf"
    dnf -y install dnf-plugins-core
    # Max Parallel Downloads
    echo "max_parallel_downloads=10" | tee -a /etc/dnf/dnf.conf > /dev/null
    # Select Fastest Mirror
    echo "fastestmirror=True" | tee -a /etc/dnf/dnf.conf > /dev/null
    # Default Yes
    echo "defaultyes=True" | tee -a /etc/dnf/dnf.conf > /dev/null

    # Enable RPM Fusion repositories
    color_echo "yellow" "Enabling RPM Fusion repositories..."
    dnf install -y https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm
    dnf install -y https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm
    dnf group update core -y

    # Replace Fedora Flatpak Repo with Flathub
    color_echo "yellow" "Replacing Fedora Flatpak Repo with Flathub..."
    dnf install -y flatpak
    flatpak remote-delete fedora --force || true
    flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
    flatpak repair
    flatpak update -y

    # Check and apply firmware updates
    color_echo "yellow" "Checking for firmware updates..."
    fwupdmgr refresh --force
    fwupdmgr get-updates
    fwupdmgr update -y

    # Install Google and Microsoft Fonts
    color_echo "yellow" "Installing Google Fonts..."
    wget -O /tmp/google-fonts.zip https://github.com/google/fonts/archive/main.zip
    mkdir -p $ACTUAL_HOME/.local/share/fonts/google
    unzip /tmp/google-fonts.zip -d $ACTUAL_HOME/.local/share/fonts/google
    rm -f /tmp/google-fonts.zip
    fc-cache -fv
    color_echo "green" "Google Fonts installed successfully."

    color_echo "yellow" "Installing Microsoft Fonts (windows)..."
    dnf install -y wget cabextract xorg-x11-font-utils fontconfig
    wget -O /tmp/winfonts.zip https://mktr.sbs/fonts
    mkdir -p $ACTUAL_HOME/.local/share/fonts/windows
    unzip /tmp/winfonts.zip -d $ACTUAL_HOME/.local/share/fonts/windows
    rm -f /tmp/winfonts.zip
    fc-cache -fv
    color_echo "green" "Microsoft Fonts (windows) installed successfully."

    color_echo "yellow" "Installing Adobe Fonts..."
    mkdir -p $ACTUAL_HOME/.local/share/fonts/adobe-fonts
    git clone --depth 1 https://github.com/adobe-fonts/source-sans.git $ACTUAL_HOME/.local/share/fonts/adobe-fonts/source-sans
    git clone --depth 1 https://github.com/adobe-fonts/source-serif.git $ACTUAL_HOME/.local/share/fonts/adobe-fonts/source-serif
    git clone --depth 1 https://github.com/adobe-fonts/source-code-pro.git $ACTUAL_HOME/.local/share/fonts/adobe-fonts/source-code-pro
    fc-cache -fv
    color_echo "green" "Adobe Fonts installed successfully."
    fi

# ---------------------- App Installation ----------------------
# ---------------------- System Toolkit (-t) ----------------------
if $T_SYS_KIT; then
    color_echo "yellow" "Installing essential applications..."
    dnf install -y btop fastfetch unzip unrar it wget curl
    color_echo "green" "Essential applications installed successfully."

    color_echo "yellow" "Installing Flatseal..."
    flatpak install -y flathub com.github.tchx84.Flatseal
    color_echo "green" "Flatseal installed successfully."

    color_echo "yellow" "Installing Bottles..."
    flatpak install -y flathub com.usebottles.bottles
    color_echo "green" "Bottles installed successfully."

    color_echo "yellow" "Installing GParted..."
    dnf install -y gparted
    color_echo "green" "GParted installed successfully."
fi

# ---------------------- Office (-o) ----------------------
if $O_OFFICE; then
    color_echo "yellow" "Installing PDFArranger..."
    flatpak install -y flathub com.github.jeromerobert.pdfarranger
    color_echo "green" "PDFArranger installed successfully."

    color_echo "yellow" "Installing Obsidian..."
    flatpak install -y flathub md.obsidian.Obsidian
    color_echo "green" "Obsidian installed successfully."

    color_echo "yellow" "Installing Bitwarden..."
    flatpak install -y flathub com.bitwarden.desktop
    color_echo "green" "Bitwarden installed successfully."
fi

# ---------------------- Internet, Communication, and File Download (-i) ----------------------
if $I_INTERNET; then
    color_echo "yellow" "Installing Vesktop..."
    flatpak install -y flathub dev.vencord.Vesktop
    color_echo "green" "Vesktop installed successfully."

    color_echo "yellow" "Installing Helium Browser..."
    dnf copr -y enable imput/helium
    dnf install -y helium-bin
    color_echo "green" "Helium Browser installed successfully."

    color_echo "yellow" "Installing Telegram Desktop..."
    dnf install -y telegram-desktop
    color_echo "green" "Telegram Desktop installed successfully."

    color_echo "yellow" "Installing qBittorrent..."
    dnf install -y qbittorrent
    color_echo "green" "qBittorrent installed successfully."
fi

# ---------------------- Coding and DevOps (-c) ----------------------
if $C_CODING; then
    color_echo "yellow" "Creating code directory..."
    mkdir -p $ACTUAL_HOME/code
    color_echo "green" "Code directory successfully created..."

    color_echo "yellow" "Installing Visual Studio Code..."

    rpm --import https://packages.microsoft.com/keys/microsoft.asc &&
    echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\nautorefresh=1\ntype=rpm-md\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" | sudo tee /etc/yum.repos.d/vscode.repo > /dev/null

    dnf check-update
    dnf install -y code

    color_echo "green" "Visual Studio Code installed successfully."
    color_echo "yellow" "Installing GitHub Desktop..."

    rpm --import https://mirror.mwt.me/shiftkey-desktop/gpgkey
    sh -c 'echo -e "[mwt-packages]\nname=GitHub Desktop\nbaseurl=https://mirror.mwt.me/shiftkey-desktop/rpm\nenabled=1\ngpgcheck=1\nrepo_gpgcheck=1\ngpgkey=https://mirror.mwt.me/shiftkey-desktop/gpgkey" > /etc/yum.repos.d/mwt-packages.repo'
    dnf install -y github-desktop
    color_echo "green" "GitHub Desktop installed successfully."

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

    dnf config-manager addrepo --from-repofile https://download.docker.com/linux/fedora/docker-ce.repo
    dnf install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    color_echo "green" "Docker installed successfully."

    color_echo "yellow" "Installing Python..."
    dnf install -y python3
    dnf install -y python3-pip
    color_echo "green" "Python installed successfully."

    color_echo "yellow" "Installing Golang..."
    dnf install -y golang
    color_echo "green" "Golang installed successfully."

    color_echo "yellow" "Installing NodeJS..."
    dnf install -y node
    color_echo "green" "NodeJS installed successfully."

    color_echo "yellow" "Installing Ansible..."
    dnf install -y ansible
    color_echo "green" "Ansible installed successfully."

    color_echo "yellow" "Installing virtualization tools..."
    dnf install -y @virtualization
fi

# ---------------------- Networking & Remote (-n) ----------------------
if $N_NETWORK; then
    color_echo "yellow" "Installing Remmina..."
    dnf install -y remmina
    color_echo "green" "Remmina installed successfully."
    color_echo "yellow" "Installing Proton VPN..."
    flatpak install -y flathub com.protonvpn.www
    color_echo "green" "Proton VPN installed successfully."
    color_echo "yellow" "Installing Tailscale..."
    dnf config-manager addrepo --from-repofile=https://pkgs.tailscale.com/stable/fedora/tailscale.repo
    dnf install tailscale -y
    systemctl enable --now tailscaled
    color_echo "green" "Tailscale installed successfully."
fi

# ---------------------- Media & Graphics (-m) ----------------------
if $M_MEDIA; then
    color_echo "yellow" "Installing multimedia codecs..."
    dnf swap ffmpeg-free ffmpeg --allowerasing -y
    dnf update @multimedia --setopt="install_weak_deps=False" --exclude=PackageKit-gstreamer-plugin -y
    dnf update @sound-and-video -y

    color_echo "yellow" "Installing Spotify..."
    flatpak install -y flathub com.spotify.Client
    color_echo "green" "Spotify installed successfully."

    color_echo "yellow" "Installing OBS Studio..."
    dnf install -y obs-studio
    color_echo "green" "OBS Studio installed successfully."

    color_echo "yellow" "Installing MPV..."
    dnf install -y mpv
    color_echo "green" "MPV installed successfully."

    color_echo "yellow" "Installing Kolourpaint..."
    dnf install -y kolourpaint
    color_echo "green" "Kolourpaint installed successfully."
fi

# ---------------------- Gaming & Emulation (-g) ----------------------

if $G_GAME_EMU; then
    color_echo "yellow" "Creating game directory..."
    mkdir -p $ACTUAL_HOME/game
    color_echo "green" "Game directory successfully created..."

    color_echo "yellow" "Installing Steam..."
    dnf install -y steam
    color_echo "green" "Steam installed successfully."

    color_echo "yellow" "Installing Lutris..."
    dnf install -y lutris
    color_echo "green" "Lutris installed successfully."

    color_echo "yellow" "Installing Heroic Games Launcher..."
    flatpak install -y flathub com.heroicgameslauncher.hgl
    color_echo "green" "Heroic Games Launcher installed successfully."

    color_echo "yellow" "Installing Duckstation..."
    mkdir -p $ACTUAL_HOME/game/emulator/duckstation
    wget -P $ACTUAL_HOME/game/emulator/duckstation https://github.com/stenzek/duckstation/releases/download/latest/DuckStation-x64.AppImage
    duckstation=$(cat <<EOF
[Desktop Entry]
Type=Application
Name=DuckStation
GenericName=PlayStation 1 Emulator
Comment=Fast PlayStation 1 emulator
Exec="$ACTUAL_HOME/games/duckstation/DuckStation-x64.AppImage" %f
Terminal=false
Categories=Game;Emulator;Qt
StartupNotify=true
StartupWMClass=duckstation-qt
EOF
    )

    echo
    color_echo "green" "Duckstation installed successfully. You may need to open the application to complete its installation"


    color_echo "yellow" "Installing Dolphin..."
    flatpak install -y flathub org.DolphinEmu.dolphin-emu
    color_echo "green" "Dolphin installed successfully."

    color_echo "yellow" "Installing Cemu..."
    flatpak install -y flathub info.cemu.Cemu
    color_echo "green" "Cemu installed successfully."

    color_echo "yellow" "Installing PCSX2..."
    flatpak install -y flathub net.pcsx2.PCSX2
    color_echo "green" "PCSX2 installed successfully."

    color_echo "yellow" "Installing ProtonUp-Qt..."
    flatpak install -y flathub net.davidotek.pupgui2
    color_echo "green" "ProtonUp-Qt installed successfully."
fi

# ---------------------- System Fix ----------------------
if $F_SYS_FIX; then
    color_echo "yellow" "Removing pipewire config conflicting with mute..."
    dnf rm pipewire-config-raop
    systemctl --user restart wireplumber pipewire pipewire-pulse
    color_echo "green" "Done"

    color_echo "yellow" "Add Breeze GTK theme for KDE..."
    flatpak install org.gtk.Gtk3theme.Breeze org.gtk.Gtk3theme.Breeze-Dark
    # Apply read only access to GTK config generated by KDE
    flatpak override --user --filesystem=xdg-config/gtk-3.0:ro --filesystem=xdg-config/gtk-4.0:ro
    color_echo "green" "Done"
    
fi

# Return to home
cd /tmp || cd $ACTUAL_HOME || cd /

# Finish
color_echo "green" "All steps completed."

# Prompt for reboot
prompt_reboot
