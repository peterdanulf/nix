{
  config,
  pkgs,
  ...
}: {
  imports = [
    ./nushell.nix
  ];

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  home = {
    # Home Manager needs a bit of information about you and the paths it should
    # manage.
    username = "peterdanulf";
    homeDirectory = "/Users/peterdanulf";

    # This value determines the Home Manager release that your configuration is
    # compatible with. This helps avoid breakage when a new Home Manager release
    # introduces backwards incompatible changes.
    #
    # You should not change this value, even if you update Home Manager. If you do
    # want to update the value, then make sure to first check the Home Manager
    # release notes.
    stateVersion = "23.11"; # Please read the comment before changing.

    # The home.packages option allows you to install Nix packages into your
    # environment.
    packages = [
    # # Adds the 'hello' command to your environment. It prints a friendly
    # # "Hello, world!" when run.
    # pkgs.hello

    # # It is sometimes useful to fine-tune packages, for example, by applying
    # # overrides. You can do that directly here, just don't forget the
    # # parentheses. Maybe you want to install Nerd Fonts with a limited number of
    # # fonts?
    # (pkgs.nerdfonts.override { fonts = [ "FantasqueSansMono" ]; })

    # # You can also create simple shell scripts directly inside your
    # # configuration. For example, this adds a command 'my-hello' to your
    # # environment:
    # (pkgs.writeShellScriptBin "my-hello" ''
    #   echo "Hello, ${config.home.username}!"
    # '')
    # Development tools moved from flake.nix
    pkgs.vim
    pkgs.gh
    pkgs.github-copilot-cli
    pkgs.glow
    # Add Python with necessary packages
    (pkgs.python3.withPackages (ps:
      with ps; [
        rapidfuzz
        pandas
        openai-whisper
      ]))

    pkgs.gnused
    pkgs.sd
    pkgs.cocoapods
    pkgs.nodejs_24
    pkgs.bun
    (pkgs.lib.hiPrio pkgs.claude-code)
    pkgs.ripgrep
    pkgs.ast-grep
    pkgs.lazygit
    pkgs.bat
    pkgs.fd
    pkgs.bottom
    pkgs.zoxide
    pkgs.mkcert
    pkgs.ruby_3_3
    pkgs.wget
    pkgs.fzf
    pkgs.neovim
    pkgs.sox
    pkgs.ngrok
    pkgs.yarn
    pkgs.bws
    pkgs.lazydocker
    pkgs.rustc
    pkgs.cargo
    pkgs.rust-analyzer
    pkgs.mariadb.client
    pkgs.supabase-cli
    pkgs.duf
    pkgs.dust
    pkgs.procs
    pkgs.tealdeer

    # PHP
    pkgs.php
    
    # Go
    pkgs.go
    pkgs.gopls
    pkgs.gofumpt
    pkgs.golangci-lint

    # Nix linter and formatter
    pkgs.statix
  ];

    # Home Manager is pretty good at managing dotfiles. The primary way to manage
    # plain files is through 'home.file'.
    # # Building this configuration will create a copy of 'dotfiles/screenrc' in
    # # the Nix store. Activating the configuration will then make '~/.screenrc' a
    # # symlink to the Nix store copy.
    # ".screenrc".source = dotfiles/screenrc;

    # # You can also set the file content immediately.
    # ".gradle/gradle.properties".text = ''
    #   org.gradle.console=verbose
    #   org.gradle.daemon.idletimeout=3600000
    # '';
    file = {
      # gh repo clone peterdanulf/dotfiles ~/dotfiles
      ".config/nvim" = {
        source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/dotfiles/nvim";
      };
      ".config/ghostty/config" = {
        text = ''
          font-family = Operator Mono Lig
          font-size = 16
          macos-option-as-alt = right
          command = ${pkgs.nushell}/bin/nu
        '';
      };
    };

    # Home Manager can also manage your environment variables through
    # 'home.sessionVariables'. If you don't want to manage your shell through Home
    # Manager then you have to manually source 'hm-session-vars.sh' located at
    # either
    #
    #  ~/.nix-profile/etc/profile.d/hm-session-vars.sh
    #
    # or
    #
    #  /etc/profiles/per-user/peterdanulf/etc/profile.d/hm-session-vars.sh
    #
    sessionVariables = {
      EDITOR = "nvim";
      TERM = "xterm-256color";
      # To add token: echo "your-token-here" > ~/.claude_oauth_token
      CLAUDE_CODE_OAUTH_TOKEN = ''$(cat ${config.home.homeDirectory}/.claude_oauth_token)'';
      BWS_ACCESS_TOKEN = ''$(cat ${config.home.homeDirectory}/.bws_access_token)'';
    };
  };

  programs = {
    fzf = {
      enable = true;
    };
    git = {
      enable = true;
      settings = {
        user.name = "Peter Danulf";
        user.email = "peter.danulf@gmail.com";
      };
    };
    ssh = {
      enable = true;
      enableDefaultConfig = false;
      matchBlocks = {
        "*" = {
          serverAliveInterval = 60;
          serverAliveCountMax = 120;
          extraOptions = {
            TCPKeepAlive = "yes";
            ForwardAgent = "no";
            Compression = "no";
            AddKeysToAgent = "no";
            HashKnownHosts = "no";
            UserKnownHostsFile = "~/.ssh/known_hosts";
            ControlMaster = "no";
            ControlPath = "~/.ssh/master-%r@%n:%p";
            ControlPersist = "no";
          };
        };
      };
      includes = [ "~/.orbstack/ssh/config" ];
    };
    wezterm = {
      enable = true;
      extraConfig = ''
        local wez = require('wezterm')
        return {
          font = wezterm.font("Operator Mono Lig", {weight="DemiLight", stretch="Normal", style="Normal"}),
          font_size = 16.0,
          hide_tab_bar_if_only_one_tab = true,
          send_composed_key_when_left_alt_is_pressed = true,
          send_composed_key_when_right_alt_is_pressed = false,
          color_scheme = "Tokyo Night",
          default_prog = { "${pkgs.nushell}/bin/nu" },
        }
      '';
    };
  };

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
}
