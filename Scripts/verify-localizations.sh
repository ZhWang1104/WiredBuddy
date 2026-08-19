#!/bin/zsh
set -euo pipefail

repository_dir=${0:A:h:h}
locales_dir="$repository_dir/Wired Buddy/Locales"
supported_locales=(en de zh-Hans)
reference_keys=$(mktemp)

extract_keys() {
  sed -nE 's/^"([^"]+)"[[:space:]]*=.*/\1/p' "$1" | sort
}

for locale in $supported_locales; do
  strings_file="$locales_dir/$locale.lproj/Localizable.strings"
  plutil -lint "$strings_file" >/dev/null

  locale_keys=$(mktemp)
  extract_keys "$strings_file" > "$locale_keys"

  if [[ "$locale" == "en" ]]; then
    cp "$locale_keys" "$reference_keys"
  elif ! diff -u "$reference_keys" "$locale_keys"; then
    print -u2 "Localization keys differ for $locale"
    exit 1
  fi
done

print "All localization checks passed (${supported_locales[*]})"
