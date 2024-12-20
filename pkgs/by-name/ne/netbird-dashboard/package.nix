{
  lib,
  buildNpmPackage,
  fetchFromGitHub,
}:

buildNpmPackage rec {
  pname = "netbird-dashboard";
  version = "2.7.0";

  src = fetchFromGitHub {
    owner = "netbirdio";
    repo = "dashboard";
    rev = "v${version}";
    hash = "sha256-wvmwxWvRaSdDHe3cc22U1vLQGGONpjz2zR4vmvpThdo=";
  };

  npmDepsHash = "sha256-A8wzM8gYxYHIhPwxZeIWkNwHJ3skSD7MyNA5qWmX0q8=";
  npmFlags = [ "--legacy-peer-deps" ];

  installPhase = ''
    cp -R out $out
  '';

  env = {
    CYPRESS_INSTALL_BINARY = 0;
  };

  meta = with lib; {
    description = "NetBird Management Service Web UI Panel";
    homepage = "https://github.com/netbirdio/dashboard";
    license = licenses.bsd3;
    maintainers = with maintainers; [ vrifox ];
  };
}
