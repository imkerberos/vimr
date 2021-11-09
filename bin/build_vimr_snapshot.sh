#!/bin/bash
set -Eeuo pipefail

readonly clean=${clean:?"true or false: when true, xcodebuild clean will be performed"}

main() {
  if [[ "${clean}" == true ]]; then
    local -r cmd="clean build"
  else
    local -r cmd="build"
  fi

  pushd "$(dirname "${BASH_SOURCE[0]}")/.." > /dev/null

  # Carthage often crashes => do it at the beginning.
  echo "### Updating carthage"
  carthage update --cache-builds --platform macos

  echo "### Xcodebuilding"
  xcodebuild \
      -workspace VimR.xcworkspace \
      -derivedDataPath ./build \
      -configuration Release \
      -scheme VimR \
      ${cmd}

  popd >/dev/null
}

main
