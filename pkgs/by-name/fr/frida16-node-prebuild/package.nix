{
  lib,
  stdenvNoCC,
  fetchurl,
}:

let
  version = "16.7.19";
  source =
    {
      aarch64-darwin = {
        url = "https://github.com/frida/frida/releases/download/${version}/frida-v${version}-napi-v8-darwin-arm64.tar.gz";
        hash = "sha256-KmDxDXGA6FxFhGY3SNvRriU/SJfXw6XkNOX6O0CtNpY=";
      };
      x86_64-darwin = {
        url = "https://github.com/frida/frida/releases/download/${version}/frida-v${version}-napi-v8-darwin-x64.tar.gz";
        hash = "sha256-bnRd2BLK7XJFZvL1aJFNQ/2eI5QrMaKD4o++1/XrE6c=";
      };
      aarch64-linux = {
        url = "https://github.com/frida/frida/releases/download/${version}/frida-v${version}-napi-v8-linux-arm64.tar.gz";
        hash = "sha256-OImdJ/VGEkPi63TVf08T8N+qo/qxYCofdnatiocMDCc=";
      };
      x86_64-linux = {
        url = "https://github.com/frida/frida/releases/download/${version}/frida-v${version}-napi-v8-linux-x64.tar.gz";
        hash = "sha256-5+dDsi/3lnyoV4kdwp2r3+/AbdhdUE4HByTDY1tJgok=";
      };
    }
    .${stdenvNoCC.hostPlatform.system}
      or (throw "Unsupported system: ${stdenvNoCC.hostPlatform.system}");
in
stdenvNoCC.mkDerivation {
  pname = "frida16-node-prebuild";
  inherit version;

  src = fetchurl {
    inherit (source) url hash;
  };

  dontUnpack = true;

  installPhase = ''
    runHook preInstall

    mkdir -p "$out"
    tar -xzf "$src" -C "$out"

    runHook postInstall
  '';

  meta = {
    description = "Prebuilt Frida v16 Node.js binding archive contents";
    homepage = "https://frida.re";
    changelog = "https://frida.re/news/";
    license = lib.licenses.wxWindowsException31;
    maintainers = with lib.maintainers; [ caverav ];
    platforms = [
      "aarch64-darwin"
      "x86_64-darwin"
      "aarch64-linux"
      "x86_64-linux"
    ];
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
  };
}
