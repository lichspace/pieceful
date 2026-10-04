#!/bin/bash
set -euo pipefail

platform="${1:-}"
case "$platform" in
  macos|ios) ;;
  *) echo "Usage: $0 {macos|ios} [output-directory]" >&2; exit 2 ;;
esac

project_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
output_dir="${2:-$project_root/dist}"
mkdir -p "$output_dir"
output_dir="$(cd "$output_dir" && pwd)"
build_dir="$project_root/.build/unsigned/$platform"

build_args=(
  -project "$project_root/ShiguangPuzzle.xcodeproj"
  -scheme ShiguangPuzzle
  -configuration Release
  -derivedDataPath "$build_dir"
  CODE_SIGNING_ALLOWED=NO
  CODE_SIGNING_REQUIRED=NO
  CODE_SIGN_IDENTITY=
  DEVELOPMENT_TEAM=
  ONLY_ACTIVE_ARCH=NO
)

if [[ "$platform" == macos ]]; then
  build_args+=(-destination 'generic/platform=macOS' 'ARCHS=arm64 x86_64')
  app_path="$build_dir/Build/Products/Release/ShiguangPuzzle.app"
  info_path="$app_path/Contents/Info.plist"
  executable_path="$app_path/Contents/MacOS/ShiguangPuzzle"
else
  build_args+=(-destination 'generic/platform=iOS' ARCHS=arm64)
  app_path="$build_dir/Build/Products/Release-iphoneos/ShiguangPuzzle.app"
  info_path="$app_path/Info.plist"
  executable_path="$app_path/ShiguangPuzzle"
fi

# Clean prevents an earlier signed build from leaking signatures into the package.
xcodebuild "${build_args[@]}" clean build 2>&1 | tee "$output_dir/$platform-build.log"
test -x "$executable_path"
test "$(/usr/libexec/PlistBuddy -c 'Print :CFBundleExecutable' "$info_path")" = ShiguangPuzzle
if [[ -d "$app_path/_CodeSignature" || -d "$app_path/Contents/_CodeSignature" || -f "$app_path/embedded.mobileprovision" ]]; then
  echo "Unexpected signing files in $app_path" >&2
  exit 1
fi

if [[ "$platform" == macos ]]; then
  lipo "$executable_path" -verify_arch arm64
  lipo "$executable_path" -verify_arch x86_64
  package="$output_dir/ShiguangPuzzle-macOS-unsigned.app.zip"
  ditto -c -k --sequesterRsrc --keepParent "$app_path" "$package"
else
  # A device IPA is a zip containing Payload/*.app. ExportArchive requires signing.
  staging_dir="$(mktemp -d "${TMPDIR:-/tmp}/pieceful-ipa.XXXXXX")"
  trap 'rm -rf "$staging_dir"' EXIT
  mkdir -p "$staging_dir/Payload"
  ditto "$app_path" "$staging_dir/Payload/ShiguangPuzzle.app"
  package="$output_dir/ShiguangPuzzle-iOS-unsigned.ipa"
  ditto -c -k --keepParent "$staging_dir/Payload" "$package"
fi

unzip -tq "$package"
(cd "$output_dir" && shasum -a 256 "$(basename "$package")" > "$(basename "$package").sha256")
echo "Unsigned package: $package"
