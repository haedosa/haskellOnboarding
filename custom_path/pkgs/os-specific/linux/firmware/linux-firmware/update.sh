#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$(readlink -f "$0")")" || exit

# step 1: figure out the latest version from the tags
repo="https://git.kernel.org/pub/scm/linux/kernel/git/firmware/linux-firmware.git"
latestTag="$(git ls-remote --refs --tags --sort refname "$repo" | tail -n1 | cut -f2 | cut -d '/' -f3)"

# step 2: prefetch the source tarball
snapshotUrl="$repo/snapshot/linux-firmware-$latestTag.tar.gz"
hash="$(nix-prefetch-url --unpack "$snapshotUrl")"
sriHash="$(nix --experimental-features nix-command hash to-sri "sha256:$hash")"

# step 3: rebuild as a non-FO derivation to get the right hash
cat > source.nix << EOF
{
  version = "$latestTag";
  sourceHash = "$sriHash";
  outputHash = null;
}
EOF

outPath="$(nix --experimental-features "nix-command flakes" build ".#linux-firmware" --no-link --print-out-paths)"
outHash="$(nix --experimental-features nix-command hash path "$outPath")"

# step 4: generate the final file
cat > source.nix << EOF
# This file is autogenerated! Run ./update.sh to regenerate.
{
  version = "$latestTag";
  sourceHash = "$sriHash";
  outputHash = "$outHash";
}
EOF