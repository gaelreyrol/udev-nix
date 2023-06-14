{ udev, ... }:

let
  files = {
    "20-hw1.rules" = with udev; {
      "HW.1 / Nano" = {
        Subsystems = operators.match "usb";
        Attrs = {
          "idVendor" = operators.match [ "2581" ];
          "idProduct" = operators.match [ "1b7c" "2b7c" "3b7c" "4b7c" ];
        };
        Tag = [
          (operators.add "uaccess")
          (operators.add "udev-acl")
        ];
      };
    };
    "61-gnome-settings-daemon-rfkill.rules" = with udev; {
      "Get access to /dev/rfkill for users" = {
        Kernel = operators.match "rfkill";
        Subsystem = operators.match "misc";
        Tag = operators.add "uaccess";
      };
    };
    "20-test.rules" = with udev; {
      "Description on my udev file" = {
        Subsystems = operators.match "usb";
        Tag = [
          (operators.add "uaccess")
        ];
      };
    };
  };
in
builtins.mapAttrs (name: rules: udev.mkUdevFile name { inherit rules; }) files
