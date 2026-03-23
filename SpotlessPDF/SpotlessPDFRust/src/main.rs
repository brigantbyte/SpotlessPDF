use std::env;
use std::fs;
use std::path::PathBuf;
use std::process;

fn main() {
    if let Err(message) = run() {
        eprintln!("{message}");
        process::exit(1);
    }
}

fn run() -> Result<(), String> {
    let mut args = env::args().skip(1);

    let input_path = args
        .next()
        .map(PathBuf::from)
        .ok_or_else(|| usage("Missing input PDF path"))?;
    let output_path = args
        .next()
        .map(PathBuf::from)
        .ok_or_else(|| usage("Missing output PDF path"))?;

    let force_naive = args.any(|arg| arg == "--force-naive");

    let data = fs::read(&input_path)
        .map_err(|error| format!("Failed to read {}: {error}", input_path.display()))?;
    let (cleaned_pdf, _) = spotlesspdf_rs::clean_pdf(data, force_naive);

    if let Some(parent) = output_path.parent() {
        fs::create_dir_all(parent)
            .map_err(|error| format!("Failed to create {}: {error}", parent.display()))?;
    }

    fs::write(&output_path, cleaned_pdf)
        .map_err(|error| format!("Failed to write {}: {error}", output_path.display()))?;

    Ok(())
}

fn usage(reason: &str) -> String {
    format!(
        "{reason}\nUsage: spotlesspdf_engine <input.pdf> <output.pdf> [--force-naive]"
    )
}
