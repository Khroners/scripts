#!/usr/bin/env bash

# Source: http://mywiki.wooledge.org/BashFAQ/035
die() {
    printf '%s\n' "$1" >&2
    exit 1
}
tester() {
    eval "$testdownload" -q --spider "$testlink"

    if [ "$?" -ne 0 ]; then
        die "ERROR: $testlink is invalid"
    fi
}
cleanup() {
    echo "Cleaning up"
    rm -rf "$output"/index*
    rm -rf "$output"/.listing*
}
downloader() {
    if [ "$aria" == 0 ]; then
        if [ "$extension" = ".iso" ]; then
            eval "$download" "$1" -P "$2"            
        else
            eval "$testdownload" -q --spider "$1"*"$extension"
            if [ "$?" -ne 0 ]; then
                eval "$download" "$1" -P "$2"
            else
                eval "$download" "$1"*"$extension" -P "$2"
            fi
        fi
        
    else
        if [ "$extension" = ".iso" ]; then
            eval "$download" "$1" -d "$2"            
        else
            # Source: zb226 https://superuser.com/questions/545316/getting-all-the-filenames-not-content-recursively-from-an-http-directory
            # Needed to get the actual filenames to download with aria since it does not support wildcard
            wget -d -np -N --spider -e robots=off --reject-regex="\?C=" --no-check-certificate "$1"* 2>&1 | grep " -> " | sed "s/.* -> //" | uniq | cut -f2 -d "'" | grep "$extension$" | awk -v url="$1" '{print url "/" $0}' > "$output"/ariafiles.txt
            if [ -s "$output"/ariafiles.txt ]; then
                echo "Beginning Aria download"
            else
                echo "Empty"
                echo "$1" > "$output"/ariafiles.txt
            fi
            eval "$download" -i "$output"/ariafiles.txt -d "$2"
            rm -rf "$output"/ariafiles.txt
        fi
    fi
}

extension=".torrent"
testdownload="wget -r -np -nd -c -q -m -U mozilla -e robots=off"
download="$testdownload --show-progress"
curler="curl -ls"
output="."
fedora_distributions=("Server" "Workstation")

# Debugging information
test=0
type="Downloading"

# Download list
all=1
archlinux=0
Rocky=0
debian=0
fedora=0
kali=0
ubuntu=0
proxmox=0

# Optional Features
aria=0
concurrent=1

# Links to download from
# Arch has iso and torrents together, this works with ftp only
arch_ftp=ftp://mirror.rackspace.com/archlinux/iso

# Rocky has iso and torrents together,  this works with ftp only
rocky_ftp=https://download.rockylinux.org/pub/rocky/

# Debian has iso and torrents together,  this works with ftp only
debian_ftp=ftp://cdimage.debian.org/debian-cd/current/amd64

# Fedora has iso and torrents seperate, fedora has a redirect to a mirror so curl is used
fedora_torrent=https://torrent.fedoraproject.org/torrents
fedora_iso=https://download.fedoraproject.org/pub/fedora/linux/releases

# Kali has iso and torrents seperate 
kali_iso=https://cdimage.kali.org/kali-images/current
kali_torrent=https://kali.download/base-images/current

# OpenSUSE
opensuse_current=https://download.opensuse.org/distribution/openSUSE-current/iso
opensuse_tumbleweed=https://download.opensuse.org/tumbleweed/iso

# Proxmox-VE
proxmox_url=http://download.proxmox.com/iso

# Ubuntu has iso and torrents together,  this works with ftp only
ubuntu_ftp=ftp://releases.ubuntu.com/releases

