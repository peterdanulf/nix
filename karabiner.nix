{
  config,
  pkgs,
  ...
}: let
  # Dell U4323QE main input over DDC: USB-C 27, HDMI 1 17, HDMI 2 18
  monitorInput = pkgs.writeShellScript "monitor-input" ''
    m1ddc=${pkgs.m1ddc}/bin/m1ddc
    case "$1" in
      toggle)
        if [ "$($m1ddc get input)" = 27 ]; then $m1ddc set input 17; else $m1ddc set input 27; fi
        ;;
      hdmi2) $m1ddc set input 18 ;;
    esac
  '';
in {
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
              {
                description = "Middle mouse button: tap toggles monitor input USB-C/HDMI 1, hold 2s switches to HDMI 2";
                manipulators = [
                  {
                    type = "basic";
                    from = {
                      pointing_button = "button3";
                    };
                    to_if_alone = [
                      { shell_command = "${monitorInput} toggle"; }
                    ];
                    to_if_held_down = [
                      { shell_command = "${monitorInput} hdmi2"; }
                    ];
                    parameters = {
                      "basic.to_if_alone_timeout_milliseconds" = 2000;
                      "basic.to_if_held_down_threshold_milliseconds" = 2000;
                    };
                  }
                ];
              }
            ];
          };
          # Karabiner ignores mice by default; the middle-button rule needs this one grabbed
          devices = [
            {
              identifiers = {
                is_pointing_device = true;
                vendor_id = 1133; # Logitech USB Receiver
                product_id = 50504;
              };
              ignore = false;
            }
          ];
          virtual_hid_keyboard = {
            keyboard_type_v2 = "ansi";
          };
        }
      ];
    };
  };
}
