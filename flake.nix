{
  description = "Example Darwin system flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin.url = "github:LnL7/nix-darwin";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    nixvim.url = "github:peterdanulf/nixvim";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs @ {
    self,
    nix-darwin,
    nixpkgs,
    nixvim,
    home-manager,
  }: let
    configuration = {pkgs, ...}: {
      # List packages installed in system profile. To search by name, run:
      # $ nix-env -qaP | grep wget
      environment.systemPackages = [
        pkgs.vim
        pkgs.neovide
        pkgs.gh
        pkgs.google-cloud-sdk
        pkgs.glow
        pkgs.zsh-powerlevel10k
        inputs.nixvim.packages.aarch64-darwin.default
        # Add Python with necessary packages
        (pkgs.python3.withPackages (ps:
          with ps; [
            rapidfuzz
            pandas
          ]))
        # Add Cargo for Rust
        pkgs.rustup
      ];

      homebrew = {
        enable = true;
        onActivation.autoUpdate = true;
        onActivation.cleanup = "uninstall";
        taps = [];
        brews = ["gnu-sed"];
        casks = ["bitwarden" "slack" "spotify" "wezterm" "arc" "sublime-text" "orbstack" "google-chrome" "chatgpt" "mimestream" "zed" "flutter" "android-studio" "tableplus" "transmit" "microsoft-teams" "ghostty" "poedit"];
      };

      # nix.package = pkgs.nix;

      # Necessary for using flakes on this system.
      nix.settings.experimental-features = "nix-command flakes";

      # Set home path.
      users.users.peterdanulf = {
        name = "peterdanulf";
        home = "/Users/peterdanulf";
      };

      # Create /etc/zshrc that loads the nix-darwin environment.
      programs.zsh = {
        enable = true;
        promptInit = "source ${pkgs.zsh-powerlevel10k}/share/zsh-powerlevel10k/powerlevel10k.zsh-theme";
      };

      system = {
        defaults = {
          # minimal dock
          dock = {
            autohide = true;
            orientation = "left";
            show-process-indicators = false;
            show-recents = false;
            static-only = true;
          };
          # a finder that tells me what I want to know and lets me work
          finder = {
            AppleShowAllExtensions = true;
            ShowPathbar = true;
            FXEnableExtensionChangeWarning = false;
          };
        };
        # Set Git commit hash for darwin-version.
        configurationRevision = self.rev or self.dirtyRev or null;

        # Used for backwards compatibility, please read the changelog before changing.
        # $ darwin-rebuild changelog
        stateVersion = 4;
      };

      # The platform the configuration will be used on.
      nixpkgs.hostPlatform = "aarch64-darwin";
    };
  in {
    # Build darwin flake using:
    # $ darwin-rebuild build --flake .#simple
    darwinConfigurations."simple" = nix-darwin.lib.darwinSystem {
      modules = [
        configuration
        home-manager.darwinModules.home-manager
        {
          home-manager = {
            useGlobalPkgs = true;
            useUserPackages = true;
            verbose = true;
            users.peterdanulf = import ./home.nix;
          };
        }
      ];
    };

    # Expose the package set, including overlays, for convenience.
    darwinPackages = self.darwinConfigurations."simple".pkgs;
  };
}
