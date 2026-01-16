#!/bin/bash
set -euo pipefail

PKG_FILE="packages.txt"

# --- Check if running as root ---
if [[ $EUID -eq 0 ]]; then
    echo "Warning: Do not run this script as root. Only pacman commands use sudo internally."
fi

echo "=== Arch Setup Script ==="
echo "Make sure you have sudo privileges"

if [[ ! -f "$PKG_FILE" ]]; then
    echo "Error: $PKG_FILE not found!"
    exit 1
fi

PACMAN_PKGS=()
AUR_PKGS=()

# --- Split packages into official / AUR ---
while IFS= read -r pkg; do
    [[ "$pkg" =~ ^#.*$ ]] && continue
    [[ -z "$pkg" ]] && continue

    if pacman -Si "$pkg" &>/dev/null; then
        PACMAN_PKGS+=("$pkg")
    else
        AUR_PKGS+=("$pkg")
    fi
done < "$PKG_FILE"

echo "Official packages: ${#PACMAN_PKGS[@]}"
echo "AUR packages: ${#AUR_PKGS[@]}"

# --- Update system ---
echo "Updating system..."
sudo pacman -Syu --noconfirm

# --- Install official packages ---
if [[ ${#PACMAN_PKGS[@]} -gt 0 ]]; then
    echo "Installing official packages..."
    for pkg in "${PACMAN_PKGS[@]}"; do
        if pacman -Qi "$pkg" &>/dev/null; then
            echo "[SKIP] $pkg already installed"
        else
            echo "[INSTALL] $pkg"
            sudo pacman -S --needed --noconfirm "$pkg"
        fi
    done
fi

# --- Ensure Node.js and npm are installed for Node-based AUR packages ---
echo "Installing Node.js and npm (required for some AUR packages)..."
sudo pacman -S --needed --noconfirm nodejs npm

# --- Install yay if missing ---
if ! command -v yay &>/dev/null; then
    echo "yay not found. Installing yay..."
    tmpdir=$(mktemp -d)
    git clone https://aur.archlinux.org/yay.git "$tmpdir/yay"
    cd "$tmpdir/yay"
    # Установка yay от обычного пользователя
    makepkg -si --noconfirm
    cd -
    rm -rf "$tmpdir"
fi

# --- Install AUR packages ---
if [[ ${#AUR_PKGS[@]} -gt 0 ]]; then
    echo "Installing AUR packages..."
    for pkg in "${AUR_PKGS[@]}"; do
        if yay -Qi "$pkg" &>/dev/null; then
            echo "[SKIP] $pkg already installed"
        else
            echo "[INSTALL] $pkg (AUR)"
            # Очистка кеша исходников перед сборкой
            rm -rf ~/.cache/yay/"$pkg"
            # Установка пакета
            yay -S --needed --noconfirm --devel --removemake --noedit "$pkg"
        fi
    done
fi

echo ""
echo "=== Installation complete ==="
echo "Official packages installed: ${#PACMAN_PKGS[@]}"
echo "AUR packages installed: ${#AUR_PKGS[@]}"
