{
  config,
  pkgs,
  ...
}: {
  # Home Manager needs a bit of information about you and the paths it should
  # manage.
  home.username = "peterdanulf";
  home.homeDirectory = "/Users/peterdanulf";

  # This value determines the Home Manager release that your configuration is
  # compatible with. This helps avoid breakage when a new Home Manager release
  # introduces backwards incompatible changes.
  #
  # You should not change this value, even if you update Home Manager. If you do
  # want to update the value, then make sure to first check the Home Manager
  # release notes.
  home.stateVersion = "23.11"; # Please read the comment before changing.

  # The home.packages option allows you to install Nix packages into your
  # environment.
  home.packages = [
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
    pkgs.glow
    # Add Python with necessary packages
    (pkgs.python3.withPackages (ps:
      with ps; [
        rapidfuzz
        pandas
      ]))
    
    pkgs.zsh-powerlevel10k
    pkgs.gnused
    pkgs.cocoapods
    pkgs.nodejs_20
    pkgs.bun
    (pkgs.lib.hiPrio pkgs.claude-code)
    pkgs.ripgrep
    pkgs.ast-grep
    pkgs.lazygit
    pkgs.bat
    pkgs.fd
    pkgs.bottom
    pkgs.eza
    pkgs.zoxide
    pkgs.mkcert
    pkgs.firebase-tools
    pkgs.ruby_3_3
    pkgs.wget
    pkgs.fzf
    pkgs.neovim
    # Rust toolchain with all components
    (pkgs.rust-bin.stable.latest.default.override {
      extensions = [ "rust-src" "rust-analyzer" ];
    })
    pkgs.mysql-client
    pkgs.supabase-cli

    # PHP
    pkgs.php
    
    # Go
    pkgs.go
    pkgs.gopls
    pkgs.gofumpt
    pkgs.golangci-lint
    #
    pkgs.flutter
  ];

  programs = {
    zsh = {
      enable = true;
      enableCompletion = true;
      syntaxHighlighting = {
        enable = true;
      };
      autosuggestion = {
        enable = true;
      };
      initExtraFirst = ''
        source ${pkgs.zsh-powerlevel10k}/share/zsh-powerlevel10k/powerlevel10k.zsh-theme
        source ~/.p10k.zsh
        
        # Override p10k context format for SSH highlighting
        typeset -g POWERLEVEL9K_CONTEXT_TEMPLATE="%F{lightgreen}🔒 %n@%m%f"
        typeset -g POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS=(context time)
      '';
      initExtra = ''
        export PATH="$PATH":"$HOME/.pub-cache/bin"
        eval "$(zoxide init zsh)"
      '';
      shellAliases = {
        v = "nvim";
        ls = "eza";
        cd = "z";
        cat = "bat";
        find = "fd";
        switch = "sudo nix run nix-darwin -- switch --flake ~/.config/nix/.#simple";
        update = "(cd ~/.config/nix && nix flake update)";
      };
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
        }
      '';
    };
  };

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
  home.file = {
    ".anthropic_key" = {
      source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.anthropic_key";
    };
    # gh repo clone peterdanulf/dotfiles ~/dotfiles
    ".config/nvim" = {
      source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/dotfiles/nvim";
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
  home.sessionVariables = {
    EDITOR = "nvim";
    # Load API key from the .anthropic_key file
    ANTHROPIC_API_KEY = ''$(cat ${config.home.homeDirectory}/.anthropic_key)'';
  };

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
}
