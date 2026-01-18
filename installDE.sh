#!/bin/bash
set -euo pipefail

# ============================================================================
# Arch Linux Desktop Environment Setup Script
# ============================================================================
# Philosophy: Desktop environments are frontend only
# System behavior and logic are handled separately
# This script configures visual appearance only - no hotkeys, workflows, or automation
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
USER_HOME="$HOME"
LOCAL_DIR="$USER_HOME/.local"
SYSTEM_DIR="$LOCAL_DIR/system"
CONFIG_DIR="$USER_HOME/.config"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[OK]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running as root
if [[ $EUID -eq 0 ]]; then
    log_error "Do not run this script as root. Only pacman commands use sudo internally."
    exit 1
fi

# Check for yay
if ! command -v yay &>/dev/null; then
    log_warn "yay not found. Installing yay..."
    tmpdir=$(mktemp -d)
    git clone https://aur.archlinux.org/yay.git "$tmpdir/yay"
    cd "$tmpdir/yay"
    makepkg -si --noconfirm
    cd -
    rm -rf "$tmpdir"
    log_success "yay installed"
fi

log_info "=== Arch Linux Desktop Environment Setup ==="
log_info "Preparing scalable, minimal, and visually unified desktop environment"

# ============================================================================
# Package Installation
# ============================================================================

log_info "Updating system..."
sudo pacman -Syu --noconfirm

package_exists_repo() {
    pacman -Si "$1" &>/dev/null
}

package_exists_aur() {
    yay -Si "$1" &>/dev/null
}

package_installed() {
    pacman -Qi "$1" &>/dev/null || yay -Qi "$1" &>/dev/null
}

# Wayland stack
log_info "Installing Wayland stack..."
WAYLAND_PKGS=(
    "pipewire"
    "pipewire-alsa"
    "pipewire-pulse"
    "pipewire-jack"
    "wireplumber"
    "xdg-desktop-portal"
    "xdg-desktop-portal-kde"
    "qt5-wayland"
    "qt6-wayland"
)

# Desktop environments
log_info "Installing desktop environments..."
DE_PKGS=(
    "plasma"
    "plasma-wayland-session"
    "sddm"
    "sddm-kcm"
    "hyprland"
)

# Display manager
log_info "Installing display manager..."
DM_PKGS=(
    "sddm"
)

# Hyprland tools
log_info "Installing Hyprland tools..."
HYPRLAND_TOOLS=(
    "waybar"
    "wofi"
    "grim"
    "slurp"
    "wl-clipboard"
)

# Developer stack
log_info "Installing developer stack..."
DEV_PKGS=(
    "gcc"
    "clang"
    "cmake"
    "make"
    "ninja"
    "gdb"
    "lldb"
    "python"
    "python-pip"
    "go"
    "openjdk"
    "dotnet-sdk"
    "docker"
    "visual-studio-code-bin"
)

# User applications
log_info "Installing user applications..."
USER_APPS=(
    "telegram-desktop"
    "discord"
    "steam"
    "obsidian"
    "amnezia-vpn"
)

# Theme packages
log_info "Installing theme packages..."
THEME_PKGS=(
    "kvantum-qt5"
    "kvantum-qt6"
    "papirus-icon-theme"
    "bibata-cursor-theme"
    "ttf-inter"
    "ttf-jetbrains-mono"
)

# Function to install packages
install_packages() {
    local -n packages=$1
    local category=$2

    for pkg in "${packages[@]}"; do
        
        # Already installed
        if package_installed "$pkg"; then
            log_info "[SKIP] $pkg already installed"
            continue
        fi

        # Official repo package
        if package_exists_repo "$pkg"; then
            log_info "[INSTALL] $pkg (repo → $category)"
            sudo pacman -S --needed --noconfirm "$pkg"
            continue
        fi

        # AUR package
        if package_exists_aur "$pkg"; then
            log_info "[INSTALL] $pkg (AUR → $category)"
            yay -S --needed --noconfirm --devel --removemake "$pkg"
            continue
        fi

        # Missing package
        log_warn "[MISSING] $pkg not found (skipped)"
    done
}


