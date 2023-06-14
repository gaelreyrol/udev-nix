# udev-nix

[![CI](https://github.com/gaelreyrol/udev-nix/actions/workflows/ci.yml/badge.svg)](https://github.com/gaelreyrol/udev-nix/actions/workflows/ci.yml)

> A small utility library to create udev rules with Nix!

For now this is a pet project to improve my Nix knowledge, the API might change in the future.

Don't hesitate to submit changes that will help me to improve the code 🤗.

> **DO NOT USE IN PRODUCTION**

## Usage

### Flakes

Import the flake:

```nix
{
  inputs = {
    udev-nix.url = "github:gaelreyrol/udev-nix";
  }
}
```

Create an udev file:

```nix
{
  outputs = inputs@{ nixpkgs, udev-nix, ... }:
  let
    udevLib = udev-nix.lib."x86_64-linux";
  in
  {
    packages.x86_64-linux.myUdevFile = udevLib.mkUdevFile "20-test.rules" {
      rules = with udevLib; {
        "Description on my udev file" = {
          Subsystems = operators.match "usb";
          Tag = [
            (operators.add "uaccess")
          ];
        };
      };
    };
  };
}
```

It will produce this result:

```bash
$ cat /nix/store/pn8abdgzvafkywdpwzcn09hi0vw8np27-20-test.rules
# Description on my udev file
SUBSYSTEMS=="usb" TAG+="uaccess"
```
