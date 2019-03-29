{ stdenv, pkgs, target-os ? "" }:

with pkgs;
with stdenv;

let
  gradle = gradle_4_10;
  status-go = callPackage ./status-go { inherit androidComposition; inherit xcodeWrapper; };
  targetAndroid = {
    "android" = true;
    "" = true;
  }.${target-os} or false;
  targetIOS = {
    "ios" = true;
    "" = true;
  }.${target-os} or false;
  xcodeWrapper = xcodeenv.composeXcodeWrapper {
    version = "10.1";
  };
  androidComposition = androidenv.composeAndroidPackages {
    toolsVersion = "26.1.1";
    platformToolsVersion = "28.0.2";
    buildToolsVersions = [ "28.0.3" ];
    includeEmulator = false;
    platformVersions = [ "26" "27" ];
    includeSources = false;
    includeDocs = false;
    includeSystemImages = false;
    systemImageTypes = [ "default" ];
    abiVersions = [ "armeabi-v7a" ];
    lldbVersions = [ "2.0.2558144" ];
    cmakeVersions = [ "3.6.4111459" ];
    includeNDK = true;
    ndkVersion = "19.2.5345600";
    useGoogleAPIs = false;
    useGoogleTVAddOns = false;
    includeExtras = [ "extras;android;m2repository" "extras;google;m2repository" ];
  };

in
  {
    buildInputs =
      [ status-go ] ++
      [ bundler ruby ] ++ ## bundler/ruby used for fastlane
      lib.optional targetAndroid [
        openjdk gradle
      ];
    shellHook =
      status-go.shellHook +
      ''
        export STATUS_GO_INCLUDEDIR=${status-go}/include
        export STATUS_GO_LIBDIR=${status-go}/lib
        export STATUS_GO_BINDIR=${status-go.bin}/bin
      '' +
      lib.optionalString targetIOS ''
        export RCTSTATUS_FILEPATH=${status-go}/lib/ios/Statusgo.framework
      '' +
      lib.optionalString targetAndroid ''
        export JAVA_HOME="${openjdk}"
        export ANDROID_HOME=~/.status/Android/Sdk
        export ANDROID_SDK_ROOT="$ANDROID_HOME"
        export ANDROID_NDK_ROOT="${androidComposition.ndk-bundle}/libexec/android-sdk/ndk-bundle"
        export ANDROID_NDK_HOME="$ANDROID_NDK_ROOT"
        export ANDROID_NDK="$ANDROID_NDK_ROOT"
        export PATH="$ANDROID_HOME/bin:$ANDROID_HOME/tools:$ANDROID_HOME/tools/bin:$ANDROID_HOME/platform-tools:$ANDROID_HOME/build-tools:$PATH"
      '';
  }