# Install all package groups
install_packages WAYLAND_PKGS "Wayland stack"
install_packages DE_PKGS "Desktop environments"
install_packages DM_PKGS "Display manager"
install_packages HYPRLAND_TOOLS "Hyprland tools"
install_packages DEV_PKGS "Developer stack"
install_packages USER_APPS "User applications"
install_packages THEME_PKGS "Themes"

# ============================================================================
# Docker user permissions
# ============================================================================

log_info "Configuring Docker user permissions..."
if ! groups | grep -q docker; then
    sudo usermod -aG docker "$USER"
    log_success "Added user to docker group (logout/login required)"
else
    log_info "User already in docker group"
fi

# ============================================================================
# System directory structure
# ============================================================================

log_info "Creating system directory structure..."
mkdir -p "$SYSTEM_DIR"
log_success "Created $SYSTEM_DIR (ready for future system-layer development)"

# ============================================================================
# Font Configuration
# ============================================================================

log_info "Configuring fonts..."
FONT_DIR="$LOCAL_DIR/share/fonts"
mkdir -p "$FONT_DIR"

# Create fontconfig directory
FONTCONFIG_DIR="$CONFIG_DIR/fontconfig"
mkdir -p "$FONTCONFIG_DIR"

# Font configuration for Inter (UI) and JetBrains Mono (monospace)
cat > "$FONTCONFIG_DIR/fonts.conf" << 'EOF'
<?xml version="1.0"?>
<!DOCTYPE fontconfig SYSTEM "fonts.dtd">
<fontconfig>
    <!-- UI Font: Inter -->
    <alias>
        <family>sans-serif</family>
        <prefer>
            <family>Inter</family>
        </prefer>
    </alias>
    
    <!-- Monospace Font: JetBrains Mono -->
    <alias>
        <family>monospace</family>
        <prefer>
            <family>JetBrains Mono</family>
        </prefer>
    </alias>
    
    <!-- Enable subpixel rendering -->
    <match target="font">
        <edit name="rgba" mode="assign"><const>rgb</const></edit>
        <edit name="hinting" mode="assign"><bool>true</bool></edit>
        <edit name="hintstyle" mode="assign"><const>hintslight</const></edit>
        <edit name="antialias" mode="assign"><bool>true</bool></edit>
    </match>
</fontconfig>
EOF

log_success "Font configuration created"

# ============================================================================
# KDE Plasma Configuration
# ============================================================================

log_info "Configuring KDE Plasma visual theme..."

KDE_CONFIG_DIR="$CONFIG_DIR"
mkdir -p "$KDE_CONFIG_DIR/kvantum"

# Download and configure Catppuccin Mocha theme for KDE
log_info "Setting up Catppuccin Mocha theme for KDE..."

# Create Kvantum theme directory
KVANTUM_THEME_DIR="$LOCAL_DIR/share/Kvantum"
mkdir -p "$KVANTUM_THEME_DIR/Catppuccin-Mocha"

# Download Catppuccin Kvantum theme if not present
if [[ ! -d "$KVANTUM_THEME_DIR/Catppuccin-Mocha" ]] || [[ -z "$(ls -A "$KVANTUM_THEME_DIR/Catppuccin-Mocha" 2>/dev/null)" ]]; then
    log_info "Downloading Catppuccin Kvantum theme..."
    KVANTUM_TMP=$(mktemp -d)
    git clone --depth=1 https://github.com/catppuccin/Kvantum.git "$KVANTUM_TMP/Kvantum" 2>/dev/null || {
        log_warn "Could not download Kvantum theme. You may need to install it manually."
    }
    if [[ -d "$KVANTUM_TMP/Kvantum/Catppuccin-Mocha" ]]; then
        cp -r "$KVANTUM_TMP/Kvantum/Catppuccin-Mocha" "$KVANTUM_THEME_DIR/"
        log_success "Catppuccin Mocha Kvantum theme installed"
    fi
    rm -rf "$KVANTUM_TMP"
fi

