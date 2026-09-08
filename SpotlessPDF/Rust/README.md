# SpotlessPDF Rust engine

The macOS application bundles the precompiled `spotlesspdf_engine` executable. End users do not need Rust, Cargo, or a package manager.

For development, run `./script/rebuild_engine.sh` from the project root to rebuild and replace the bundled-source executable, then build the app normally. Run `~/.cargo/bin/cargo test --manifest-path Rust/Cargo.toml --locked` for the self-contained regression tests.

The original 14 fixture tests require external PDFs in `Rust/example_docs/` and are explicitly ignored by default. After supplying those fixtures, run Cargo tests with `-- --ignored`.
