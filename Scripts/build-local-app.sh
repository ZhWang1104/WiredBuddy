#!/bin/zsh
set -euo pipefail

repository_dir=${0:A:h:h}
output_app=${1:-"$repository_dir/Wired Buddy-local.app"}

if [[ -e "$output_app" ]]; then
  print -u2 "Output already exists: $output_app"
  exit 1
fi

swift build \
  --package-path "$repository_dir" \
  --configuration release \
  --product WiredBuddyBuildCheck

staging_dir=$(mktemp -d "${TMPDIR:-/tmp}/wiredbuddy-app.XXXXXX")
app_dir="$staging_dir/Wired Buddy.app"
contents_dir="$app_dir/Contents"
resources_dir="$contents_dir/Resources"
iconset_dir="$staging_dir/AppIcon.iconset"

mkdir -p "$contents_dir/MacOS" "$iconset_dir"

install -m 755 \
  "$repository_dir/.build/release/WiredBuddyBuildCheck" \
  "$contents_dir/MacOS/Wired Buddy"
install -m 644 "$repository_dir/Packaging/Info.plist" "$contents_dir/Info.plist"
for localization in en de zh-Hans; do
  mkdir -p "$resources_dir/$localization.lproj"
  install -m 644 \
    "$repository_dir/Wired Buddy/Locales/$localization.lproj/Localizable.strings" \
    "$resources_dir/$localization.lproj/Localizable.strings"
done
install -m 644 \
  "$repository_dir/Resources/1024x1024px_hintergrund-128.png" \
  "$resources_dir/appicon128.png"

install -m 644 "$repository_dir/Resources/1024x1024px_hintergrund-16.png" "$iconset_dir/icon_16x16.png"
install -m 644 "$repository_dir/Resources/1024x1024px_hintergrund-32.png" "$iconset_dir/icon_16x16@2x.png"
install -m 644 "$repository_dir/Resources/1024x1024px_hintergrund-32.png" "$iconset_dir/icon_32x32.png"
install -m 644 "$repository_dir/Resources/1024x1024px_hintergrund-64.png" "$iconset_dir/icon_32x32@2x.png"
install -m 644 "$repository_dir/Resources/1024x1024px_hintergrund-128.png" "$iconset_dir/icon_128x128.png"
install -m 644 "$repository_dir/Resources/1024x1024px_hintergrund-256.png" "$iconset_dir/icon_128x128@2x.png"
install -m 644 "$repository_dir/Resources/1024x1024px_hintergrund-256.png" "$iconset_dir/icon_256x256.png"
install -m 644 "$repository_dir/Resources/1024x1024px_hintergrund-512.png" "$iconset_dir/icon_256x256@2x.png"
install -m 644 "$repository_dir/Resources/1024x1024px_hintergrund-512.png" "$iconset_dir/icon_512x512.png"
install -m 644 "$repository_dir/Resources/1024x1024px_hintergrund-1024.png" "$iconset_dir/icon_512x512@2x.png"

iconutil --convert icns "$iconset_dir" --output "$resources_dir/AppIcon.icns"

codesign \
  --force \
  --deep \
  --sign - \
  --options runtime \
  --entitlements "$repository_dir/Wired Buddy/Wired_Buddy.entitlements" \
  "$app_dir"
codesign --verify --deep --strict --verbose=2 "$app_dir"

ditto "$app_dir" "$output_app"
print "Built $output_app"