# Source: http://mywiki.wooledge.org/BashFAQ/035
while :; do
    case "$1" in
        -h | -\? | --help)
            echo "Automatically download latest linux distributions"
            echo "Usage:"
            echo "    ./linux_downloader.sh [options]"
            echo ""
            echo "General Options:"
            echo "    -h, --help            Display this help message"
            echo "    -o, --output          Change the download directory, Default is current directory"
            echo "    --aria, --aria2       Download using aria2 with X amount of concurrent connections"
            echo "    --iso                 Download iso files instead of torrent files"
            echo "    --archlinux           Download Archlinux,           will not download others unless selected"
            echo "    --rocky               Download rocky,               will not download others unless selected"
            echo "    --debian              Download Debian,              will not download others unless selected"
            echo "    --fedora              Download Fedora,              will not download others unless selected"
            echo "    --kali                Download Kali,                will not download others unless selected"
            echo "    --opensuse            Download opensuse,            will not download others unless selected"
            echo "    --tumbleweed          Download opensuse tumbleweed, will not download others unless selected"
            echo "    --ubuntu              Download Ubuntu,              will not download others unless selected"
            echo "    --proxmox             Download Proxmox,            will not download others unless selected"
            echo "    --cleanup             Cleanup and remove lingering files"
            echo ""
            echo "Example:"
            echo "    ./linux_downloader.sh -o ~/Downloads/ --iso --archlinux --ubuntu --fedora"
            echo "    ./linux_downloader.sh -o ~/Downloads/ --rocky --fedora"
            echo "    ./linux_downloader.sh -o ~/Downloads/ --iso --aria 5 --archlinux"
            echo ""
            exit 0
            ;;
        -o | --output) # Takes an option argument; ensure it has been specified.
            if [ "$2" ]; then
                output="$2"
                mkdir -p "$output"
                shift
            else
                die 'ERROR: "--extension" requires a non-empty option argument.'
            fi
            ;;
        --test)
            test=1
            type="Testing"
            ;;
        --aria | --aria2)
            if [ "$2" ]; then
                aria=1
                concurrent="$2"
                download="aria2c -c -P --follow-torrent=false --summary-interval=0 -x $concurrent"
                shift
            else
                die 'ERROR: "--aria/aria2" requires amount of concurrent connections'
            fi
            ;;
        --iso)
            extension=".iso"
            ;;
        --archlinux)
            all=0
            archlinux=1
            ;;
        --rocky)
            all=0
            rocky=1
            ;;
        --debian)
            all=0
            debian=1
            ;;
        --fedora)
            all=0
            fedora=1
            ;;
        --proxmox)
            all=0
            proxmox=1
            ;;
        --kali)
            all=0
            kali=1
            ;;
        --opensuse)
            all=0
            opensuse=1
            ;;
        --tumbleweed)
            all=0
            tumbleweed=1
            ;;
        --ubuntu)
            all=0
            ubuntu=1
            ;;
        --cleanup)
            cleanup
            exit
            ;;
        --) # End of all options.
            shift
            break
            ;;
        -?*)
            printf 'WARN: Unknown option (ignored): %s\n' "$1" >&2
            ;;
        *) # Default case: No more options, so break out of the loop.
            break ;;
    esac
    shift
done

# Archlinux
if [[ $all -eq 1 || $archlinux -eq 1 ]]; then
    echo "$type Archlinux"

    link="$arch_ftp"/latest
    checksumfile=sha1sums.txt
    
    if [ "$test" -eq 1 ]; then
        testlink="$link"/"$checksumfile"
        tester
    else
        if [ "$extension" == ".torrent" ]; then
            downloader "$link"/ "$output"
        else
            while true; do
                downloader "$link"/"$checksumfile" "$output"
                filename=$(grep .iso "$output"/"$checksumfile" | cut -d' ' -f3)
                checksum=$(grep .iso "$output"/"$checksumfile" | cut -d' ' -f1)

                downloader "$link"/"$filename" "$output"
                filechecksum=$(sha1sum "$output"/"$filename" | cut -d' ' -f1)

                if [ "$checksum" = "$filechecksum" ]; then
                    break
                fi

                echo "$filename failed, Redownloading"
                rm -f "$output"/"$filename"
            done

            rm -f "$output"/"$checksumfile"
        fi
    fi

    echo "Archlinux Done"
fi

# Debian
if [[ $all -eq 1 || $debian -eq 1 ]]; then
    echo "$type Debian"

    checksumfile=SHA512SUMS
    if [ "$extension" == ".torrent" ]; then
        link="$debian_ftp"/bt-dvd
    else
        link="$debian_ftp"/iso-cd
    fi

    if [ "$test" -eq 1 ]; then
        testlink="$link"/"$checksumfile"
        tester
    else
        if [ "$extension" == ".torrent" ]; then
            downloader "$link"/ "$output"
        else
            downloader "$link"/"$checksumfile" "$output"
            number=$(cat "$output"/"$checksumfile" | wc -l)

            for i in `seq 1 "$number"`; do
                while true; do
                    filename=$(awk NR=="$i" "$output"/"$checksumfile" | cut -d' ' -f3)
                    checksum=$(awk NR=="$i" "$output"/"$checksumfile" | cut -d' ' -f1)

                    downloader "$link"/"$filename" "$output"
                    filechecksum=$(sha512sum "$output"/"$filename" | cut -d' ' -f1)

                    if [ "$checksum" = "$filechecksum" ]; then
                        break
                    fi

                    echo "$filename failed, Redownloading"
                    rm -f "$output"/"$filename"
                done
            done

            rm -f "$output"/"$checksumfile"
        fi
    fi
    echo "Debian Done"
