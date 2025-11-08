# Nix Configuration Setup

## Prerequisites

Install Nix using the Determinate Systems graphical installer: <https://determinate.systems>

## Installation

1. Install homebrew and then GitHub command-line tool using brew.

2. Clone the dot files repository:

```bash
gh repo clone peterdanulf/dotfiles ~/dotfiles
```

2. Clone the nix files repository:

```bash
gh repo clone peterdanulf/nix ~/.config/nix
```

3. Apply the configuration:

```bash
sudo nix run nix-darwin -- switch --flake ~/.config/nix/.#simple
```

## Usage

After making changes to the configuration, rebuild with:

```bash
switch
```