# KDE Global Settings (visual only - no hotkeys or workflows)
# Safety check
if [[ -d "$KDE_CONFIG_DIR/kdeglobals" ]]; then
    log_warn "kdeglobals exists as directory, removing"
    rm -rf "$KDE_CONFIG_DIR/kdeglobals"
fi

cat > "$KDE_CONFIG_DIR/kdeglobals" << 'EOF'
[General]
ColorScheme=CatppuccinMocha
Name=Catppuccin Mocha
shadeSortColumn=true

[KDE]
ColorScheme=CatppuccinMocha
contrast=4

[Colors:View]
BackgroundAlternate=#1e1e2e
BackgroundNormal=#11111b

[Colors:Window]
BackgroundAlternate=#1e1e2e
BackgroundNormal=#11111b

[Icons]
Theme=Papirus-Dark

[KDE]
widgetStyle=kvantum
EOF

# Kvantum configuration
cat > "$KDE_CONFIG_DIR/kvantum.kvconfig" << 'EOF'
[General]
theme=Catppuccin-Mocha
EOF

# KDE Plasma color scheme (Catppuccin Mocha colors)
COLOR_SCHEME_DIR="$LOCAL_DIR/share/color-schemes"
mkdir -p "$COLOR_SCHEME_DIR"

cat > "$COLOR_SCHEME_DIR/CatppuccinMocha.colors" << 'EOF'
[ColorEffects:Disabled]
Color=56,56,56
ColorAmount=0
ColorEffect=0
ContrastAmount=0.65
ContrastEffect=1
IntensityAmount=0.1
IntensityEffect=2

[ColorEffects:Inactive]
ChangeSelectionColor=true
Color=112,111,110
ColorAmount=0
ColorEffect=0
ContrastAmount=0.1
ContrastEffect=2
Enable=false
IntensityAmount=0
IntensityEffect=0

[Colors:Button]
BackgroundAlternate=#1e1e2e
BackgroundNormal=#11111b
DecorationFocus=#89b4fa
DecorationHover=#74c7ec
ForegroundActive=#cdd6f4
ForegroundInactive=#6c7086
ForegroundLink=#89b4fa
ForegroundNegative=#f38ba8
ForegroundNeutral=#fab387
ForegroundNormal=#cdd6f4
ForegroundPositive=#a6e3a1
ForegroundVisited=#cba6f7

[Colors:Complementary]
BackgroundAlternate=#1e1e2e
BackgroundNormal=#11111b
DecorationFocus=#89b4fa
DecorationHover=#74c7ec
ForegroundActive=#cdd6f4
ForegroundInactive=#6c7086
ForegroundLink=#89b4fa
ForegroundNegative=#f38ba8
ForegroundNeutral=#fab387
ForegroundNormal=#cdd6f4
ForegroundPositive=#a6e3a1
ForegroundVisited=#cba6f7

[Colors:Header]
BackgroundAlternate=#1e1e2e
BackgroundNormal=#11111b
DecorationFocus=#89b4fa
DecorationHover=#74c7ec
ForegroundActive=#cdd6f4
ForegroundInactive=#6c7086
ForegroundLink=#89b4fa
ForegroundNegative=#f38ba8
ForegroundNeutral=#fab387
ForegroundNormal=#cdd6f4
ForegroundPositive=#a6e3a1
ForegroundVisited=#cba6f7

[Colors:Header][Inactive]
BackgroundAlternate=#1e1e2e
BackgroundNormal=#11111b
DecorationFocus=#89b4fa
DecorationHover=#74c7ec
ForegroundActive=#cdd6f4
ForegroundInactive=#6c7086
ForegroundLink=#89b4fa
ForegroundNegative=#f38ba8
ForegroundNeutral=#fab387
ForegroundNormal=#cdd6f4
ForegroundPositive=#a6e3a1
ForegroundVisited=#cba6f7

