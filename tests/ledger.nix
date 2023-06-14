{ udev, ... }:

udev.internal.writeUdevFile "20-hw1.rules" {
  rules = with udev; {
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
}
