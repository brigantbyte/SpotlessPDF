# SpotlessPDF Rust engine

The macOS application bundles the precompiled `spotlesspdf_engine` executable. End users do not need Rust, Cargo, or a package manager.

For development, run `./script/rebuild_engine.sh` from the project root to rebuild and replace the bundled-source executable, then build the app normally.

Run `cargo test --manifest-path Rust/Cargo.toml --locked` for the eight self-contained regression tests. They create their own PDFs in memory or temporary folders and need no external fixtures.

The engine derives from the YM162 project referenced in `Cargo.toml`. Its declared GPL-3.0 license is included in `LICENSE`.
