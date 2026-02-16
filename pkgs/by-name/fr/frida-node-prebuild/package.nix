{
  lib,
  stdenvNoCC,
  fetchurl,
}:

let
  version = "17.6.2";
  source =
    {
      aarch64-darwin = {
        url = "https://github.com/frida/frida/releases/download/${version}/frida-v${version}-napi-v8-darwin-arm64.tar.gz";
        hash = "sha256-47kQG90h/puHAr018ESk6dLgQPziWg7hheMQp2rL1MI=";
      };
      x86_64-darwin = {
        url = "https://github.com/frida/frida/releases/download/${version}/frida-v${version}-napi-v8-darwin-x64.tar.gz";
        hash = "sha256-JJkC1Pjzbp3TIUPr7Xytw2yd3qf9WVrZbm69WCbseTo=";
      };
      aarch64-linux = {
        url = "https://github.com/frida/frida/releases/download/${version}/frida-v${version}-napi-v8-linux-arm64.tar.gz";
        hash = "sha256-TChoxZGLDVhYQ05iZmP/WzP+SGVvrwQvBPYEkha/TrI=";
      };
      x86_64-linux = {
        url = "https://github.com/frida/frida/releases/download/${version}/frida-v${version}-napi-v8-linux-x64.tar.gz";
        hash = "sha256-9rmXqwLGc+oIPh02ty4z8TytNUUAHvo5dVsRsxtAISI=";
      };
    }
    .${stdenvNoCC.hostPlatform.system}
      or (throw "Unsupported system: ${stdenvNoCC.hostPlatform.system}");
in
stdenvNoCC.mkDerivation {
  pname = "frida-node-prebuild";
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
    description = "Prebuilt Frida Node.js binding archive contents";
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
