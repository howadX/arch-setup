#!/bin/bash
set -euo pipefail

PKG_FILE="packages.txt"
LOG_FILE="install.log"

# ----------------------------
# Arch Linux setup script v2
# ----------------------------
# Usage: ./install.sh
# Make sure you have sudo privileges
# ----------------------------

echo "=== Arch Setup Script ==="
echo "Logging to $LOG_FILE"
echo "" > "$LOG_FILE"

if [[ ! -f "$PKG_FILE" ]]; then
    echo "Error: $PKG_FILE not found!" | tee -a "$LOG_FILE"
    exit 1
fi

PACMAN_PKGS=()
AUR_PKGS=()

# --- Split packages ---
while IFS= read -r pkg; do
    [[ "$pkg" =~ ^#.*$ ]] && continue
    [[ -z "$pkg" ]] && continue

    if pacman -Si "$pkg" &>/dev/null; then
        PACMAN_PKGS+=("$pkg")
    else
        AUR_PKGS+=("$pkg")
    fi
done < "$PKG_FILE"

echo "Official packages: ${#PACMAN_PKGS[@]}" | tee -a "$LOG_FILE"
echo "AUR packages: ${#AUR_PKGS[@]}" | tee -a "$LOG_FILE"

# --- System update ---
echo "Updating system..." | tee -a "$LOG_FILE"
sudo pacman -Syu --noconfirm >> "$LOG_FILE" 2>&1

# --- Install official packages ---
if [[ ${#PACMAN_PKGS[@]} -gt 0 ]]; then
    echo "Installing official packages..." | tee -a "$LOG_FILE"
    for pkg in "${PACMAN_PKGS[@]}"; do
        if pacman -Qi "$pkg" &>/dev/null; then
            echo "[SKIP] $pkg already installed" | tee -a "$LOG_FILE"
        else
            echo "[INSTALL] $pkg" | tee -a "$LOG_FILE"
            sudo pacman -S --needed --noconfirm "$pkg" >> "$LOG_FILE" 2>&1
        fi
    done
fi

# --- Install yay if missing ---
if ! command -v yay &>/dev/null; then
    echo "yay not found. Installing yay..." | tee -a "$LOG_FILE"
    tmpdir=$(mktemp -d)
    git clone https://aur.archlinux.org/yay.git "$tmpdir/yay" >> "$LOG_FILE" 2>&1
    cd "$tmpdir/yay"
    makepkg -si --noconfirm >> "$LOG_FILE" 2>&1
    cd -
    rm -rf "$tmpdir"
fi

# --- Install AUR packages ---
if [[ ${#AUR_PKGS[@]} -gt 0 ]]; then
    echo "Installing AUR packages..." | tee -a "$LOG_FILE"
    for pkg in "${AUR_PKGS[@]}"; do
        if yay -Qi "$pkg" &>/dev/null; then
            echo "[SKIP] $pkg already installed" | tee -a "$LOG_FILE"
        else
            echo "[INSTALL] $pkg (AUR)" | tee -a "$LOG_FILE"
            yay -S --needed --noconfirm --devel --removemake "$pkg" >> "$LOG_FILE" 2>&1
        fi
    done
fi

echo ""
echo "=== Installation complete ===" | tee -a "$LOG_FILE"
echo "Official packages installed: ${#PACMAN_PKGS[@]}" | tee -a "$LOG_FILE"
echo "AUR packages installed: ${#AUR_PKGS[@]}" | tee -a "$LOG_FILE"
echo "See $LOG_FILE for detailed output."
