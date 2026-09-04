#!/usr/bin/env bash
# =============================================================================
# fsl-cli macOS installer builder — PER-USER, NO ADMIN.
#
# Produces: dist/fsl-cli-<version>-macos-<arch>.pkg
#
# Arch handling (PyInstaller reads FSLCLI_TARGET_ARCH from env — never pass
# --target-arch on the CLI, that is illegal when a .spec file is used):
#   - If the Python is universal2  → builds a UNIVERSAL binary (Intel + Apple Silicon)
#   - Otherwise                     → builds a native single-arch binary
#
# The .pkg installs to ~/.local/bin (home folder) so NO admin password is asked.
# Ollama + models are installed on first run.
# =============================================================================

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$REPO_ROOT"

VERSION=$(python3 -c "import fsl_cli; print(fsl_cli.__version__)")
APP_NAME="fsl-cli"
DIST="$REPO_ROOT/dist"
PKG_ROOT="$DIST/pkg_root"
PKG_SCRIPTS="$DIST/pkg_scripts"
INSTALL_DIR=".local/bin"
IDENTIFIER="com.firstsource.fsl-cli"

# ── Arch selection ────────────────────────────────────────────────────────
# We build NATIVE single-arch. Universal2 is avoided because compiled
# dependencies (pydantic_core, etc.) ship single-arch wheels, which makes
# a universal2 PyInstaller build fail ("not a fat binary").
#
# Native arm64 binaries run on Intel Macs via Rosetta 2, so a native build
# on an Apple Silicon runner covers effectively all modern Macs.
#
# To force universal later (needs universal2 wheels for ALL deps):
#   export FSLCLI_TARGET_ARCH=universal2 before running this script.
export FSLCLI_TARGET_ARCH="${FSLCLI_TARGET_ARCH:-native}"
if [ "$FSLCLI_TARGET_ARCH" = "universal2" ]; then
    ARCH_LABEL="universal"
else
    ARCH_LABEL="$(uname -m)"
fi
echo "▶  Target arch: $FSLCLI_TARGET_ARCH ($ARCH_LABEL)"

echo "▶  Building fsl-cli $VERSION for macOS ($ARCH_LABEL)"
echo ""

# ── 1. Clean ────────────────────────────────────────────────────────────
rm -rf build "$DIST/onefile" "$PKG_ROOT" "$PKG_SCRIPTS"
mkdir -p "$PKG_ROOT/$INSTALL_DIR" "$PKG_SCRIPTS"

# ── 2. Build the binary (arch chosen via FSLCLI_TARGET_ARCH env) ─────────
python3 -m PyInstaller fsl_cli.spec --distpath "$DIST/onefile" --workpath "build" --noconfirm

cp "$DIST/onefile/fsl-cli" "$PKG_ROOT/$INSTALL_DIR/fsl-cli"
chmod +x "$PKG_ROOT/$INSTALL_DIR/fsl-cli"
echo "   $(file "$PKG_ROOT/$INSTALL_DIR/fsl-cli")"

# ── 3. Postinstall (PATH setup, runs as the user) ─────────────────────────
cp "$REPO_ROOT/packaging/macos/scripts/postinstall" "$PKG_SCRIPTS/postinstall"
chmod +x "$PKG_SCRIPTS/postinstall"

# ── 4. Component pkg (installs into the user's home) ──────────────────────
echo "▶  Building component package…"
pkgbuild \
    --root       "$PKG_ROOT" \
    --scripts    "$PKG_SCRIPTS" \
    --identifier "$IDENTIFIER" \
    --version    "$VERSION" \
    --install-location "$HOME" \
    "$DIST/fsl-cli.pkg"

# ── 5. Distribution product pkg (welcome/license, per-user domain) ────────
FINAL_PKG="$DIST/${APP_NAME}-${VERSION}-macos-${ARCH_LABEL}.pkg"
RES="$REPO_ROOT/packaging/macos/resources"

if [ -f "$RES/distribution.xml" ]; then
    echo "▶  Building distribution installer…"
    productbuild \
        --distribution "$RES/distribution.xml" \
        --resources    "$RES" \
        --package-path "$DIST" \
        "$FINAL_PKG"
else
    cp "$DIST/fsl-cli.pkg" "$FINAL_PKG"
fi

rm -f "$DIST/fsl-cli.pkg"

echo ""
echo "✓  Installer ready:  $FINAL_PKG"
echo "   Install (NO admin needed): double-click the pkg, or:"
echo "     installer -pkg \"$FINAL_PKG\" -target CurrentUserHomeDirectory"
