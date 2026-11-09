# Tidy

**A calmer place for your files.**

Tidy is a native macOS file organizer. Choose a folder, review its suggested organization plan, and decide what to move. Tidy can group files by type or content, suggest clearer names for generic scans and downloads, and add matching Finder folder icons.

## What it does

- **Review before moving:** Scan builds a plan you can inspect. Skip individual files before you apply it.
- **Organize by type and content:** PDFs, text, images, and supported documents are analyzed locally to suggest useful categories such as invoices, school, travel, code, and photos. Other files are grouped by their file type.
- **Suggest clearer filenames:** Generic names such as `scan` or `download` can be replaced with a title inferred from the document.
- **Undo the last batch:** Tidy keeps a local move journal so you can restore the most recent organization batch.
- **Safer scanning:** Hidden files, symbolic links, app packages, system locations, and files changed in the last minute are skipped.
- **Local processing:** Tidy uses Apple’s PDFKit, Vision, and NaturalLanguage frameworks. It does not send file contents to a network service.

Tidy moves files only after you select a folder, review the proposed plan, and choose **Organize**. Its undo journal is stored under Application Support at `Tidy/journal.json`.

## Download

Get the latest **Tidy for macOS arm64** archive from [GitHub Releases](https://github.com/mhmdbilal1/tidy/releases/latest). Unzip it and move `Tidy.app` into `/Applications`.

This prototype build is ad hoc signed and not notarized. If Gatekeeper blocks the first launch, Control-click `Tidy.app` in Finder and choose **Open**. Tidy is sandboxed and asks you to select the folder it may organize.

## Build from source

### Requirements

- macOS 27 or later
- Xcode 27 or later
- Apple silicon Mac

From the repository root, run:

```sh
./scripts/build.sh
```

The script creates `build/Tidy.app` and `dist/Tidy-macOS-arm64.zip`.

## Project structure

```text
Tidy.xcodeproj/       Xcode project
Tidy/                 SwiftUI app, organizer, analysis helpers, and app icon
scripts/build.sh      Release build and packaging script
```

## License

No open-source license has been added. The project is not currently offered under an open-source license.
