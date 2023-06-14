{ pkgs, ... }:

# https://man.archlinux.org/man/udev.7
# http://www.reactivated.net/writing_udev_rules.html
let
  joinOperator = operator: value: "${operator}\"${valueFormat value}\"";
  valueFormat = value:
    if builtins.isString value then value
    else if builtins.isList value then builtins.concatStringsSep "|" value
    else builtins.throw "key value is not a string or list";
  operators = {
    match = joinOperator "==";
    exclude = joinOperator "!=";
    assign = joinOperator "=";
    add = joinOperator "+=";
    remove = joinOperator "-=";
    force = joinOperator ":=";
  };
  writeUdevRule = name: builtins.mapAttrs
    (key: value: {
      inherit key;
      value =
        if builtins.isString value then "${key}${value}"
        else if builtins.isAttrs value then
          builtins.concatStringsSep " "
            (builtins.map (value: "${key}${value}") (
              builtins.attrValues (builtins.mapAttrs (name: value: "{${name}}${value}") value)
            ))
        else if builtins.isList value then builtins.concatStringsSep " " (builtins.map (value: "${key}${value}") value)
        else builtins.throw "not a string, list or attrset, is: ${builtins.typeOf value}"
      ;
    });
  writeUdevRules = rules: builtins.attrValues (
    builtins.mapAttrs
      (name: value: {
        inherit name;
        value = builtins.concatStringsSep " " (builtins.catAttrs "value" (builtins.attrValues value));
      })
      (builtins.mapAttrs writeUdevRule rules)
  );
  writeUdevFile = name: { rules }: builtins.concatStringsSep "\n" (builtins.map
    ({ name, value }: ''
      # ${name}
      ${value}
    '')
    (writeUdevRules rules));
in
{
  internal = {
    inherit writeUdevRule writeUdevRules writeUdevFile;
  };
  inherit operators;
  mkUdevFile = name: attrs: pkgs.writeTextFile {
    inherit name;
    text = writeUdevFile name attrs;
  };
}
