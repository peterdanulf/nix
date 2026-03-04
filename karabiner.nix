{
  config,
  pkgs,
  ...
}: {
  home.file.".config/karabiner/karabiner.json" = {
    text = builtins.toJSON {
      global = {
        ask_for_confirmation_before_quitting = true;
        check_for_updates_on_startup = true;
        show_in_menu_bar = true;
        show_profile_name_in_menu_bar = false;
        unsafe_ui = false;
      };
      profiles = [
        {
          name = "Default profile";
          selected = true;
          complex_modifications = {
            rules = [
              {
                description = "Alt+Shift+S to Shift+Cmd+Ctrl+4 (screenshot selection to clipboard)";
                manipulators = [
                  {
                    type = "basic";
                    from = {
                      key_code = "s";
                      modifiers = {
                        mandatory = [ "option" "shift" ];
                      };
                    };
                    to = [
                      {
                        key_code = "4";
                        modifiers = [ "shift" "command" "control" ];
                      }
                    ];
                  }
                ];
              }
            ];
          };
          virtual_hid_keyboard = {
            keyboard_type_v2 = "ansi";
          };
        }
      ];
    };
  };
}
