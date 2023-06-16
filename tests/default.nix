{ udev, pkgs, ... }:

let
  tests = with udev; {
    "usb-printer.rules" = {
      rules = {
        "Epson USB Printer" = {
          Subsystem = operators.match "usb";
          Attrs = {
            "serial" = operators.match "L72010011070626380";
          };
          Symlink = operators.add "epson_680";
        };
      };
      expect = ''
        # Epson USB Printer
        ATTRS{serial}==\"L72010011070626380\", SUBSYSTEM==\"usb\", SYMLINK+=\"epson_680\"
      '';
    };
    "usb-camera.rules" = {
      rules = {
        "Olympus USB Camera" = {
          Kernel = operators.match "sd?1";
          Subsystems = operators.match "scsi";
          Attrs = {
            "model" = operators.match "X250,D560Z,C350Z";
          };
          Symlink = operators.add "camera";
        };
      };
      expect = ''
        # Olympus USB Camera
        ATTRS{model}==\"X250,D560Z,C350Z\", KERNEL==\"sd?1\", SUBSYSTEMS==\"scsi\", SYMLINK+=\"camera\"
      '';
    };
    "usb-hard-disk.rules" = {
      rules = {
        "USB Storage" = {
          Kernel = operators.match "sd*";
          Subsystems = operators.match "scsi";
          Attrs = {
            "model" = operators.match "USB 2.0 Storage Device";
          };
          Symlink = operators.add "usbhd%n";
        };
      };
      expect = ''
        # USB Storage
        ATTRS{model}==\"USB 2.0 Storage Device\", KERNEL==\"sd*\", SUBSYSTEMS==\"scsi\", SYMLINK+=\"usbhd%n\"
      '';
    };
    "usb-card-reader.rules" = {
      rules = {
        "USB CompactFlash Reader" = {
          Kernel = operators.match "sd*";
          Subsystems = operators.match "scsi";
          Attrs = {
            "model" = operators.match "USB 2.0 CompactFlash Reader";
          };
          Symlink = operators.add "cfrdr%n";
          Options = operators.add "all_partitions";
        };
      };
      expect = ''
        # USB CompactFlash Reader
        ATTRS{model}==\"USB 2.0 CompactFlash Reader\", KERNEL==\"sd*\", OPTIONS+=\"all_partitions\", SUBSYSTEMS==\"scsi\", SYMLINK+=\"cfrdr%n\"
      '';
    };
    "usb-palm-pilot.rules" = {
      rules = {
        "Palm Pilot" = {
          Subsystems = operators.match "usb";
          Attrs = {
            "product" = operators.match "Palm Handheld";
          };
          Kernel = operators.match "ttyUSB*";
          Symlink = operators.add "pilot";
        };
      };
      expect = ''
        # Palm Pilot
        ATTRS{product}==\"Palm Handheld\", KERNEL==\"ttyUSB*\", SUBSYSTEMS==\"usb\", SYMLINK+=\"pilot\"
      '';
    };
    "cd-drives.rules" = {
      rules = {
        "DVD CDROM Group" = {
          Subsystem = operators.match "block";
          Kernel = operators.match "hdc";
          Symlink = operators.add "dvd";
          Group = operators.assign "cdrom";
        };
        "DVDRW CDROM Group" = {
          Subsystem = operators.match "block";
          Kernel = operators.match "hdc";
          Symlink = operators.add "dvdrw";
          Group = operators.assign "cdrom";
        };
      };
      expect = ''
        # DVD CDROM Group
        GROUP=\"cdrom\", KERNEL==\"hdc\", SUBSYSTEM==\"block\", SYMLINK+=\"dvd\"
        # DVDRW CDROM Group
        GROUP=\"cdrom\", KERNEL==\"hdc\", SUBSYSTEM==\"block\", SYMLINK+=\"dvdrw\"
      '';
    };
    "network-interface.rules" = {
      rules = {
        "LAN rename" = {
          Kernel = operators.match "eth*";
          Attr = {
            "address" = operators.match "00:52:8b:d5:04:48";
          };
          Name = operators.assign "lan";
        };
      };
      expect = ''
        # LAN rename
        ATTR{address}==\"00:52:8b:d5:04:48\", KERNEL==\"eth*\", NAME=\"lan\"
      '';
    };
  };
  mkTestUdevDerivation = name: drv: expect: pkgs.runCommand name
    {
      buildInputs = [ pkgs.diffutils ];
    } ''
    echo "${expect}" > ./expect.rule
    diff ${drv} ./expect.rule 2>&1 > $out || echo 'skip diff exit code'
    if [ -s $out ]; then
      echo '==== derivation ===='
      cat ${drv}
      echo '==== expect ===='
      cat ./expect.rule
      echo "derivation output !== expect";
      cat $out
      exit 1
    fi
  '';
in
builtins.mapAttrs
  (name: test: {
    inherit (test) expect drv;
    result = mkTestUdevDerivation name test.drv test.expect;
  })
  (builtins.mapAttrs
    (name: test: {
      inherit (test) expect;
      drv = udev.writeUdevFile name { inherit (test) rules; };
    })
    tests)
