use lopdf::{dictionary, Document, Object, Stream};
use spotlesspdf_rs::try_clean_pdf;
use std::{fs, process::Command};

fn pdf(with_text: bool, page_count: usize) -> Vec<u8> {
    let mut doc = Document::with_version("1.5");
    let pages_id = doc.new_object_id();
    let font_id = doc.add_object(dictionary! {"Type" => "Font", "Subtype" => "Type1", "BaseFont" => "Helvetica"});
    let mut kids = Vec::new();
    for _ in 0..page_count {
        let mut page = dictionary! {"Type" => "Page", "Parent" => pages_id, "MediaBox" => vec![0.into(), 0.into(), 612.into(), 792.into()]};
        if with_text {
            let stream = doc.add_object(Stream::new(dictionary! {}, b"BT /F1 12 Tf 50 700 Td (Keep this text) Tj ET".to_vec()));
            page.set("Contents", stream);
            page.set("Resources", dictionary! {"Font" => dictionary! {"F1" => font_id}});
        }
        kids.push(Object::Reference(doc.add_object(page)));
    }
    doc.objects.insert(pages_id, dictionary! {"Type" => "Pages", "Kids" => kids, "Count" => page_count as i64}.into());
    let catalog = doc.add_object(dictionary! {"Type" => "Catalog", "Pages" => pages_id});
    doc.trailer.set("Root", catalog);
    let mut bytes = Vec::new();
    doc.save_to(&mut bytes).unwrap();
    bytes
}

#[test]
fn pages_without_resources_or_contents_are_preserved() {
    for force in [false, true] {
        let (bytes, _) = try_clean_pdf(pdf(false, 2), force).unwrap();
        let doc = Document::load_mem(&bytes).unwrap();
        assert_eq!(doc.get_pages().len(), 2);
        for id in doc.get_pages().values() {
            assert!(doc.get_page_content(*id).unwrap().is_empty());
        }
    }
}

#[test]
fn ordinary_text_is_preserved() {
    let (bytes, _) = try_clean_pdf(pdf(true, 2), false).unwrap();
    let doc = Document::load_mem(&bytes).unwrap();
    assert_eq!(doc.get_pages().len(), 2);
    assert_eq!(doc.extract_text(&[1, 2]).unwrap().matches("Keep this text").count(), 2);
}

#[test]
fn damaged_pdf_returns_error() {
    assert!(try_clean_pdf(b"not a PDF".to_vec(), false).is_err());
}

#[test]
fn cli_is_standalone_and_rejects_invalid_input_without_output() {
    let dir = std::env::temp_dir().join(format!("spotless-regression-{}", std::process::id()));
    fs::create_dir_all(&dir).unwrap();
    let input = dir.join("input.pdf");
    let output = dir.join("output.pdf");
    fs::write(&input, pdf(false, 1)).unwrap();
    let status = Command::new(env!("CARGO_BIN_EXE_spotlesspdf_engine"))
        .env_clear().args([&input, &output]).status().unwrap();
    assert!(status.success());
    assert_eq!(Document::load(&output).unwrap().get_pages().len(), 1);
    fs::remove_file(&output).unwrap();
    fs::write(&input, b"damaged PDF").unwrap();
    let result = Command::new(env!("CARGO_BIN_EXE_spotlesspdf_engine"))
        .env_clear().args([&input, &output]).output().unwrap();
    assert!(!result.status.success());
    assert!(!output.exists());
    let error = String::from_utf8_lossy(&result.stderr);
    assert!(error.contains("Unable to read PDF"));
    assert!(!error.contains("panicked"));
    fs::remove_dir_all(&dir).unwrap();
}

#[test]
fn wuolah_cleaning_preserves_annotation_only_solutions() {
    use spotlesspdf_rs::{clean::Cleaner, models::method::Method};
    let mut doc = Document::load_mem(&pdf(false, 3)).unwrap();
    let pages = doc.get_pages();
    let ink = doc.add_object(dictionary! {
        "Type" => "Annot", "Subtype" => "Ink",
        "Rect" => vec![10.into(), 10.into(), 200.into(), 200.into()],
        "InkList" => vec![Object::Array(vec![20.into(), 20.into(), 100.into(), 100.into()])],
        "Contents" => Object::string_literal("Handwritten solution")
    });
    let mut contents = Vec::new();
    let shared_a = doc.add_object(Stream::new(dictionary! {}, b"q\n".to_vec()));
    let shared_b = doc.add_object(Stream::new(dictionary! {}, b"Q\n".to_vec()));
    for id in pages.values().skip(1) {
        let mut streams = Vec::new();
        for _ in 0..2 { streams.push(doc.add_object(Stream::new(dictionary! {}, b"q\n".to_vec()))); }
        streams.push(shared_a);
        streams.push(doc.add_object(Stream::new(dictionary! {}, b"q Q\n".to_vec())));
        streams.push(shared_b);
        for _ in 0..3 { streams.push(doc.add_object(Stream::new(dictionary! {}, b"Q\n".to_vec()))); }
        let page = doc.get_object_mut(*id).unwrap().as_dict_mut().unwrap();
        page.set("Contents", streams.iter().copied().map(Object::Reference).collect::<Vec<_>>());
        page.set("Annots", vec![Object::Reference(ink)]);
        contents.push(streams);
    }
    Method::Wuolah(contents, vec![1]).clean(&mut doc);
    for id in pages.values().skip(1) {
        let annots = doc.get_object(*id).unwrap().as_dict().unwrap().get(b"Annots").unwrap().as_array().unwrap();
        assert_eq!(annots.len(), 1);
        assert_eq!(annots[0].as_reference().unwrap(), ink);
    }
}
