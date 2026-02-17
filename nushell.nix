{ config, pkgs, ... }:
let
  zoxideInit = pkgs.runCommand "zoxide-init.nu" {} ''
    ${pkgs.zoxide}/bin/zoxide init nushell --cmd z > $out
  '';

  reviewsScript = pkgs.writeText "reviews.nu" ''
    # GitHub PR Review Dashboard
    # Shows PRs that need your review, with status indicators and clickable links
    def reviews [] {
      # Get current user and build search query
      let me = (gh api user | from json | get login)
      let search_query = "state:open review-requested:@me OR (review:changes_requested reviewed-by:@me)"

      # Fetch PRs and filter for those needing attention
      gh pr list --search $search_query --json number,title,author,assignees,reviews,reviewRequests,commits,createdAt,updatedAt,additions,deletions,url
      | from json
      | where {|pr|
          let my_reviews = ($pr.reviews | where author.login == $me)

          if ($my_reviews | is-empty) {
            # Case 1: Never reviewed - needs attention
            true
          } else {
            # Case 2: Requested changes and new commits added - needs re-review
            let last_changes = (
              $my_reviews
              | where state == "CHANGES_REQUESTED"
              | sort-by submittedAt
              | last
            )

            if ($last_changes | is-empty) {
              false
            } else {
              let last_commit = ($pr.commits | last | get committedDate)
              $last_commit > ($last_changes.submittedAt)
            }
          }
        }
      # Format assignees as initials
      | insert assignees_display {|pr|
          if ($pr.assignees | is-empty) {
            ""
          } else {
            ($pr.assignees | each {|a|
              $a.login | str upcase | split row "-" | each {|part|
                $part | str substring 0..0
              } | str join ""
            } | str join ", ")
          }
        }
      # Build reviewers list with status icons
      # Icons: ○ pending, ✓ approved, ✗ changes requested, ↻ re-review needed
      | insert reviewers_display {|pr|
          let non_copilot_reviews = ($pr.reviews | where author.login != "copilot-pull-request-reviewer")
          let requested_reviewers = ($pr.reviewRequests | each {|req| $req.login })
          let reviewed_logins = ($non_copilot_reviews | each {|rev| $rev.author.login })
          let assignee_logins = ($pr.assignees | each {|a| $a.login })
          let author_login = $pr.author.login

          # Include reviewers who are: requested, have reviewed, or are assignees who reviewed/were requested
          let all_reviewers = ($requested_reviewers | append $reviewed_logins | uniq | where {|login| $login != $author_login and $login != "copilot-pull-request-reviewer" and (($login not-in $assignee_logins) or ($login in $requested_reviewers) or ($login in $reviewed_logins)) })

          let review_states = ($all_reviewers | each {|login|
            let initials = ($login | str upcase | split row "-" | each {|part| $part | str substring 0..0 } | str join "")
            let user_reviews = ($non_copilot_reviews | where author.login == $login)
            let meaningful_reviews = ($user_reviews | where state == "APPROVED" or state == "CHANGES_REQUESTED")
            let in_review_requests = ($login in $requested_reviewers)

            # Determine icon based on review state
            let icon = if $in_review_requests {
              if ($meaningful_reviews | is-not-empty) {
                let latest_review = ($meaningful_reviews | sort-by submittedAt | last)
                if ($latest_review.state == "CHANGES_REQUESTED") { "↻" } else { "○" }
              } else {
                "○"
              }
            } else if ($meaningful_reviews | is-empty) {
              "○"
            } else {
              let latest_review = ($meaningful_reviews | sort-by submittedAt | last)
              if ($latest_review.state == "APPROVED") { "✓" } else if ($latest_review.state == "CHANGES_REQUESTED") { "✗" } else { "○" }
            }
            $"($initials) ($icon)"
          })
          $review_states | str join ", "
        }
      # Calculate last activity date
      | insert last_activity {|pr|
          let created = ($pr.createdAt | into datetime)
          let updated = ($pr.updatedAt | into datetime)
          if $updated > $created { $updated } else { $created }
        }
      # Format dates
      | insert created_fmt {|pr|
          $pr.createdAt | into datetime | format date "%Y-%m-%d"
        }
      | insert updated_fmt {|pr|
          $pr.updatedAt | into datetime | format date "%Y-%m-%d"
        }
      # Format lines of code changed
      | insert loc {|pr|
          $"+($pr.additions) -($pr.deletions)"
        }
      # Calculate sort priority: 1=re-reviews, 2=no reviews, 3=other
      | insert sort_order {|pr|
          let non_copilot_reviews = ($pr.reviews | where author.login != "copilot-pull-request-reviewer")
          let requested_reviewers = ($pr.reviewRequests | each {|req| $req.login })
          let reviewed_logins = ($non_copilot_reviews | each {|rev| $rev.author.login })
          let assignee_logins = ($pr.assignees | each {|a| $a.login })
          let author_login = $pr.author.login
          let all_reviewers = ($requested_reviewers | append $reviewed_logins | uniq | where {|login| $login != $author_login and $login != "copilot-pull-request-reviewer" and (($login not-in $assignee_logins) or ($login in $requested_reviewers) or ($login in $reviewed_logins)) })

          # Priority 1: Any reviewer has re-review pending after requesting changes
          let has_re_review = ($all_reviewers | any {|login| let user_reviews = ($non_copilot_reviews | where author.login == $login); let meaningful_reviews = ($user_reviews | where state == "APPROVED" or state == "CHANGES_REQUESTED"); let in_review_requests = ($login in $requested_reviewers); if $in_review_requests and ($meaningful_reviews | is-not-empty) { let latest_review = ($meaningful_reviews | sort-by submittedAt | last); $latest_review.state == "CHANGES_REQUESTED" } else { false } })

          # Priority 2: All reviewers have no meaningful reviews yet
          let all_no_reviews = ($all_reviewers | all {|login| let user_reviews = ($non_copilot_reviews | where author.login == $login); let meaningful_reviews = ($user_reviews | where state == "APPROVED" or state == "CHANGES_REQUESTED"); let in_review_requests = ($login in $requested_reviewers); not ($in_review_requests and ($meaningful_reviews | is-not-empty)) and ($meaningful_reviews | is-empty) })

          if $has_re_review {
            1
          } else if $all_no_reviews {
            2
          } else {
            3
          }
        }
      # Make all columns clickable with OSC 8 hyperlinks (Cmd+click to open PR)
      | insert pr_link {|pr| $"\e]8;;($pr.url)\e\\($pr.number)\e]8;;\e\\" }
      | insert assignee_link {|pr| $"\e]8;;($pr.url)\e\\($pr.assignees_display)\e]8;;\e\\" }
      | insert title_link {|pr| $"\e]8;;($pr.url)\e\\($pr.title)\e]8;;\e\\" }
      | insert reviews_link {|pr| $"\e]8;;($pr.url)\e\\($pr.reviewers_display)\e]8;;\e\\" }
      | insert loc_link {|pr| $"\e]8;;($pr.url)\e\\($pr.loc)\e]8;;\e\\" }
      | insert created_link {|pr| $"\e]8;;($pr.url)\e\\($pr.created_fmt)\e]8;;\e\\" }
      | insert updated_link {|pr| $"\e]8;;($pr.url)\e\\($pr.updated_fmt)\e]8;;\e\\" }
      # Sort by priority, then by last activity
      | sort-by last_activity --reverse
      | sort-by sort_order
      # Display final table
      | select pr_link assignee_link title_link reviews_link loc_link created_link updated_link
      | rename PR assignee title reviews loc created updated
      | table --index false
    }
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

      # PR review worktree helpers
      def --env pr-review [pr: int] {
        $env.PR_REVIEW_ORIGIN = (pwd)
        let branch = (gh pr view $pr --json headRefName -q .headRefName)
        git fetch origin $branch
        let dir = $"../review/pr-($pr)"
        if ($dir | path exists) {
          git worktree remove $dir --force
        }
        git worktree add $dir -b $"pr-($pr)" $"origin/($branch)"
        cd $dir

        # Run project-specific bootstrap if it exists (from origin dir)
        let bootstrap_script = ($env.PR_REVIEW_ORIGIN | path join "scripts/pr-bootstrap.sh")
        if ($bootstrap_script | path exists) {
          bash $bootstrap_script --non-interactive --origin $env.PR_REVIEW_ORIGIN $pr
        }
      }

      def --env pr-done [] {
        let dir = ($env.PWD | path basename)
        let branch = (git branch --show-current)

        # Run project-specific cleanup if it exists (from origin dir)
        let cleanup_script = ($env.PR_REVIEW_ORIGIN | path join "scripts/pr-cleanup.sh")
        if ($cleanup_script | path exists) {
          bash $cleanup_script
        }

        cd $env.PR_REVIEW_ORIGIN
        git worktree remove $"../review/($dir)"
        git branch -D $branch
      }

      # Load GitHub PR review dashboard
      source ${reviewsScript}

      # Initialize zoxide for nushell
      source ${zoxideInit}

      # Initialize atuin for better history (handles Ctrl+R)
      # Atuin will be initialized via the program configuration below
    '';
    envFile.text = ''
      # Nushell Environment Config File

      # Basic environment
      $env.EDITOR = "nvim"
      $env.TERM = "xterm-256color"

      # OpenSSL paths for cargo build
      $env.OPENSSL_DIR = "${pkgs.openssl.dev}"
      $env.OPENSSL_LIB_DIR = "${pkgs.openssl.out}/lib"
      $env.OPENSSL_INCLUDE_DIR = "${pkgs.openssl.dev}/include"
      $env.PKG_CONFIG_PATH = "${pkgs.openssl.dev}/lib/pkgconfig"

      # Load tokens if they exist
      if ("~/.claude_oauth_token" | path expand | path exists) {
          $env.CLAUDE_CODE_OAUTH_TOKEN = (open ~/.claude_oauth_token | str trim)
      }
      if ("~/.bws_access_token" | path expand | path exists) {
          $env.BWS_ACCESS_TOKEN = (open ~/.bws_access_token | str trim)
      }

      # Set PATH
      $env.PATH = ($env.PATH | split row (char esep))

      # Add common macOS paths
      $env.PATH = ($env.PATH | prepend "/usr/local/bin")
      $env.PATH = ($env.PATH | prepend "/opt/homebrew/bin")

      # Add PostgreSQL binaries to PATH
      $env.PATH = ($env.PATH | prepend "/opt/homebrew/opt/postgresql@18/bin")

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