[Colors:Selection]
BackgroundAlternate=#1e1e2e
BackgroundNormal=#89b4fa
DecorationFocus=#89b4fa
DecorationHover=#74c7ec
ForegroundActive=#11111b
ForegroundInactive=#6c7086
ForegroundLink=#89b4fa
ForegroundNegative=#f38ba8
ForegroundNeutral=#fab387
ForegroundNormal=#11111b
ForegroundPositive=#a6e3a1
ForegroundVisited=#cba6f7

[Colors:Tooltip]
BackgroundAlternate=#1e1e2e
BackgroundNormal=#11111b
DecorationFocus=#89b4fa
DecorationHover=#74c7ec
ForegroundActive=#cdd6f4
ForegroundInactive=#6c7086
ForegroundLink=#89b4fa
ForegroundNegative=#f38ba8
ForegroundNeutral=#fab387
ForegroundNormal=#cdd6f4
ForegroundPositive=#a6e3a1
ForegroundVisited=#cba6f7

[Colors:View]
BackgroundAlternate=#1e1e2e
BackgroundNormal=#11111b
DecorationFocus=#89b4fa
DecorationHover=#74c7ec
ForegroundActive=#cdd6f4
ForegroundInactive=#6c7086
ForegroundLink=#89b4fa
ForegroundNegative=#f38ba8
ForegroundNeutral=#fab387
ForegroundNormal=#cdd6f4
ForegroundPositive=#a6e3a1
ForegroundVisited=#cba6f7

[Colors:Window]
BackgroundAlternate=#1e1e2e
BackgroundNormal=#11111b
DecorationFocus=#89b4fa
DecorationHover=#74c7ec
ForegroundActive=#cdd6f4
ForegroundInactive=#6c7086
ForegroundLink=#89b4fa
ForegroundNegative=#f38ba8
ForegroundNeutral=#fab387
ForegroundNormal=#cdd6f4
ForegroundPositive=#a6e3a1
ForegroundVisited=#cba6f7

[General]
ColorScheme=CatppuccinMocha
Name=Catppuccin Mocha
shadeSortColumn=true

[KDE]
contrast=4
widgetStyle=kvantum
EOF

# KDE Plasma workspace settings (visual only)
PLASMA_CONFIG_DIR="$CONFIG_DIR/plasma-workspace"
mkdir -p "$PLASMA_CONFIG_DIR/env"

# Set cursor theme
cat > "$PLASMA_CONFIG_DIR/env/cursor.sh" << 'EOF'
export XCURSOR_THEME="Bibata-Modern-Ice"
export XCURSOR_SIZE=24
EOF

# GTK theme configuration for Catppuccin
GTK_THEME_DIR="$LOCAL_DIR/share/themes"
mkdir -p "$GTK_THEME_DIR"

