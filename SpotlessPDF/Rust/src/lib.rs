/*!

 # SpotlessPDF crate in Rust
 SpotlessPDF is a tool designed to remove advertisements from PDFs, making it easier to read and navigate documents without being disrupted by unwanted ads.

 # Examples

    ```no_run
    use spotlesspdf_rs::clean::clean_pdf;

    fn main(){
        let data = std::fs::read("input.pdf").unwrap();
        let (clean_pdf, _) = clean_pdf(data, false);
        //Stores the clean pdf in the out directory
        std::fs::write("output.pdf", clean_pdf).unwrap();
    }
    ```
*/
/// Main method execution
pub mod clean;

/// Re-export the cleaning entry points
pub use clean::{clean_pdf, try_clean_pdf};

/// Modeling the different pdf sources and types
pub mod models {
    /// Represents the different methods used in the SpotlessPDF application.
    pub mod method;

    /// Represents the different page types used in the SpotlessPDF application.
    pub mod page_type;
}

