{ pkgs ?  import <nixpkgs> {}
, firmware ? import ../src {}
, pinned ? import ../src/nix/pinned-nixpkgs.nix {}
}:

let
  config = ./.;

  # Workaround for building ZMK Studio with MoErgo's Nix build: nanopb's
  # generator scripts use `#!/usr/bin/env python3`, and /usr/bin/env does not
  # exist in the Nix sandbox, so `generator/protoc` fails with "not found".
  # Point the shebangs at a Python that has the packages the generator needs.
  nanopbPython = pinned.python3.withPackages (ps: [ ps.protobuf ps.grpcio-tools ps.setuptools ]);
  origNanopb = firmware.zephyr.modules.nanopb;
  patchedNanopb = pinned.runCommand "zmk-module-nanopb-patched" {} ''
    mkdir -p $out
    cp -rL ${origNanopb.src} $out/nanopb
    chmod -R u+w $out/nanopb
    grep -rlI '^#!/usr/bin/env python3' $out/nanopb/generator | while read f; do
      sed -i '1s|^#!/usr/bin/env python3|#!${nanopbPython}/bin/python3|' "$f"
    done
  '' // {
    src = origNanopb.src;
    modulePath = "${patchedNanopb}/nanopb";
  };
  zephyr = firmware.zephyr // {
    modules = firmware.zephyr.modules // { nanopb = patchedNanopb; };
  };

  # ZMK Studio is enabled via CONFIG_ZMK_STUDIO in glove80.conf and is used over
  # Bluetooth. The studio-rpc-usb-uart snippet is deliberately NOT used: combined
  # with Studio it broke USB typing on the Glove80.
  glove80_left  = firmware.zmk.override { inherit zephyr; board = "glove80_lh"; keymap = "${config}/glove80.keymap"; kconfig = "${config}/glove80.conf"; };
  glove80_right = firmware.zmk.override { inherit zephyr; board = "glove80_rh"; keymap = "${config}/glove80.keymap"; kconfig = "${config}/glove80.conf"; };

in firmware.combine_uf2 glove80_left glove80_right
