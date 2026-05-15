#!/usr/bin/env bash
set -euo pipefail

skip_prebuild=0
for arg in "$@"; do
  case "$arg" in
    --skip-prebuild)
      skip_prebuild=1
      ;;
    *)
      echo "Unknown argument: $arg" >&2
      echo "Usage: build_macos.sh [--skip-prebuild]" >&2
      exit 2
      ;;
  esac
done

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "macOS packaging must run on macOS." >&2
  exit 1
fi

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "$script_dir/../.." && pwd)"
desktop_dir="$repo_root/apps/desktop"
web_static_validation_script="$repo_root/scripts/validate_web_static_assets.js"

python312="$(uv python find 3.12 | tr -d '\r')"
if [[ -z "$python312" ]]; then
  echo "No Python 3.12 interpreter was found via uv." >&2
  exit 1
fi

echo "Using Python 3.12: $python312"

icon_script="$repo_root/apps/desktop/build/generate_icon.py"
if [[ ! -f "$icon_script" ]]; then
  echo "Icon generator script was not found: $icon_script" >&2
  exit 1
fi

icon_python="$python312"
if ! "$icon_python" -c "from PIL import Image" >/dev/null 2>&1; then
  icon_venv_dir="$repo_root/build/icon-python"
  icon_python="$icon_venv_dir/bin/python"

  if [[ ! -x "$icon_python" ]]; then
    echo "Creating isolated Python environment for icon generation: $icon_venv_dir"
    "$python312" -m venv "$icon_venv_dir"
  fi

  if ! "$icon_python" -m pip --version >/dev/null 2>&1; then
    echo "pip is missing in the icon generation environment; bootstrapping with ensurepip..."
    "$icon_python" -m ensurepip --upgrade
  fi

  if ! "$icon_python" -c "from PIL import Image" >/dev/null 2>&1; then
    echo "Pillow is missing; installing Pillow into the isolated icon generation environment..."
    "$icon_python" -m pip install --disable-pip-version-check Pillow
  fi
fi

echo "Generating application icons..."
"$icon_python" "$icon_script"

pushd "$desktop_dir" >/dev/null
trap 'popd >/dev/null' EXIT

if [[ "$skip_prebuild" -eq 0 ]]; then
  npm run build:renderer
  "$python312" "$repo_root/packaging/pyinstaller/build_onedir.py"

  backend_executable="$repo_root/dist/BiliSum/BiliSum"
  if [[ ! -f "$backend_executable" ]]; then
    echo "Packaged backend was not produced: $backend_executable" >&2
    exit 1
  fi
  chmod +x "$backend_executable"
else
  echo "SkipPrebuild enabled: reusing existing renderer and backend artifacts."
fi

if [[ ! -f "$web_static_validation_script" ]]; then
  echo "Web static asset validation script was not found: $web_static_validation_script" >&2
  exit 1
fi

echo "Validating web static asset references..."
node "$web_static_validation_script"

npm run build:electron

export CSC_IDENTITY_AUTO_DISCOVERY=false
npx electron-builder --config electron-builder.config.js --mac dmg --publish=never
