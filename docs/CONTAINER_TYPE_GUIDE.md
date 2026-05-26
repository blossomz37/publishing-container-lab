# How To Identify What Kind Of Container A File Is

This guide is for figuring out what kind of package or container a software file might be before you try to unpack it.

The short version: changing the extension to `.zip` is sometimes a useful test, but it should be only one of several checks. File extensions are easy to fake, and many container formats are not ZIP at all.

## First Principle

Do not trust the file extension.

Use the file's actual bytes and internal structure to decide what it is.

## Fast Triage Checklist

1. Check the file type with `file`.
2. Inspect the first bytes with `xxd` or `hexdump`.
3. Try archive listing tools without renaming the file.
4. If it looks ZIP-like, test with `unzip -l` or `7z l`.
5. If it does not look ZIP-like, stop assuming it is an archive.

## Method 1: `file`

This is the quickest first pass on macOS and Linux.

```bash
file some-package.ext
```

What it tells you:

- Common archive types such as ZIP, tar, gzip, or PDF
- Plain data with no recognized signature
- Some structured formats with known magic numbers

What it does not tell you:

- Whether the file is internally a proprietary container
- Whether the file is encrypted or compressed in a custom way

## Method 2: Inspect The Magic Bytes

Read the first few bytes directly.

```bash
xxd -l 64 some-package.ext
```

Useful signatures:

- `50 4b 03 04` usually means ZIP
- `1f 8b` usually means gzip
- `25 50 44 46` usually means PDF
- `7f 45 4c 46` usually means ELF
- `00 00 01 00` can indicate ICO/CUR depending on context

If the header is not recognizable, the file may still be a valid proprietary package.

## Method 3: Try Listing As An Archive

If the file might be ZIP-like, try listing its contents without changing anything.

```bash
unzip -l some-package.ext
```

If that fails, try a broader archive tool:

```bash
7z l some-package.ext
```

Why this matters:

- Some package files are genuine ZIP archives with a different extension.
- Some are not ZIP at all, and the failure tells you not to treat them like one.

## Method 4: Test Common Archive Families

Different tools recognize different containers.

```bash
tar -tf some-package.ext
bsdtar -tf some-package.ext
```

Use these when the file might be a tarball, a compressed tarball, or another archive family.

## Method 5: Look For Embedded Structure

If the file is not a standard archive, search for recognizable strings.

```bash
strings -n 8 some-package.ext | sed -n '1,40p'
```

This can reveal:

- XML
- JSON
- EPUB paths like `META-INF/container.xml`
- Known file names or internal manifest paths

## Method 6: Look For Internal File Markers

Some containers are not obvious from the header but have recognizable embedded paths or metadata.

Examples:

- EPUB often contains `mimetype`, `META-INF/container.xml`, and `OEBPS/`
- Office files often contain `[Content_Types].xml` and `word/`, `ppt/`, or `xl/`
- Some app packages have their own manifest files or resource directories

## What To Do With A Suspected ZIP File

If `file` or the magic bytes suggest ZIP, test it directly before renaming it.

```bash
unzip -t some-package.ext
unzip -l some-package.ext
```

If those work, the file is probably ZIP-based even if the extension is unusual.

If they fail, renaming to `.zip` probably will not help.

## Safer Than Renaming The Extension

Renaming a file to `.zip` is not a real test. It only changes the label.

Better options:

1. Use `file`.
2. Use `xxd`.
3. Use `unzip -l` or `7z l`.
4. Use `strings` to find internal file paths.
5. Use the app itself, if the format is proprietary.

## How To Classify What You Find

### ZIP-like container

Likely if:

- The header starts with `PK`
- `unzip -l` works
- The file tree contains recognizable internal paths

### Tar-like container

Likely if:

- `tar -tf` or `bsdtar -tf` works
- The file may also be compressed with gzip, bzip2, or xz

### Proprietary package

Likely if:

- `file` says only `data`
- Archive tools fail
- The app that created the file can open it, but common shell tools cannot

Examples include many native app formats from graphics, publishing, or design tools.

### Plain binary document

Likely if:

- There is no archive structure at all
- The file is a single binary blob
- It may still contain embedded resources, but not as a normal folder tree

## A Practical Workflow You Can Reuse

```bash
file "some-package.ext"
xxd -l 64 "some-package.ext"
unzip -l "some-package.ext" 2>/dev/null || true
7z l "some-package.ext" 2>/dev/null || true
strings -n 8 "some-package.ext" | sed -n '1,40p'
```

Then decide:

- If it is archive-like, unpack it.
- If it is proprietary, look for app-specific export or packaging tools.
- If it is unknown, treat it as opaque until you have stronger evidence.

## Applied To The Files In This Workspace

- `sample.epub` is ZIP-based and unpackable with normal archive tools.
- `Winters-Magic-Kindle.epub` is also ZIP-based, but with a different EPUB layout.
- `sample-epub.af` is not ZIP-based and does not behave like a standard archive.

## Rule Of Thumb

The reliable sequence is:

1. Identify the magic bytes.
2. Test archive tools without renaming.
3. Inspect internal paths.
4. Only then decide whether the file is safely unpackable.

That approach is more dependable than renaming extensions and guessing.