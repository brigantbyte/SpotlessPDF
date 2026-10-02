#!/usr/bin/env bash
# Developer-only step. The distributed app contains this compiled executable.
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CARGO_BIN="${CARGO:-$HOME/.cargo/bin/cargo}"
if [[ ! -x "$CARGO_BIN" ]]; then
    CARGO_BIN="$(command -v cargo)"
fi
export MACOSX_DEPLOYMENT_TARGET=27.0
"$CARGO_BIN" build --manifest-path "$ROOT_DIR/Rust/Cargo.toml" --locked --release --bin spotlesspdf_engine
install -m 755 "$ROOT_DIR/Rust/target/release/spotlesspdf_engine" "$ROOT_DIR/spotlesspdf_engine"
