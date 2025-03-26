#!/bin/bash

# Reset color
reset=$(tput sgr0)

# Colors for the dots (you can adjust these to match your theme)
dot1=$(tput setaf 0)  # Black
dot2=$(tput setaf 8)  # Gray
dot3=$(tput setaf 7)  # White
dot4=$(tput setaf 15) # Bright white

# Function to get system information dynamically
get_username() {
    whoami
}

get_distro() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        echo "$NAME"
    else
        echo "Unknown"
    fi
}

get_arch() {
    uname -m
}

get_kernel() {
    uname -r
}

get_uptime() {
    uptime -p | sed 's/up //'
}

get_init() {
    if [ -d /run/systemd/system ]; then
        echo "systemd"
    elif [ -f /sbin/init ] && strings /sbin/init | grep -q sysvinit; then
        echo "sysvinit"
    elif command -v runit >/dev/null 2>&1; then
        echo "runit"
    else
        echo "Custom"
    fi
}

get_cpu() {
    lscpu | grep "Model name" | awk -F: '{print $2}' | sed 's/^[ \t]*//' | sed 's/ \+/ /g'
}

get_gpu() {
    lspci | grep -i vga | grep -i nvidia | awk -F: '{print $3}' | sed 's/^[ \t]*//' || echo ""
}

get_vram() {
    if command -v nvidia-smi >/dev/null 2>&1; then
        nvidia-smi --query-gpu=memory.total --format=csv,noheader,nounits | awk '{print $1 " MiB"}'
    else
        echo ""
    fi
}

get_ram() {
    free -m | awk '/Mem:/ {print $3 " / " $2 " MiB"}'
}

get_disk() {
    df -h / | awk 'NR==2 {print $3 " / " $2 " (" $5 ")"}'
}

get_monitor() {
    if command -v xrandr >/dev/null 2>&1; then
        xrandr | grep " connected" | grep -o "[0-9]\+x[0-9]\+@[0-9.]\+Hz" | head -1 || echo ""
    else
        echo ""
    fi
}

get_editor() {
    if command -v nvim >/dev/null 2>&1; then
        echo "/bin/nvim"
    elif [ -n "$EDITOR" ]; then
        echo "$EDITOR"
    else
        echo ""
    fi
}

get_shell() {
    basename "$SHELL"
}

get_packages() {
    # Check if the system is Linux From Scratch
    if [ -f /etc/os-release ] && grep -q "Linux From Scratch" /etc/os-release; then
        # Count directories in ~/sources
        if [ -d "$HOME/sources" ]; then
            find "$HOME/sources" -maxdepth 1 -type d | wc -l | awk '{print $1-1 " (sources)"}'
        else
            echo "0 (sources)"
        fi
    elif command -v pacman >/dev/null 2>&1; then
        pacman -Q | wc -l | awk '{print $1 " (pacman)"}'
    elif command -v dpkg >/dev/null 2>&1; then
        dpkg -l | grep ^ii | wc -l | awk '{print $1 " (dpkg)"}'
    else
        echo ""
    fi
}

get_wm() {
    if [ -n "$XDG_CURRENT_DESKTOP" ]; then
        echo "$XDG_CURRENT_DESKTOP (X11)"
    elif [ -n "$DESKTOP_SESSION" ]; then
        echo "$DESKTOP_SESSION (X11)"
    else
        echo ""
    fi
}

get_song() {
    if command -v mpc >/dev/null 2>&1; then
        mpc current 2>/dev/null || echo ""
    else
        echo ""
    fi
}

# Get all system information
username=$(get_username)
distro=$(get_distro)
arch=$(get_arch)
kernel=$(get_kernel)
uptime=$(get_uptime)
init=$(get_init)
cpu=$(get_cpu)
gpu=$(get_gpu)
vram=$(get_vram)
ram=$(get_ram)
disk=$(get_disk)
monitor=$(get_monitor)
editor=$(get_editor)
shell=$(get_shell)
packages=$(get_packages)
wm=$(get_wm)
song=$(get_song)

# Path to the image (optional, leave empty if no image)
#image_path="./logo.png"

# Clear the screen
clear

# Check if image is provided and display it
image_width=0
if [ -n "$image_path" ] && [ -f "$image_path" ]; then
    # Display the image on the left
    # Adjust the size (20x20) and position (@0x0) as needed
    kitty +kitten icat --align left --place 20x20@0x0 "$image_path"
    # Set the image width (adjust based on your image)
    image_width=25
    # Move cursor down to avoid overlap
    tput cud 20
    # Move cursor back to the top-right of the image
    tput cuu 20
    tput cuf "$image_width"
else
    # No image, start from the left
    image_width=0
fi

# Print the username
echo -e "\n${username}\n"

# Print the color dots
echo -e "${dot1}● ${dot2}● ${dot3}● ${dot4}●${reset}\n"

# Print system information with exact formatting, only if the info exists
echo -e "--- System ---"
[ -n "$distro" ] && echo -e "Distro: ${distro}"
[ -n "$arch" ] && echo -e "Arch: ${arch}"
[ -n "$kernel" ] && echo -e "Kernel: ${kernel}"
[ -n "$uptime" ] && echo -e "Uptime: ${uptime}"
[ -n "$init" ] && echo -e "Init: ${init}"
echo -e ""

echo -e "--- Hardware ---"
[ -n "$cpu" ] && echo -e "CPU: ${cpu}"
[ -n "$gpu" ] && echo -e "GPU: ${gpu}"
[ -n "$vram" ] && echo -e "VRAM: ${vram}"
[ -n "$ram" ] && echo -e "RAM: ${ram}"
[ -n "$disk" ] && echo -e "Disk: ${disk}"
[ -n "$monitor" ] && echo -e "Monitor: ${monitor}"
echo -e ""

echo -e "--- Software ---"
[ -n "$editor" ] && echo -e "Editor: ${editor}"
[ -n "$shell" ] && echo -e "Shell: ${shell}"
[ -n "$packages" ] && echo -e "Packages: ${packages}"
[ -n "$wm" ] && echo -e "WM: ${wm}"
[ -n "$song" ] && echo -e "Song: ${song}"
echo -e ""

# Reset the cursor position
tput cud 1
