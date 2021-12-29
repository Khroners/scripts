# linux-autodownloader
Based on https://gitlab.com/Luigi311/linux_downloader/
Automatically download the latest version of some of the most common linux 
distributions. It will automatically download either the iso or the torrent file
for some distributions.
I'm using this with watch-dir on transmission.

NB : I'm a Shell script's beginner. Feel free to contribute to improve the script/add more linux distro !

# Usage
```bash
$ ./linux-autodownloader.sh [options]
```

# Options
```bash
General Options:
    -h, --help            Display this help message
    -o, --output          Change the download directory, Default is current directory
    --archlinux           Download Archlinux,           will not download others unless selected
    --debian              Download Debian,              will not download others unless selected
    --fedora              Download Fedora,              will not download others unless selected
    --kali                Download Kali,                will not download others unless selected
    --opensuse            Download opensuse,            will not download others unless selected
    --proxmox             Download Proxmox,             will not download others unless selected
    --rocky               Download Rocky,               will not download others unless selected
    --tumbleweed          Download opensuse tumbleweed, will not download others unless selected
    --ubuntu              Download Ubuntu,              will not download others unless selected
    --cleanup             Cleanup and remove lingering files

Example:
    ./linux-autodownloader.sh -o ~/Downloads/ --archlinux --ubuntu --fedora
```

# Supported File Types
- Iso (Checksum checker of some need to be done, like Rocky/Proxmox)
- Torrent

# Supported Distros
- Archlinux
- Debian
- Fedora
- Kali
- OpenSUSE
- Proxmox
- RockyLinux
- Ubuntu

TO DO : 
- Check checksum of Rocky/Proxmox/Kali
- Add more distros
- Only download .torrent if possible (Proxmox for example)
