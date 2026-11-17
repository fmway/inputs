set -eu

VERSION="@version@"
ASSET="droidloom-image-${VERSION}-$(uname -m).pkg.tar.zst"
BASE_URL="https://github.com/denialwm/droidloom/releases/download/packages"
API="https://api.github.com/repos/denialwm/droidloom/releases/tags/packages"
ARTIFACTS="/usr/lib/droidloom/artifacts"

if [ "$(id -u)" -ne 0 ]; then
  echo "droidloom-setup: must run as root (e.g. sudo droidloom-setup)" >&2
  exit 1
fi

mkdir -p "$ARTIFACTS"
staging="$(mktemp -d "$ARTIFACTS/.extract.XXXXXX")"
trap 'rm -rf "$staging"' EXIT HUP INT TERM

shadow="$staging/root"
mkdir -p "$shadow"

echo "droidloom-setup: resolving the digest of ${ASSET} from the GitHub API"
digest="$(curl -fsSL "$API" | jq -r --arg n "$ASSET" '.assets[] | select(.name == $n) | .digest // empty')"
if [ -n "$digest" ]; then
  expected="${digest#sha256:}"
elif [ -n "${DROIDLOOM_IMAGE_SHA256:-}" ]; then
  echo "droidloom-setup: asset has no digest in the API; using DROIDLOOM_IMAGE_SHA256" >&2
  expected="$DROIDLOOM_IMAGE_SHA256"
else
  echo "droidloom-setup: asset ${ASSET} has no digest in the GitHub API response." >&2
  echo "  Retry later, or set DROIDLOOM_IMAGE_SHA256 to a known sha256 hex digest." >&2
  exit 1
fi

download="$staging/payload.pkg.tar.zst"
echo "droidloom-setup: downloading ${ASSET}"
curl -fL --retry 3 --progress-bar -o "$download" "${BASE_URL}/${ASSET}"
echo "${expected}  ${download}" | sha256sum -c -

echo "droidloom-setup: unpacking into ${shadow}"
tar --use-compress-program=unzstd -x -C "$shadow" -f "$download"
src="$shadow/usr/lib/droidloom"
for part in runtime storage images; do
  if [ ! -d "$src/$part" ]; then
    echo "droidloom-setup: payload is missing ${part}/" >&2
    exit 1
  fi
done
rm -f "$src/current"

target="${ARTIFACTS}/${VERSION}"
rm -rf "$target"
mv "$src" "$target"
mkdir -p "$ARTIFACTS"
cd "$ARTIFACTS/.."
ln -sfn "artifacts/${VERSION}" ".current.$$"
mv -Tf ".current.$$" current

echo "droidloom-setup: installed ${VERSION} at $(realpath "$ARTIFACTS/..")"
echo "Next steps, as root:"
echo "  droidloom-package-helper setup --uid <uid>"
echo "  systemctl --user enable droidloom.service"
