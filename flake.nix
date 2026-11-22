
{
  description = "Fotufilm 1.17 for NixOS";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };

      pname = "fotufilm-bin";
      version = "1.17";

      src = pkgs.fetchurl {
        url = "https://github.com/DhaliwalX/fotufilm-engine/releases/download/v${version}/Fotufilm-Linux-x86_64.AppImage";
        hash = "sha256-CS3vnKEiKdYpWqy/F0jQ1IEdf1NqgN3UQBdaR2zT0Wk=";
      };

      contents = pkgs.appimageTools.extract {
        inherit pname version src;

        # Replace the incompatible bundled libcurl.
        postExtract = ''
          rm -f $out/usr/lib/fotufilm/lib/libcurl.so.4

          ln -s ${pkgs.curl.out}/lib/libcurl.so.4 \
            $out/usr/lib/fotufilm/lib/libcurl.so.4
        '';
      };

      fotufilm = pkgs.appimageTools.wrapAppImage {
        inherit pname version contents;

        extraPkgs = p: [
          p.libepoxy
          p.curl.out
          p.openssl
        ];

        
extraInstallCommands = ''
  set -e

  mkdir -p $out/bin

  for candidate in $out/bin/*; do
    [ -f "$candidate" ] || continue
    [ "$(basename "$candidate")" = "fotufilm-bin" ] && continue

    ln -s "$candidate" "$out/bin/fotufilm-bin"
    break
  done

  if [ ! -x "$out/bin/fotufilm-bin" ]; then
    echo "ERROR: Could not locate generated Fotufilm launcher"
    ls -la $out/bin
    exit 1
  fi
'';


        meta = {
          description = "Fotufilm desktop application";
          homepage = "https://github.com/DhaliwalX/fotufilm-engine";
          platforms = [ "x86_64-linux" ];
          mainProgram = "fotufilm-bin";
        };
      };

    in {
      packages.${system} = {
        fotufilm-bin = fotufilm;
        default = fotufilm;
      };

      apps.${system}.default = {
        type = "app";
        program = "${fotufilm}/bin/fotufilm-bin";
      };
    };
}
