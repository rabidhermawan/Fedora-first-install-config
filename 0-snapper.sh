# Check if system runs on BTRFS
if ! findmnt -n -o FSTYPE / | grep -q btrfs; then
    echo "Error: Root filesystem is not Btrfs"
    exit 1
fi

# Check if system runs with sudo
if [ "$EUID" -ne 0 ]; then
    echo "Please run this script with sudo"
    exit 1
fi

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

# Step 0: Recompress subvolumes to use ZSTD
color_echo "yellow" "Recompress subvolumes to use ZSTD..."
btrfs filesystem defragment -r -v -czstd /
btrfs filesystem defragment -r -v -czstd /home
color_echo "green" "Subvolumes compressed with ZSTD..."

# Step 1: Installing required packages
color_echo "yellow" "Installed required packages..."
dnf install -y snapper libdnf5-plugin-actions btrfs-assistant inotify-tools make git
color_echo "green" "Requiered packages installed..."

# Step 2: Configuring snapper
color_echo "yellow" "Configuring Snapper..."
# Create configs if not present
[ -d /.snapshots ] || snapper -c root create-config /
[ -d /home/.snapshots ] || snapper -c home create-config /home

# Set permissions for current user
REAL_USER=${SUDO_USER:-$USER}
snapper -c root set-config ALLOW_USERS=$REAL_USER SYNC_ACL=yes
snapper -c home set-config ALLOW_USERS=$REAL_USER SYNC_ACL=yes

# Disable timeline snapshots for home
snapper -c home set-config TIMELINE_CREATE=no

# Ensure .snapshots is excluded from updatedb
if grep -q '^PRUNENAMES' /etc/updatedb.conf; then
    grep -q '\.snapshots' /etc/updatedb.conf || \
    sed -i 's|^PRUNENAMES *= *"|PRUNENAMES = ".snapshots |' /etc/updatedb.conf
else
    echo 'PRUNENAMES = ".snapshots"' | tee -a /etc/updatedb.conf
fi
color_echo "green" "Snapper configured..."

# Step 3: Configuring grub-btrfs
color_echo "yellow" "Installing and configuring grub-btrfs..."
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cd "$tmpdir"

git clone --depth 1 https://github.com/Antynea/grub-btrfs
cd grub-btrfs

# Configure grub-btrfs for Fedora
sed -i \
-e 's|^#GRUB_BTRFS_SNAPSHOT_KERNEL_PARAMETERS=.*|GRUB_BTRFS_SNAPSHOT_KERNEL_PARAMETERS="rd.live.overlay.overlayfs=1"|' \
-e 's|^#GRUB_BTRFS_GRUB_DIRNAME=.*|GRUB_BTRFS_GRUB_DIRNAME="/boot/grub2"|' \
-e 's|^#GRUB_BTRFS_MKCONFIG=.*|GRUB_BTRFS_MKCONFIG=/usr/bin/grub2-mkconfig|' \
-e 's|^#GRUB_BTRFS_SCRIPT_CHECK=.*|GRUB_BTRFS_SCRIPT_CHECK=grub2-script-check|' \
config

sudo make install
sudo systemctl enable --now grub-btrfsd.service

# Generate GRUB config (important for first run)
echo "==> Updating GRUB configuration..."
sudo grub2-mkconfig -o /boot/grub2/grub.cfg
color_echo "green" "Grub-btrfs installed and configured..."

# Step 5: Enable Snapper timers
color_echo "yellow" "Enabling Snapper timers..."
sudo systemctl enable --now snapper-timeline.timer
sudo systemctl enable --now snapper-cleanup.timer
color_echo "green" "Snapper timers enabled..."