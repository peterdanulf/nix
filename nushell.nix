{ pkgs, ... }:
let
  zoxideInit = pkgs.runCommand "zoxide-init.nu" {} ''
    ${pkgs.zoxide}/bin/zoxide init nushell --cmd z > $out
  '';
in {
  programs.nushell = {
    enable = true;
    configFile.text = ''
      # Nushell Config File

      # Core config
      $env.config = {
        show_banner: false
        completions: {
          case_sensitive: false
          quick: true
          partial: true
          algorithm: "fuzzy"
        }
        history: {
          max_size: 10000
          sync_on_enter: true
          file_format: "plaintext"
        }
        cursor_shape: {
          emacs: line
          vi_insert: line
          vi_normal: block
        }
        table: {
          mode: rounded
          index_mode: always
          trim: {
            methodology: wrapping
            wrapping_try_keep_words: true
          }
        }
        datetime_format: {
          normal: '%a, %d %b %Y %H:%M:%S %z'
          table: '%m/%d/%y %I:%M:%S%p'
        }
      }

      # Oh My Posh will handle the prompt configuration

      # Aliases
      alias v = nvim
      alias cat = bat
      alias find = fd
      alias df = duf
      alias du = dust
      alias ps = procs

      # Nix aliases using functions instead of direct aliases to avoid startup evaluation
      def switch [] {
        cd ~/.config/nix
        sudo nix run nix-darwin -- switch --flake .#simple
      }

      def update [] {
        cd ~/.config/nix
        nix flake update
        cd -
      }

      # Initialize zoxide for nushell
      source ${zoxideInit}

      # Initialize atuin for better history (handles Ctrl+R)
      # Atuin will be initialized via the program configuration below
    '';
    envFile.text = ''
      # Nushell Environment Config File

      # Set PATH
      $env.PATH = ($env.PATH | split row (char esep))

      # Add common macOS paths
      $env.PATH = ($env.PATH | prepend "/usr/local/bin")
      $env.PATH = ($env.PATH | prepend "/opt/homebrew/bin")

      # Add Determinate Nix to PATH
      $env.PATH = ($env.PATH | prepend "/nix/var/nix/profiles/default/bin")
      $env.PATH = ($env.PATH | prepend $"($env.HOME)/.nix-profile/bin")

      # Add pub-cache to PATH
      $env.PATH = ($env.PATH | append $"($env.HOME)/.pub-cache/bin")

      # Add Flutter to PATH (find the latest version dynamically)
      let flutter_base = "/opt/homebrew/Caskroom/flutter"
      if ($flutter_base | path exists) {
          let versions = (ls $flutter_base | where type == dir | where name !~ ".metadata")
          if ($versions | length) > 0 {
              let latest = ($versions | sort-by name | last)
              $env.PATH = ($env.PATH | append $"($latest.name)/flutter/bin")
          }
      }

      # FZF configuration (for general FZF usage, not history)
      $env.FZF_DEFAULT_OPTS = "--height 40% --layout=reverse --border"
    '';
  };

  programs.oh-my-posh = {
    enable = true;
    enableNushellIntegration = true;
    useTheme = "tokyonight_storm";
  };

  programs.atuin = {
    enable = true;
    enableNushellIntegration = true;
    settings = {
      # Optional settings
      auto_sync = false;  # Set to true if you want to sync history
      update_check = false;
      style = "compact";
      inline_height = 10;
    };
  };
}