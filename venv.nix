{ pkgs, lib, ... }:

let
  # Runtime libs commonly needed by manylinux Python wheels (numpy/pandas/etc.)
  nixPythonLibs = pkgs.lib.makeLibraryPath [
    pkgs.stdenv.cc.cc.lib  # libstdc++.so.6
    pkgs.zlib
    pkgs.openssl
    pkgs.curl
    pkgs.expat
    pkgs.icu
    pkgs.nss
  ];

  venvScript = pkgs.writeShellScriptBin "venv" ''
    set -euo pipefail

    usage() {
      cat <<'USAGE'
Usage:
  venv [PYVER] [DIR]
  venv --py PYVER [--dir DIR] [--recreate]
  venv -h | --help

Examples:
  venv                 # creates/activates .venv using default python
  venv 3.13            # creates/activates .venv using Python 3.13
  venv 3.12 myenv      # creates/activates ./myenv using Python 3.12
  venv --py 3.11 --dir venv --recreate

Options:
  --py, --python VER   Python version (3.10, 3.11, 3.12, 3.13)
  --dir DIR           Venv directory (default: .venv)
  --recreate          Delete and recreate the venv
  -h, --help          Show this help

Notes:
  - Injects Nix runtime libs into the venv so numpy/pandas wheels work on NixOS.
USAGE
    }

    # Defaults
    PYVER=""
    DIR=".venv"
    RECREATE=0

    # Parse args
    while [ "$#" -gt 0 ]; do
      case "$1" in
        -h|--help)
          usage
          exit 0
          ;;
        --py|--python)
          shift
          [ "$#" -gt 0 ] || { echo "error: --py requires a value"; exit 2; }
          PYVER="$1"
          shift
          ;;
        --dir)
          shift
          [ "$#" -gt 0 ] || { echo "error: --dir requires a value"; exit 2; }
          DIR="$1"
          shift
          ;;
        --recreate)
          RECREATE=1
          shift
          ;;
        3.*)
          if [ -z "$PYVER" ]; then
            PYVER="$1"
          else
            DIR="$1"
          fi
          shift
          ;;
        *)
          DIR="$1"
          shift
          ;;
      esac
    done

    # Pick interpreter
    PYBIN="python"
    if [ -n "$PYVER" ]; then
      case "$PYVER" in
        3.13) PYBIN="${pkgs.python313}/bin/python" ;;
        3.12) PYBIN="${pkgs.python312}/bin/python" ;;
        3.11) PYBIN="${pkgs.python311}/bin/python" ;;
        3.10) PYBIN="${pkgs.python310}/bin/python" ;;
        *)
          echo "error: unsupported PYVER '$PYVER' (supported: 3.10, 3.11, 3.12, 3.13)"
          exit 2
          ;;
      esac
    fi

    # Recreate if requested
    if [ "$RECREATE" -eq 1 ] && [ -d "$DIR" ]; then
      echo "Recreating $DIR..."
      rm -rf "$DIR"
    fi

    # Create if missing
    if [ ! -d "$DIR" ]; then
      "$PYBIN" -m venv "$DIR"
    fi

    ACTIVATE="$DIR/bin/activate"
    if [ ! -f "$ACTIVATE" ]; then
      echo "error: couldn't find activate script at $ACTIVATE"
      exit 1
    fi

    # Inject the Nix runtime libs into this venv (only once)
    if ! grep -q "NIX_PYTHON_LD_LIBRARY_PATH" "$ACTIVATE"; then
      cat >> "$ACTIVATE" <<EOF

# --- NixOS Python wheel fix (numpy/pandas/etc.) ---
export NIX_PYTHON_LD_LIBRARY_PATH="${nixPythonLibs}"
export LD_LIBRARY_PATH="\$NIX_PYTHON_LD_LIBRARY_PATH:\${LD_LIBRARY_PATH:-}"
# -----------------------------------------------
EOF
    fi

    # Activate and upgrade pip quietly
    . "$ACTIVATE"
    python -m pip install -U pip >/dev/null 2>&1 || true

    echo "✔ Activated $DIR $( [ -n "$PYVER" ] && echo "(Python $PYVER)" )"
  '';
in
{
  environment.systemPackages = [
    venvScript
    pkgs.python310
    pkgs.python311
    pkgs.python312
    pkgs.python313
  ];
}
