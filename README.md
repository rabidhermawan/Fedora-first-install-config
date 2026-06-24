# Fedora-first-install-config
Personal script for Fedora first setup

## BEFORE RUNNING
Run this command below to enable ZSTD compression
```bash
sudo dnf update -y
sudo sed -i.bkp '/ btrfs / s/subvol=[^ ,]*/&,compress=zstd:1/' /etc/fstab
reboot
```

## Usage (FOR 1-INSTALL.SH)
```bash
  Usage: fedora_things_to_do [-(a|..|t)]
  -a, All apps installed
  -b, All apps installed (incl. games & emulation)
  -h, Help
  -c, Coding and DevOps
  -f, Fix
  -g, Gaming & Emulation
  -i, Internet, Communication, and File Download
  -m, Media & Graphics
  -n, Networking & Remote
  -o, Office
  -s, System Configuration
  -t, System Toolkit
```

## Credits
- [SysGuides Snapper Setup for Fedora](https://github.com/SysGuides/sysguides-snapper-fedora), for providing initial Snapper configuration
- [NATTDF](https://nattdf.streamlit.app/), for providing the base of the script
