{ stdenv, buildGoPackage, go, pkgs, fetchFromGitHub, androidComposition, openjdk, xcodeWrapper }:

with stdenv;

let
   gomobile = pkgs.callPackage ./gomobile { inherit androidComposition xcodeWrapper; };
   version = lib.fileContents ../../../../../../STATUS_GO_VERSION; # TODO: Simplify this path search with lib.locateDominatingFile
   owner = "status-im";
   repo = "status-go";
   goPackagePath = "github.com/${owner}/${repo}";
   rev = version;
   sha256 = "10px992lyicyl7av3yh1b2c3j444dirfwi1i0mxyjg8v0gimn1jn";
   mobileTarget = if isDarwin then "ios" else "android";
   mobileOutputFileName = if isDarwin then "Statusgo.framework" else "status-go-${version}.aar";
   desktopOutputFileName = "libstatus.a";
   destopSystem = hostPlatform.system;
   removeReferences = [ go ];
   removeExpr = refs: ''remove-references-to ${lib.concatMapStrings (ref: " -t ${ref}") refs}'';
   goBuildFlags = "-v";
   goBuildLdFlags = "-ldflags=-s";

in buildGoPackage rec {
  inherit goPackagePath version rev;
  name = "${repo}-${version}";

  src = pkgs.fetchFromGitHub { inherit rev owner repo sha256; };

  nativeBuildInputs = [ gomobile openjdk ]
    ++ lib.optional isDarwin xcodeWrapper;

  # Fixes Cgo related build failures (see https://github.com/NixOS/nixpkgs/issues/25959 )
  hardeningDisable = [ "fortify" ];

  patchPhase = ''
    date=$(date -u '+%Y-%m-%d.%H:%M:%S')

    # gomobile doesn't seem to be able to pass -ldflags with multiple values correctly to go build, so we just patch files here  
    substituteInPlace cmd/statusd/main.go --replace \
      "buildStamp = \"N/A\"" \
      "buildStamp = \"$date\""
    substituteInPlace params/version.go --replace \
      "var Version string" \
      "var Version string = \"${version}\""
    substituteInPlace params/version.go --replace \
      "var GitCommit string" \
      "var GitCommit string = \"${rev}\""
    substituteInPlace vendor/github.com/ethereum/go-ethereum/metrics/metrics.go --replace \
      "var EnabledStr = \"false\"" \
      "var EnabledStr = \"true\""
  '';

  preConfigure = lib.optionalString isDarwin ''
    xcrun xcodebuild -version
  '';

  buildPhase = ''
    runHook preBuild

    runHook renameImports

    pushd "$NIX_BUILD_TOP/go/src/${goPackagePath}" >/dev/null

    # TODO: Build desktop libraries
    echo
    echo "Building desktop libraries"
    echo
    #GOOS=windows GOARCH=amd64 CGO_ENABLED=1 go build ${goBuildFlags} -buildmode=c-archive -o $out/${desktopOutputFileName} ./lib
    go build -o $out/${desktopOutputFileName} ${goBuildFlags} -buildmode=c-archive ${goBuildLdFlags} ./lib

    # Build command-line tools
    for name in ./cmd/*; do
      echo
      echo "Building $name"
      echo
  	  go install ${goBuildFlags} $name
    done

    popd >/dev/null

    # Build mobile libraries
    # TODO: Manage to pass -s -w to -ldflags. Seems to only accept a single flag
    echo
    echo "Building mobile library"
    echo
    ANDROID_HOME=${androidComposition.androidsdk}/libexec/android-sdk \
    ANDROID_NDK_HOME="${androidComposition.ndk-bundle}/libexec/android-sdk/ndk-bundle" \
    GOPATH=${gomobile.dev}:$GOPATH \
    PATH=${lib.makeBinPath [ gomobile.bin openjdk ]}:$PATH \
    gomobile bind ${goBuildFlags} -target=${mobileTarget} -iosversion=8.0 \
      -o ${mobileOutputFileName} \
      ${goBuildLdFlags} \
      ${goPackagePath}/mobile

    runHook postBuild
  '';


  postInstall = ''
    mkdir -p $bin
    cp -r "$NIX_BUILD_TOP/go/bin/" $bin

    mkdir -p $out/lib/${mobileTarget}
    mv ${mobileOutputFileName} $out/lib/${mobileTarget}/

    mkdir -p $out/lib/${destopSystem} $out/include
    mv $out/${desktopOutputFileName} $out/lib/${destopSystem}
    mv $out/libstatus.h $out/include
  '';

  preFixup = ''
    find $out -type f -exec ${removeExpr removeReferences} '{}' + || true
  '';

  outputs = [ "out" "bin" ];

  meta = {
    description = "The Status module that consumes go-ethereum.";
    license = lib.licenses.mpl20;
    maintainers = with lib.maintainers; [ pombeirp ];
    platforms = with lib.platforms; linux ++ darwin;
  };
}