log_info "Downloading Catppuccin GTK theme..."
GTK_TMP=$(mktemp -d)
git clone --depth=1 https://github.com/catppuccin/gtk.git "$GTK_TMP/gtk" 2>/dev/null || {
    log_warn "Could not download GTK theme. You may need to install it manually."
}
if [[ -d "$GTK_TMP/gtk" ]]; then
    # Build and install GTK theme
    if command -v meson &>/dev/null && command -v ninja &>/dev/null; then
        cd "$GTK_TMP/gtk"
        meson setup build -Dtheme=moppa -Dvariants=dark 2>/dev/null || log_warn "GTK theme build skipped"
        meson install -C build --destdir "$GTK_TMP/install" 2>/dev/null || log_warn "GTK theme install skipped"
        if [[ -d "$GTK_TMP/install" ]]; then
            cp -r "$GTK_TMP/install"/* "$LOCAL_DIR/" 2>/dev/null || true
        fi
        cd -
    fi
fi
rm -rf "$GTK_TMP"

# GTK settings
GTK_CONFIG_DIR="$CONFIG_DIR/gtk-3.0"
mkdir -p "$GTK_CONFIG_DIR"

cat > "$GTK_CONFIG_DIR/settings.ini" << 'EOF'
[Settings]
gtk-theme-name=Catppuccin-Mocha-Dark
gtk-icon-theme-name=Papirus-Dark
gtk-font-name=Inter 11
gtk-cursor-theme-name=Bibata-Modern-Ice
gtk-cursor-theme-size=24
gtk-application-prefer-dark-theme=true
EOF

cat > "$CONFIG_DIR/gtk-4.0/settings.ini" << 'EOF'
[Settings]
gtk-theme-name=Catppuccin-Mocha-Dark
gtk-icon-theme-name=Papirus-Dark
gtk-font-name=Inter 11
gtk-cursor-theme-name=Bibata-Modern-Ice
gtk-cursor-theme-size=24
gtk-application-prefer-dark-theme=true
EOF

log_success "KDE Plasma visual configuration completed"

# ============================================================================
# Hyprland Configuration
# ============================================================================

log_info "Configuring Hyprland visual theme..."

HYPRLAND_CONFIG_DIR="$CONFIG_DIR/hypr"
mkdir -p "$HYPRLAND_CONFIG_DIR"

# Hyprland main config (visual only - no keybindings or workflows)
cat > "$HYPRLAND_CONFIG_DIR/hyprland.conf" << 'EOF'
# ============================================================================
# Hyprland Configuration - Visual Theme Only
# ============================================================================
# Philosophy: This file contains visual styling only
# No keybindings, workflows, or automation logic
# ============================================================================

# Monitor configuration (example - adjust for your setup)
# monitor=,preferred,auto,1

# Execute on startup (visual only)
exec-once = waybar
exec-once = wl-paste --type text --watch cliphist store
exec-once = wl-paste --type image --watch cliphist store

# Environment variables
env = XCURSOR_THEME,Bibata-Modern-Ice
env = XCURSOR_SIZE,24
env = QT_QPA_PLATFORM,wayland
env = QT_WAYLAND_DISABLE_WINDOWDECORATION,1

# Input configuration
input {
    kb_layout = us
    follow_mouse = 1
    touchpad {
        natural_scroll = yes
    }
    sensitivity = 0
}

# General appearance
general {
    gaps_in = 8
    gaps_out = 12
    border_size = 2
    col.active_border = rgba(89b4faaa) rgba(74c7ecaa) 45deg
    col.inactive_border = rgba(11111baa)
    layout = dwindle
    allow_tearing = false
}

# Decoration (rounded corners, shadows)
decoration {
    rounding = 12
    blur {
        enabled = true
        size = 8
        passes = 3
        new_optimizations = true
        xray = false
    }
    drop_shadow = yes
    shadow_range = 20
    shadow_render_power = 3
    col.shadow = rgba(00000088)
    col.shadow_inactive = rgba(00000044)
}

# Animations (smooth, non-aggressive)
animations {
    enabled = yes
    bezier = myBezier, 0.4, 0.0, 0.2, 1
    animation = windows, 1, 7, myBezier
    animation = windowsOut, 1, 7, default, popin 80%
    animation = border, 1, 10, default
    animation = borderangle, 1, 8, default
    animation = fade, 1, 7, default
    animation = workspaces, 1, 6, default
}

# Dwindle layout
dwindle {
    pseudotile = yes
    preserve_split = yes
}

# Window rules (visual only)
windowrule = float, ^(pavucontrol)$
windowrule = float, ^(blueman-manager)$
windowrule = float, ^(nm-connection-editor)$
windowrule = float, ^(chromium)$
windowrule = float, ^(thunar)$
windowrule = float, ^(wofi)$
windowrule = float, ^(waybar)$
windowrule = opacity 0.9, ^(waybar)$
EOF

# Waybar configuration (Catppuccin Mocha theme)
WAYBAR_CONFIG_DIR="$CONFIG_DIR/waybar"
mkdir -p "$WAYBAR_CONFIG_DIR"

cat > "$WAYBAR_CONFIG_DIR/config" << 'EOF'
{
    "layer": "top",
    "position": "top",
    "height": 40,
    "spacing": 8,
    "modules-left": ["hyprland/workspaces"],
    "modules-center": ["clock"],
    "modules-right": ["tray", "pulseaudio", "network", "battery", "cpu", "memory"],
    
    "hyprland/workspaces": {
        "disable-scroll": true,
        "all-outputs": true,
        "format": "{icon}",
        "format-icons": {
            "1": "一",
            "2": "二",
            "3": "三",
            "4": "四",
            "5": "五",
            "urgent": "󰠗",
            "focused": "󰮯",
            "default": "󰧨"
        }
    },
    
    "clock": {
        "format": "{:%Y-%m-%d %H:%M}",
        "tooltip-format": "<big>{:%Y %B}</big>\n<tt><small>{calendar}</small></tt>"
    },
    
    "pulseaudio": {
        "format": "{icon} {volume}%",
        "format-muted": "󰝟",
        "format-icons": {
            "headphone": "󰋋",
            "hands-free": "󰋎",
            "headset": "󰋎",
            "phone": "󰄜",
            "portable": "󰦧",
            "car": "󰄋",
            "default": ["󰕿", "󰖀", "󰕾"]
        },
        "on-click": "pavucontrol"
    },
    
    "network": {
        "format-wifi": "󰤨 {signalStrength}%",
        "format-ethernet": "󰈀",
        "format-disconnected": "󰤭",
        "tooltip-format": "{ifname} via {ipaddr}",
        "tooltip-format-wifi": "{essid} ({signalStrength}%) 󰤨",
        "tooltip-format-ethernet": "{ifname} 󰈀",
        "tooltip-format-disconnected": "Disconnected"
    },
    
    "battery": {
        "states": {
            "warning": 30,
            "critical": 15
        },
        "format": "{icon} {capacity}%",
        "format-charging": "󰂄 {capacity}%",
        "format-plugged": "󰂄 {capacity}%",
        "format-alt": "{icon} {time}",
        "format-icons": ["󰁺", "󰁻", "󰁼", "󰁽", "󰁾", "󰁿", "󰂀", "󰂁", "󰂂", "󰁹"]
    },
    
    "cpu": {
        "format": "󰻠 {usage}%",
        "interval": 2
    },
    
    "memory": {
        "format": "󰍛 {}%",
        "interval": 2
    },
    
    "tray": {
        "icon-size": 20,
        "spacing": 8
    }
}
EOF

# Waybar style (Catppuccin Mocha)
cat > "$WAYBAR_CONFIG_DIR/style.css" << 'EOF'
* {
    border: none;
    border-radius: 0;
    font-family: "Inter", "Font Awesome 6 Free";
    font-size: 13px;
    min-height: 0;
}

window#waybar {
    background-color: rgba(17, 17, 27, 0.95);
    border-bottom: 2px solid rgba(137, 180, 250, 0.3);
    color: #cdd6f4;
    transition-property: background-color;
    transition-duration: 0.5s;
    border-radius: 0 0 12px 12px;
}

window#waybar.hidden {
    opacity: 0.2;
}

button {
    box-shadow: inset 0 -3px transparent;
    border: none;
    border-radius: 0;
}

button:hover {
    background: inherit;
    box-shadow: inset 0 -3px #89b4fa;
}

#workspaces button {
    padding: 0 8px;
    background-color: transparent;
    color: #6c7086;
    border-radius: 8px;
    margin: 4px 2px;
}

#workspaces button:hover {
    background: rgba(137, 180, 250, 0.2);
    color: #89b4fa;
}

#workspaces button.focused {
    background-color: rgba(137, 180, 250, 0.3);
    color: #89b4fa;
    box-shadow: inset 0 -3px #89b4fa;
}

#workspaces button.urgent {
    background-color: #f38ba8;
    color: #11111b;
}

#clock,
#battery,
#cpu,
#memory,
#network,
#pulseaudio,
#tray {
    padding: 0 12px;
    color: #cdd6f4;
    border-radius: 8px;
    margin: 4px 2px;
}

#clock {
    background-color: rgba(137, 180, 250, 0.2);
    font-weight: bold;
}

#battery {
    background-color: rgba(166, 227, 161, 0.2);
}

#battery.charging, #battery.plugged {
    color: #a6e3a1;
    background-color: rgba(166, 227, 161, 0.3);
}

#battery.critical:not(.charging) {
    background-color: rgba(243, 139, 168, 0.3);
    color: #f38ba8;
    animation-name: blink;
    animation-duration: 0.5s;
    animation-timing-function: linear;
    animation-iteration-count: infinite;
    animation-direction: alternate;
}

#cpu {
    background-color: rgba(116, 199, 236, 0.2);
}

#memory {
    background-color: rgba(203, 166, 247, 0.2);
}

#network {
    background-color: rgba(250, 179, 135, 0.2);
}

#network.disconnected {
    background-color: rgba(243, 139, 168, 0.2);
    color: #f38ba8;
}

#pulseaudio {
    background-color: rgba(137, 180, 250, 0.2);
}

#pulseaudio.muted {
    background-color: rgba(108, 112, 134, 0.2);
    color: #6c7086;
}

#tray {
    background-color: rgba(17, 17, 27, 0.5);
}

#tray > .passive {
    -gtk-icon-effect: dim;
}

#tray > .needs-attention {
    -gtk-icon-effect: highlight;
    background-color: #f38ba8;
}

@keyframes blink {
    to {
        background-color: rgba(243, 139, 168, 0.5);
        color: #11111b;
    }
}
EOF

log_success "Hyprland visual configuration completed"

# ============================================================================
# SDDM Configuration
# ============================================================================

log_info "Configuring SDDM..."

# SDDM theme directory
SDDM_THEME_DIR="/usr/share/sddm/themes"
SDDM_CONFIG_DIR="/etc/sddm.conf.d"

# Create SDDM config (requires sudo)
log_info "Setting up SDDM Wayland session..."
sudo mkdir -p "$SDDM_CONFIG_DIR"

sudo tee "$SDDM_CONFIG_DIR/wayland.conf" > /dev/null << 'EOF'
[General]
DisplayServer=wayland

[Wayland]
SessionCommand=/usr/share/sddm/scripts/wayland-session
SessionDir=/usr/share/wayland-sessions
SessionLogFile=. wayland-session.log
EOF

log_success "SDDM configuration completed"

# ============================================================================
# Final Steps
# ============================================================================

log_info "Enabling services..."

# Enable SDDM
if systemctl is-enabled sddm &>/dev/null; then
    log_info "SDDM already enabled"
else
    sudo systemctl enable sddm
    log_success "SDDM enabled"
fi

# Enable Docker
if systemctl is-enabled docker &>/dev/null; then
    log_info "Docker already enabled"
else
    sudo systemctl enable docker
    log_success "Docker enabled"
fi

# Enable PipeWire
systemctl --user enable pipewire pipewire-pulse wireplumber 2>/dev/null || log_warn "PipeWire user services may need manual enable"

log_success "Services configured"

# ============================================================================
# Summary
# ============================================================================

echo ""
log_success "=== Desktop Environment Setup Complete ==="
echo ""
log_info "Installed and configured:"
echo "  ✓ KDE Plasma (Wayland)"
echo "  ✓ Hyprland (Wayland)"
echo "  ✓ Catppuccin Mocha theme"
echo "  ✓ Kvantum Qt theming"
echo "  ✓ Papirus Dark icons"
echo "  ✓ Bibata Modern Ice cursor"
echo "  ✓ Inter and JetBrains Mono fonts"
echo "  ✓ Wayland stack (PipeWire, WirePlumber, xdg-desktop-portal)"
echo "  ✓ SDDM display manager"
echo "  ✓ Developer tools"
echo "  ✓ User applications"
echo ""
log_info "System structure:"
echo "  ✓ ~/.local/system directory created (ready for system-layer development)"
echo ""
log_warn "Important notes:"
echo "  • Logout and login (or reboot) to apply all changes"
echo "  • Docker group membership requires logout/login"
echo "  • Select 'Plasma (Wayland)' or 'Hyprland' session at login"
echo "  • Visual themes are configured - no hotkeys or workflows defined"
echo ""
log_info "The desktop environment is ready for immediate use and future development!"
echo "  • Reboot your system!"
