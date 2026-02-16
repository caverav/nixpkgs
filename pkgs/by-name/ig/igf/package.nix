{
  lib,
  buildNpmPackage,
  fetchFromGitHub,
  fetchurl,
  npm-lockfile-fix,
  bun,
  nodejs_22,
  stdenv,
}:

let
  fridaPrebuilds = {
    aarch64-darwin = {
      frida = {
        url = "https://github.com/frida/frida/releases/download/17.6.2/frida-v17.6.2-napi-v8-darwin-arm64.tar.gz";
        hash = "sha256-47kQG90h/puHAr018ESk6dLgQPziWg7hheMQp2rL1MI=";
      };
      frida16 = {
        url = "https://github.com/frida/frida/releases/download/16.7.19/frida-v16.7.19-napi-v8-darwin-arm64.tar.gz";
        hash = "sha256-KmDxDXGA6FxFhGY3SNvRriU/SJfXw6XkNOX6O0CtNpY=";
      };
    };
    x86_64-darwin = {
      frida = {
        url = "https://github.com/frida/frida/releases/download/17.6.2/frida-v17.6.2-napi-v8-darwin-x64.tar.gz";
        hash = "sha256-JJkC1Pjzbp3TIUPr7Xytw2yd3qf9WVrZbm69WCbseTo=";
      };
      frida16 = {
        url = "https://github.com/frida/frida/releases/download/16.7.19/frida-v16.7.19-napi-v8-darwin-x64.tar.gz";
        hash = "sha256-bnRd2BLK7XJFZvL1aJFNQ/2eI5QrMaKD4o++1/XrE6c=";
      };
    };
    aarch64-linux = {
      frida = {
        url = "https://github.com/frida/frida/releases/download/17.6.2/frida-v17.6.2-napi-v8-linux-arm64.tar.gz";
        hash = "sha256-TChoxZGLDVhYQ05iZmP/WzP+SGVvrwQvBPYEkha/TrI=";
      };
      frida16 = {
        url = "https://github.com/frida/frida/releases/download/16.7.19/frida-v16.7.19-napi-v8-linux-arm64.tar.gz";
        hash = "sha256-OImdJ/VGEkPi63TVf08T8N+qo/qxYCofdnatiocMDCc=";
      };
    };
    x86_64-linux = {
      frida = {
        url = "https://github.com/frida/frida/releases/download/17.6.2/frida-v17.6.2-napi-v8-linux-x64.tar.gz";
        hash = "sha256-9rmXqwLGc+oIPh02ty4z8TytNUUAHvo5dVsRsxtAISI=";
      };
      frida16 = {
        url = "https://github.com/frida/frida/releases/download/16.7.19/frida-v16.7.19-napi-v8-linux-x64.tar.gz";
        hash = "sha256-5+dDsi/3lnyoV4kdwp2r3+/AbdhdUE4HByTDY1tJgok=";
      };
    };
  };

  prebuildsForSystem =
    fridaPrebuilds.${stdenv.hostPlatform.system}
      or (throw "Unsupported system ${stdenv.hostPlatform.system}");
in
buildNpmPackage {
  pname = "igf";
  version = "0.20.0-unstable-2026-02-10";

  src = fetchFromGitHub {
    owner = "ChiChou";
    repo = "Grapefruit";
    rev = "acc0506eb6f1b477564816eeef2781462fedb437";
    hash = "sha256-5prjcojnz4NGh1CVtsihQfOm5emONnJufLWfFLtOqwg=";
    postFetch = ''
      ${lib.getExe npm-lockfile-fix} $out/package-lock.json
    '';
  };

  npmDepsHash = "sha256-e4Lyet3zrvKOoXuzJ2AA0Xk94w1yKK/XixTwa6P6ZQ8=";

  nodejs = nodejs_22;

  npmBuildScript = "build:npm";
  npmFlags = [ "--ignore-scripts" ];
  dontNpmInstall = true;
  dontNpmPrune = true;

  installPhase = ''
    runHook preInstall

    npm prune --omit=dev --no-save --ignore-scripts
    find node_modules -maxdepth 1 -type d -empty -delete

    packageOut="$out/lib/node_modules/igf"
    mkdir -p "$packageOut"

    cp -r dist "$packageOut/"
    cp -r bin "$packageOut/"
    cp -r drizzle "$packageOut/"
    # dist/index.mjs resolves migrations from ../../drizzle
    cp -r drizzle "$out/lib/node_modules/drizzle"
    cp package.json "$packageOut/"
    cp -r node_modules "$packageOut/"

    tar -xzf ${fetchurl prebuildsForSystem.frida} -C "$packageOut/node_modules/frida"
    tar -xzf ${fetchurl prebuildsForSystem.frida16} -C "$packageOut/node_modules/frida16"

    mkdir -p "$out/bin"
    cat > "$out/bin/igf" <<EOF
    #!${stdenv.shell}
    exec ${lib.getExe bun} "$packageOut/dist/index.mjs" "\$@"
    EOF
    chmod +x "$out/bin/igf"

    nodejsInstallManuals "$packageOut/package.json"

    runHook postInstall
  '';

  doInstallCheck = true;
  installCheckPhase = ''
    runHook preInstallCheck
    $out/bin/igf --help >/dev/null
    runHook postInstallCheck
  '';

  meta = {
    description = "Runtime application instrumentation toolkit powered by Frida";
    homepage = "https://github.com/ChiChou/Grapefruit";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ caverav ];
    mainProgram = "igf";
    platforms = builtins.attrNames fridaPrebuilds;
  };
}