fi

# Fedora
if [[ $all -eq 1 || $fedora -eq 1 ]]; then
    echo "$type Fedora"
    
    if [ "$extension" == ".torrent" ]; then
        link="$fedora_torrent"
    else
        # This curl requires -L so it can figure out the redirected link
        fedora=$($curler -o /dev/null -w %{url_effective} "$fedora_iso")
        release=$(eval "$curler" "$fedora" | awk -F 'href="' '{print $2}' | cut -d'/' -f1 | sort -n -r | awk NR==1)
        link="$fedora$release"
    fi

    if [ "$test" -eq 1 ]; then
        if [ "$extension" == ".torrent" ]; then
            testlink="$link"/
        else
            checksumfile=$(eval "$curler" "$link"/Server/x86_64/iso/ | grep CHECKSUM | awk -F 'href="' '{print $2}' | cut -d'"' -f1)
            testlink="$link"/Server/x86_64/iso/"$checksumfile"
        fi
        tester
    else
        if [ "$extension" == ".torrent" ]; then
            for distro in ${fedora_distributions[@]}; do
                echo "$distro"
                total=$(eval "$curler" "$link"/)
                fedora64=$(echo "$total" | grep "Fedora-"$distro"-" | grep 'x86_64' | awk -F 'href="' '{print $2}' | cut -d'"' -f1 | sort -n -r | awk NR==1)
                if [ ! -z "$fedora64" ]; then
                    downloader "$link"/"$fedora64" "$output"
                else
                    echo "$distro"" 64 bit does not exist"
                fi
            done
        else
            echo "$link"
            for distro in ${fedora_distributions[@]}; do
                checksumfile=$(eval "$curler" "$link"/"$distro"/x86_64/iso/ | grep CHECKSUM | awk -F 'href="' '{print $2}' | cut -d'"' -f1)
                downloader "$link"/"$distro"/x86_64/iso/"$checksumfile" "$output"
                number=$(awk '/# Fedora/{print $2}' "$output"/"$checksumfile" | wc -l)

                for i in `seq 1 "$number"`; do
                    while true; do
                        filename=$(awk '/# Fedora/{print $2}' "$output"/"$checksumfile" | awk NR=="$i" | cut -d':' -f1)
                        checksum=$(awk '/ = /{print $(NF)}' "$output"/"$checksumfile" | awk NR=="$i")

                        downloader "$link"/"$distro"/x86_64/iso/"$filename" "$output"               
                        filechecksum=$(sha256sum "$output"/"$filename" | cut -d' ' -f1)

                        if [ "$checksum" = "$filechecksum" ]; then
                            break
                        fi

                        echo "$filename failed, Redownloading"
                        rm -f "$output"/"$filename"
                    done
                done

                rm -f "$output"/"$checksumfile"
            done
        fi
    fi

    echo "Fedora Done"
fi

# Kali
if [[ $all -eq 1 || $kali -eq 1 ]]; then
    echo "$type Kali"

    filename=$(eval "$curler" "$kali_iso"/ | awk -F 'href="' '{print $2}' | cut -d'"' -f1 | grep installer-amd64.iso | awk -F '.iso' '{print $1}')
    echo $filename
    checksumfile=SHA256SUMS
    if [ "$extension" == ".torrent" ]; then
        link="$kali_torrent"     
    else
        link="$kali_iso" 
    fi

    if [ "$test" -eq 1 ]; then
        if [ "$extension" == ".torrent" ]; then
            testlink="$link"/"$filename".torrent
        else
            testlink="$link"/"$checksumfile"
        fi
        tester
    else
        if [ "$extension" == ".torrent" ]; then
            echo "$link"/"$filename""$extension" "$output"
            downloader "$link"/"$filename"".iso""$extension" "$output"
        else
            while true; do
                downloader "$link"/"$checksumfile" "$output"
                checksum=$(grep "$filename" "$output"/"$checksumfile" | cut -d' ' -f1)
                
                downloader "$link"/"$filename" "$output"
                filechecksum=$(sha256sum "$output"/"$filename" | cut -d' ' -f1)

                if [ "$checksum" = "$filechecksum" ]; then
                    break
                fi

                echo "$filename failed, Redownloading"
                rm -f "$output"/"$filename"
            done

            rm -f "$output"/"$checksumfile"
        fi
    fi

    echo "Kali Done"
