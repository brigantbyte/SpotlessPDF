/*!

 [![github]](https://github.com/YM162/gulagcleaner)

  [github]: https://img.shields.io/badge/github-8da0cb?style=for-the-badge&labelColor=555555&logo=github

 # SpotlessPDF crate in Rust
 SpotlessPDF is a tool designed to remove advertisements from PDFs, making it easier to read and navigate documents without being disrupted by unwanted ads.

 # Examples

    ```rust
    use spotlesspdf_rs::clean::clean_pdf;

    fn main(){
        let data = std::fs::read("example_docs/wuolah-free-example.pdf").unwrap();
        let (clean_pdf, _) = clean_pdf(data, false);
        //Stores the clean pdf in the out directory
        std::fs::write("example_docs/out/wuolah_clean.pdf", clean_pdf).unwrap();
    }
    ```
*/
/// Main method execution
pub mod clean;

/// Main method rexport
pub use clean::clean_pdf;

/// Modeling the different pdf sources and types
pub mod models {
    /// Represents the different methods used in the SpotlessPDF application.
    pub mod method;

    /// Represents the different page types used in the SpotlessPDF application.
    pub mod page_type;
}

#[cfg(test)]
pub mod tests;
