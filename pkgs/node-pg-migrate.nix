{ lib, stdenv, fetchzip, makeWrapper, nodejs, pnpm_10, fetchPnpmDeps, pnpmConfigHook }:

let
  pnpm = pnpm_10;
in
stdenv.mkDerivation (finalAttrs: {
  pname = "node-pg-migrate";
  version = "8.0.4";

  src = fetchzip {
    url = "https://github.com/salsita/node-pg-migrate/archive/refs/tags/v${finalAttrs.version}.tar.gz";
    hash = "sha256-8cTSkFBCyZKDctM0KADIj+7R6WBBT1VxCsRIY4xCeiI=";
  };

  pnpmDeps = fetchPnpmDeps {
    inherit (finalAttrs) pname version src;
    fetcherVersion = 3;
    inherit pnpm;
    hash = "sha256-/Edt3hZCSibzTQYXawER9KTDakjc/xC92QHFkoqN32s=";
  };

  nativeBuildInputs = [ makeWrapper nodejs pnpm pnpmConfigHook ];

  buildPhase = "pnpm build";

  installPhase = ''
    runHook preInstall
    mkdir -p $out/lib/node-pg-migrate
    cp -r . $out/lib/node-pg-migrate/
    makeWrapper ${nodejs}/bin/node $out/bin/node-pg-migrate \
      --add-flags "$out/lib/node-pg-migrate/bin/node-pg-migrate.js"
    runHook postInstall
  '';

  meta = {
    description = "PostgreSQL database migration management tool for Node.js";
    homepage = "https://salsita.github.io/node-pg-migrate/";
    license = lib.licenses.mit;
    mainProgram = "node-pg-migrate";
  };
})