fi


# Proxmox

if [[ $all -eq 1 || $proxmox -eq 1 ]]; then
    echo "$type proxmox"
    proxmoxfile=$(eval $curler "$proxmox_url"/ | awk -F 'href="' '{print $2}' | cut -d'"' -f1 | grep "proxmox-ve_" | sort -n -r | awk NR==1)
    link="$proxmox_url"/"$proxmoxfile"
    signature=$(eval $curler "$proxmox_url"/ | awk -F 'href="' '{print $2}' | cut -d'"' -f1 | grep "SHA256SUMS.asc" | awk -F ".asc")
    signaturelink="${proxmox_url}"/"${signature}"
    checksumfile="SHA256SUMS"
    if [ "$test" -eq 1 ]; then
        testlink="$proxmox_url"/"$checksumfile"
        tester
    else
        downloader "$proxmox_url"/"$proxmoxfile" "$output"
        #downloader "$proxmox_url"/"$SHA256SUMS" "$output"
        #downloader "$proxmox_url"/"$proxmoxfile" "$output"
#        number=$(grep SHA256SUMS "$output"/"$checksumfile" | wc -l)
 #       for i in $(seq 1 $number); do
  #          while true; do
   #             filename=$(grep SHA256SUMS "$output"/"$checksumfile" | cut -d' ' -f2 | awk NR=="$i" | tr -d '()')
    #            checksum=$(grep SHA256SUMS "$output"/"$checksumfile" | cut -d' ' -f4 | awk NR=="$i")
     #           echo $filename
      #          downloader "$proxmox_url"/"$filename" "$output"
       #         filechecksum=$(SHA256SUMS "$output"/"$filename" | cut -d' ' -f1)
        #        if [ "$checksum" = "$filechecksum" ]; then
         #           break
          #      fi
           #     echo "$filename failed, Redownloading"
            #    rm -f "$output"/"$filename"
            #done
        #done
        rm -f "$output"/"$checksumfile"
    fi
    echo "proxmox Done"
fi

# Rocky
if [[ $all -eq 1 || $rocky -eq 1 ]]; then
    echo "$type Rocky"
    release=$(eval $curler "$rocky_ftp" | awk -F 'href="' '{print $2}' | cut -d'/' -f1 | sort -n -r | awk NR==1)
    checksumfile="CHECKSUM"
    link="$rocky_ftp""$release"/isos/x86_64
    distros=$(eval $curler "$link"/ | awk -F 'href="' '{print $2}' | cut -d'"' -f1 | grep 'dvd1.torrent')
    #link="$rocky_ftp""$release"/isos/x86_64
    for i in ${distros[@]}; do
            filename=$(eval echo "$i" | awk -F '.torrent' '{print $1}')
            extension=".torrent"
            #test="${link}/${filename}${extension}"
            #echo "$test"
    done
    if [ "$test" -eq 1 ]; then
        testlink="$link"/"$checksumfile"
        tester
    else
        if [ "$extension" == ".torrent" ]; then
            downloader "$link"/"$filename".torrent "$output"
        else        
            downloader "$link"/"$checksumfile" "$output"
            number=$(grep SHA256 "$output"/"$checksumfile" | wc -l)

            for i in `seq 1 "$number"`; do
                while true; do
                    filename=$(grep SHA256 "$output"/"$checksumfile" | cut -d' ' -f2 | awk NR=="$i" | tr -d '()')
                    checksum=$(grep SHA256 "$output"/"$checksumfile" | cut -d' ' -f4 | awk NR=="$i")

                    downloader "$link"/"$filename" "$output"
                    filechecksum=$(sha256sum "$output"/"$filename" | cut -d' ' -f1)

                    if [ "$checksum" = "$filechecksum" ]; then
                        break
                    fi

                    echo "$filename failed, Redownloading"
                    rm -f "$output"/"$filename"
                done
            done

            rm -f "$output"/"$checksumfile"
        fi
    fi

    echo "Rocky Done"
