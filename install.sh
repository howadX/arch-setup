#!/bin/bash
set -e

echo "==> Обновление системы"
sudo pacman -Syu --noconfirm

echo "==> Установка пакетов из pacman"
sudo pacman -S --needed --noconfirm $(grep -v '^#' packages.txt)

echo "==> Включение сервисов"
sudo systemctl enable NetworkManager
sudo systemctl enable docker
sudo systemctl enable sshd

echo "==> Добавление пользователя в группу docker"
sudo usermod -aG docker $USER

echo "==> Установка AUR пакетов"
yay -S --needed --noconfirm \
  visual-studio-code-bin \
  amnezia-vpn-bin \
  zen-browser-bin

echo "==> Готово!"
echo "Перезагрузи систему и Docker будет доступен без sudo."
