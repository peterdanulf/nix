{
  description = "Example Darwin system flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin.url = "github:LnL7/nix-darwin";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    rust-overlay.url = "github:oxalica/rust-overlay";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs @ {
    self,
    nix-darwin,
    nixpkgs,
    rust-overlay,
    home-manager,
  }: let
    configuration = {pkgs, ...}: {
      # List packages installed in system profile. To search by name, run:
      # $ nix-env -qaP | grep wget
      # Install packages from nixpkgs
      environment.systemPackages = with pkgs; [
        google-cloud-sdk
        dnsmasq
      ];

      homebrew = {
        enable = true;
        onActivation.autoUpdate = true;
        onActivation.cleanup = "uninstall";
        taps = [];
        brews = ["gnu-sed"];
        casks = ["bitwarden" "slack" "spotify" "wezterm" "arc" "sublime-text" "orbstack" "google-chrome" "chatgpt" "mimestream" "zed" "android-studio" "tableplus" "transmit" "microsoft-teams" "ghostty" "poedit" "flutter" "claude"];
      };

      # Configure dnsmasq using launchd
      # Note: Update tailscaleIP when your Tailscale IP changes
      launchd.daemons.dnsmasq = let
        tailscaleIP = "100.92.156.113";  # Mac Mini's Tailscale IP
      in {
        path = [ pkgs.dnsmasq ];
        serviceConfig = {
          ProgramArguments = [
            "${pkgs.dnsmasq}/bin/dnsmasq"
            "--keep-in-foreground"
            "--port=53"
            "--no-daemon"
            "--no-hosts"
            "--listen-address=0.0.0.0"
            "--server=100.100.100.100"  # Tailscale DNS
            "--server=8.8.8.8"  # Google DNS fallback
            "--cache-size=1000"
            "--address=/skippo.test/${tailscaleIP}"
            "--address=/www.skippo.test/${tailscaleIP}"
            "--address=/cms.skippo.test/${tailscaleIP}"
          ];
          RunAtLoad = true;
          KeepAlive = true;
          UserName = "root";
        };
      };

      # Create /etc/resolver/test for .test domains
      # Note: This requires sudo permissions and will be created on activation
      system.activationScripts.postActivation.text = ''
        echo "Setting up dnsmasq resolver for .test domains..."
        if [ ! -d /etc/resolver ]; then
          echo "Creating /etc/resolver directory (requires sudo)..."
          sudo mkdir -p /etc/resolver
        fi
        echo "nameserver 127.0.0.1" | sudo tee /etc/resolver/test > /dev/null
      '';

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
      };

      system = {
        primaryUser = "peterdanulf";
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
      
      # Allow unfree packages
      nixpkgs.config.allowUnfree = true;
    };
  in {
    # Build darwin flake using:
    # $ darwin-rebuild build --flake .#simple
    darwinConfigurations."simple" = nix-darwin.lib.darwinSystem {
      modules = [
        ({ pkgs, ... }: {
          nixpkgs.overlays = [ rust-overlay.overlays.default ];
        })
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
