# Performance Analysis - Initialization Bottlenecks

## Current Initialization Flow

### 1. **Script Loading** (Blocking)
- Multiple large JavaScript libraries loaded synchronously:
  - `jquery-3.7.0.min.js` (~90KB)
  - `jquery.stylesheet-0.3.7.min.js`
  - `interact-1.3.4.min.js`
  - `mousetrap-1.6.2.min.js`
  - `marked-4.0.12.min.js`
  - `tiff-2016-11-01.min.js` (large)
  - `pdfjs-1.8.579.min.js` (very large, ~500KB+)
  - `pdfjs-1.8.579.worker.min.js` (large)
  - `turf-5.1.6.min.js` (large)
  - `xmllint.js` (large)
  - `svg-canvas.js`
  - `page-canvas.js`
  - `page-editor.js`
  - `nw-app.js`
  - `nw-winstate.js`

**Impact:** All scripts must load and parse before DOM is ready.

### 2. **XSLT Loading** (Async but Sequential)
During `PageCanvas` initialization:
- **5 Import XSLT files** loaded asynchronously:
  - `page2svg.xslt`
  - `page_from_2010-03-19.xslt`
  - `page2page.xslt`
  - `alto_v2_to_page.xslt`
  - `alto_v3_to_page.xslt`
- **3 Export XSLT files** loaded asynchronously:
  - `svg2page.xslt`
  - `sortattr.xslt`
  - `page_fix_xsd_sequence.xslt`

**Impact:** 8 XSLT files must be fetched and parsed. Each requires:
- HTTP request
- XML parsing
- XSLTProcessor creation
- Stylesheet import

### 3. **XSD Loading** (Complex Fallback Chain)
The XSD loading has a 3-step fallback mechanism:
1. Try to load `../xsd/pagecontent_omnius.xsd` as XML
2. If fails, try to load it as text
3. If succeeds, parse text to get path, then load resolved path as XML

**Impact:** Can cause 2-3 sequential HTTP requests before success.

### 4. **Window.onload Handler** (Waits for All Resources)
The main initialization code runs in `$(window).on('load')`, which waits for:
- All images
- All stylesheets
- All scripts
- All other resources

**Impact:** Blocks until everything is loaded.

## Performance Bottlenecks Identified

### High Impact:
1. **PDF.js library** - Very large library loaded upfront, even if PDFs aren't used
2. **Multiple XSLT files** - 8 files loaded sequentially (though async, they still take time)
3. **XSD fallback mechanism** - Multiple sequential requests
4. **Synchronous script loading** - All scripts block parsing

### Medium Impact:
1. **TIFF.js library** - Large library, may not always be needed
2. **Turf.js library** - Large geospatial library, may not always be needed
3. **Xmllint.js** - Large library for XML validation

### Low Impact:
1. **Multiple small libraries** - jQuery, Mousetrap, etc. are relatively small

## Recommendations

### Quick Wins (Easy to Implement):

1. **Lazy Load PDF.js**
   - Only load PDF.js when a PDF file is actually opened
   - Move PDF.js loading to the file opening handler

2. **Optimize XSD Loading**
   - Cache the XSD file path after first successful load
   - Skip fallback if XSD is already cached
   - Pre-determine the correct XSD path

3. **Defer Non-Critical Scripts**
   - Mark some libraries as `defer` or `async` in HTML
   - Load validation libraries (xmllint) only when needed

4. **Parallel XSLT Loading**
   - XSLTs are already loaded in parallel, but ensure they don't block UI
   - Show UI immediately, allow XSLTs to load in background

### Medium Effort:

1. **Code Splitting**
   - Split large libraries into chunks
   - Load only what's needed for initial UI

2. **Resource Preloading**
   - Use `<link rel="preload">` for critical XSLT files
   - Preload XSD file

3. **Service Worker Caching**
   - Cache XSLT and XSD files after first load
   - Serve from cache on subsequent loads

### Advanced:

1. **Web Workers**
   - Move XSLT processing to Web Workers
   - Don't block main thread during XSLT compilation

2. **Bundle Optimization**
   - Use a bundler to combine and minify scripts
   - Tree-shake unused code from libraries

## Immediate Action Items

1. **Add loading indicator** (already attempted, but user removed it)
2. **Lazy load PDF.js** - Biggest win for startup time
3. **Cache XSD path** - Avoid fallback chain on subsequent loads
4. **Add performance logging** - Measure actual bottlenecks

## Expected Improvements

- **Lazy load PDF.js**: ~500-800ms faster startup
- **Optimize XSD loading**: ~100-200ms faster startup
- **Defer non-critical scripts**: ~200-300ms faster startup
- **Total potential improvement**: ~800-1300ms faster startup
