# Arch Linux Setup Script

Описание
--------
Этот репозиторий содержит скрипт для быстрой настройки [Arch Linux](https://wiki.archlinux.org/title/Arch_Linux) с базовым и расширенным набором пакетов для:

- Разработки ([C](https://en.wikipedia.org/wiki/C_(programming_language)), [C++](https://en.wikipedia.org/wiki/C%2B%2B), [C#](https://learn.microsoft.com/en-us/dotnet/csharp/), [Go](https://golang.org/), [Python](https://www.python.org/), [Java](https://www.java.com/))
- вычислений и AI ([OpenBLAS](https://www.openblas.net/), [LAPACK](https://www.netlib.org/lapack/), [Eigen](https://eigen.tuxfamily.org/), [CUDA](https://developer.nvidia.com/cuda-toolkit))
- Контейнеризации ([Docker](https://docs.docker.com/), [Podman](https://podman.io/), [QEMU](https://www.qemu.org/))
- Мультимедиа и аудио/видео ([PipeWire](https://wiki.archlinux.org/title/PipeWire), [VLC](https://www.videolan.org/vlc/), [mpv](https://mpv.io/), [OBS](https://obsproject.com/))
- Рабочего стола ([KDE Plasma](https://wiki.archlinux.org/title/KDE), [Wayland](https://wiki.archlinux.org/title/Wayland), [Hyprland](https://wiki.hyprland.org/)) с [NVIDIA](https://wiki.archlinux.org/title/NVIDIA)

Скрипт автоматически устанавливает как официальные пакеты через [pacman](https://wiki.archlinux.org/title/Pacman), так и AUR-пакеты через [yay](https://aur.archlinux.org/packages/yay/).

---

## Файлы в репозитории

1. [packages.txt](packages.txt) — список пакетов для установки. Строки с `#` игнорируются как комментарии.
2. [install.sh](install.sh) — основной скрипт установки (v2):
   - разделяет пакеты на официальные и AUR
   - устанавливает pacman-пакеты
   - устанавливает yay при необходимости
   - устанавливает AUR-пакеты с флагами --devel и --removemake
   - логирует процесс в `install.log`
3. [README.md](README.md) — это руководство по использованию скрипта.

## Подготовка к использованию

1. Убедитесь, что у вас установлена свежая [Arch Linux](https://wiki.archlinux.org/title/Arch_Linux) и есть права sudo.

```bash
    sudo pacman -Syu
```

3. Убедитесь, что файлы install.sh и packages.txt находятся в одной папке.
4. Сделайте скрипт исполняемым:
```bash
   chmod +x install.sh
```
Использование
-------------
Запустите скрипт:
```bash
   ./install.sh
```
Скрипт автоматически:
1. Обновляет систему
2. Устанавливает официальные пакеты через [pacman](https://wiki.archlinux.org/title/Pacman)
3. Проверяет наличие [yay](https://aur.archlinux.org/packages/yay/) и устанавливает его при необходимости
4. Устанавливает AUR-пакеты через yay
5. Логирует весь процесс в `install.log`

Особенности
-----------
- Скрипт безопасен для повторного запуска — установленные пакеты пропускаются.
- AUR-пакеты устанавливаются с опциями:
```bash
  --needed    # не переустанавливать существующие пакеты
  --devel     # включить установку последних версий из разработки
  --removemake # удалять временные файлы сборки
```
- Вывод в терминале информативен:
```bash
  [SKIP]    # пакет уже установлен
  [INSTALL] # пакет устанавливается
```
- Все ошибки и полный вывод команд сохраняются в install.log.

Расширение
----------
- Для добавления новых пакетов просто допишите их в [packages.txt](packages.txt).
- Можно использовать комментарии через `#`.
- Скрипт автоматически распознает, какие пакеты из официального репозитория, а какие из AUR.

Советы
------
- Перед установкой большого количества пакетов убедитесь в стабильном интернет-соединении.
- Просматривать лог в реальном времени:
```bash
   tail -f install.log
```
- Для ускорения обновления AUR-пакетов в будущем:
```bash
   yay -Syu --devel
```

Полезные ссылки
---------------
- [Arch Wiki](https://wiki.archlinux.org/)         - [Pacman](https://wiki.archlinux.org/title/Pacman)         - [AUR](https://aur.archlinux.org/)         - [Yay](https://aur.archlinux.org/packages/yay/)
- [BTRFS](https://wiki.archlinux.org/title/Btrfs)         - [Wayland](https://wiki.archlinux.org/title/Wayland)         - [Hyprland](https://wiki.hyprland.org/)
- [PipeWire](https://wiki.archlinux.org/title/PipeWire)         - [NVIDIA drivers](https://wiki.archlinux.org/title/NVIDIA)
- [KDE Plasma](https://wiki.archlinux.org/title/KDE)         - [Docker](https://docs.docker.com/)         - [Podman](https://podman.io/)         - [QEMU](https://www.qemu.org/)
- [OpenBLAS](https://www.openblas.net/)         - [LAPACK](https://www.netlib.org/lapack/)         - [Eigen](https://eigen.tuxfamily.org/)
- [CUDA](https://developer.nvidia.com/cuda-toolkit)         - [VS Code](https://code.visualstudio.com/)         - [Neovim](https://neovim.io/)