fi


# OpenSUSE Current
if [[ $all -eq 1 || $opensuse -eq 1 ]]; then
    echo "$type OpenSUSE Current"

    distros=$(eval "$curler" "$opensuse_current"/ | awk -F 'href="' '{print $2}' | cut -d'"' -f1 | grep '.sha256')
    link="$opensuse_current" 

    if [ "$test" -eq 1 ]; then
        checksumfile=$(echo "$distros" | awk NR==1)
        testlink="$link"/"$checksumfile"
        tester
    else
        for i in ${distros[@]}; do
            filename=$(eval echo "$i" | awk -F '.sha256' '{print $1}')
            checksumfile="$i"

            if [ "$extension" == ".torrent" ]; then
                downloader "$link"/"$filename".torrent "$output"
            else
                downloader "$link"/"$checksumfile" "$output"

                while true; do
                    checksum=$(grep "$filename" "$output"/"$checksumfile" | cut -d' ' -f1)

                    downloader "$link"/"$filename" "$output"
                    filechecksum=$(sha256sum "$output"/"$filename" | cut -d' ' -f1)

                    if [ "$checksum" = "$filechecksum" ]; then
                        break
                    fi

                    echo "$filename failed, Redownloading"
                    rm -f "$output"/"$filename"
                done

                rm -f "$output"/"$checksumfile"
            fi

        done
    fi
    echo "OpenSUSE Done"
fi

# OpenSUSE Tumbleweed
if [[ $all -eq 1 || $tumbleweed -eq 1 ]]; then
    echo "$type OpenSUSE Tumbleweed"

    distros=$(eval "$curler" "$opensuse_tumbleweed"/ | awk -F 'href="' '{print $2}' | cut -d'"' -f1 | grep 'openSUSE-Tumbleweed-DVD' | grep 'Snapshot' | grep 'sha256')
    link="$opensuse_tumbleweed" 

    if [ "$test" -eq 1 ]; then
        checksumfile=$(echo "$distros" | awk NR==1)
        testlink="$link"/"$checksumfile"
        tester
    else
        for i in ${distros[@]}; do
            filename=$(eval echo "$i" | awk -F '.sha256' '{print $1}')
            checksumfile="$i"

            if [ "$extension" == ".torrent" ]; then
                downloader "$link"/"$filename".torrent "$output"
            else
                downloader "$link"/"$checksumfile" "$output"

                while true; do
                    checksum=$(grep "$filename" "$output"/"$checksumfile" | cut -d' ' -f1)

                    downloader "$link"/"$filename" "$output"
                    filechecksum=$(sha256sum "$output"/"$filename" | cut -d' ' -f1)

                    if [ "$checksum" = "$filechecksum" ]; then
                        break
                    fi

                    echo "$filename failed, Redownloading"
                    rm -f "$output"/"$filename"
                done

                rm -f "$output"/"$checksumfile"
            fi

        done
    fi
    echo "OpenSUSE Done"
fi

# Ubuntu
if [[ $all -eq 1 || $ubuntu -eq 1 ]]; then
    echo "$type Ubuntu"

    release=$(eval "$curler" "$ubuntu_ftp"/ | sort -n -r | awk NR==1)
    link="$ubuntu_ftp"/"$release"
    checksumfile=SHA256SUMS

    if [ "$test" -eq 1 ]; then
        testlink="$link"/"$checksumfile"
        tester
    else
        if [ "$extension" == ".torrent" ]; then
            downloader "$link"/ "$output"
        else
            downloader "$link"/"$checksumfile" "$output"
            number=$(cat "$output"/"$checksumfile" | wc -l)

            for i in `seq 1 "$number"`; do
                while true; do
                    filename=$(cut -d'*' -f2 "$output"/"$checksumfile" | awk NR=="$i")
                    checksum=$(grep "$filename" "$output"/"$checksumfile" | cut -d' ' -f1)

                    downloader "$link"/"$filename" "$output"
                    filechecksum=$(sha256sum "$output"/"$filename" | cut -d' ' -f1)

                    if [ "$checksum" = "$filechecksum" ]; then
                        break
                    fi

                    echo "$filename failed, Redownloading"
                    rm -f "$output"/"$filename"
                done
            done

            rm -f "$output"/"$checksumfile"
        fi
    fi

    echo "Ubuntu Done"
fi

# Clean up index files that might of been downloaded
cleanup
