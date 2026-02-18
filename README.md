# Albÿno OS

This is the home of my OS for ComputerCraft.

  - working "apt-get" with addable repos (the repos have a simple format)
  - file explorer based on FileX
  - very basic KDE-like desktop (think Windows)
  - configurable default programs
  - programs can register formats that they can open
  - a bunch of shell jargon that most people don't care about
  - basic multi-user login system
  - basic filesystem protection
  - auto-update (configurable)

## Installation

You can download the most recent version via (note that it needs the extension):

```bash
wget https://raw.githubusercontent.com/EtK2000/Alb-no-OS/master/installer/main.lua disk/startup.lua
```

Now just boot up a computer with the disk attached to start the installation.

## Repo setup

[Example Repo, hosted using GitHub](https://github.com/EtK2000/Alb-no-Repo).

## Working with the source

1. Download VSCode
2. Clone the repo:
```bash
git clone https://github.com/EtK2000/Alb-no-OS/
```
3. Download the CC type stubs:
```bash
git submodule add https://github.com/nvim-computercraft/lua-ls-cc-tweaked vendor/lua-ls-cc-tweaked
git submodule update --init --recursive
```
4. Download CraftOS 2 (https://github.com/MCJack123/craftos2)
