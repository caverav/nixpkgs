{
  lib,
  buildNpmPackage,
  fetchFromGitHub,
  npm-lockfile-fix,
  bun,
  frida-node-prebuild,
  frida16-node-prebuild,
  nodejs_22,
  stdenv,
}:

buildNpmPackage {
  pname = "igf";
  version = "0.20.0-unstable-2026-02-10";

  src = fetchFromGitHub {
    owner = "ChiChou";
    repo = "Grapefruit";
    # npm publishes 0.13.1, while upstream main has the current 0.20.x codebase.
    rev = "acc0506eb6f1b477564816eeef2781462fedb437";
    hash = "sha256-5prjcojnz4NGh1CVtsihQfOm5emONnJufLWfFLtOqwg=";
    postFetch = ''
      ${lib.getExe npm-lockfile-fix} $out/package-lock.json
    '';
  };

  npmDepsHash = "sha256-e4Lyet3zrvKOoXuzJ2AA0Xk94w1yKK/XixTwa6P6ZQ8=";

  nodejs = nodejs_22;

  # Build with npm/node because upstream provides an npm-oriented build script
  # (`build:npm`), but runtime uses Bun APIs in the produced CLI entrypoint.
  npmBuildScript = "build:npm";
  npmFlags = [ "--ignore-scripts" ];
  dontNpmInstall = true;
  # We prune manually to pass --ignore-scripts, avoiding Bun-driven install hooks.
  dontNpmPrune = true;

  postPatch = ''
    # Upstream resolves migrations via ../../drizzle from dist/, but we install
    # drizzle beside dist/ under $out/lib/node_modules/igf/drizzle.
    substituteInPlace src/lib/store.ts \
      --replace-fail 'path.join(import.meta.dirname, "..", "..", "drizzle")' 'path.join(import.meta.dirname, "..", "drizzle")'
  '';

  installPhase = ''
    runHook preInstall

    npm prune --omit=dev --no-save --ignore-scripts
    find node_modules -maxdepth 1 -type d -empty -delete

    packageOut="$out/lib/node_modules/igf"
    mkdir -p "$packageOut"

    cp -r dist "$packageOut/"
    cp -r bin "$packageOut/"
    cp -r drizzle "$packageOut/"
    cp package.json "$packageOut/"
    cp -r node_modules "$packageOut/"

    # igf supports --frida 16 and --frida 17 at runtime by selecting either
    # `frida16` or `frida` bindings dynamically.
    cp ${frida-node-prebuild}/build/frida_binding.node "$packageOut/node_modules/frida/build/frida_binding.node"
    cp ${frida16-node-prebuild}/build/frida_binding.node "$packageOut/node_modules/frida16/build/frida_binding.node"

    mkdir -p "$out/bin"
    echo '#!${stdenv.shell}' > "$out/bin/igf"
    echo 'exec ${lib.getExe bun} '"\"$packageOut/dist/index.mjs\"" ' "$@"' >> "$out/bin/igf"
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
    platforms = [
      "aarch64-darwin"
      "x86_64-darwin"
      "aarch64-linux"
      "x86_64-linux"
    ];
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
  };
}
