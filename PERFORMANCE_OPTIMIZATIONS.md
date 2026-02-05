# Performance Optimizations - Startup Time Improvements

## Optimizations Implemented

### 1. ✅ Lazy Load PDF.js (Biggest Impact)
**Before:** PDF.js (~500KB+) loaded synchronously on every startup  
**After:** PDF.js only loads when a PDF file is actually opened  
**Expected Improvement:** ~500-800ms faster startup

**Implementation:**
- Removed PDF.js script tag from HTML
- Added dynamic loading function `loadPdfJs()` in `page-canvas.js`
- PDF.js loads on-demand when PDF file is detected

### 2. ✅ XSD Path Caching
**Before:** XSD loading used 2-3 sequential HTTP requests (fallback chain)  
**After:** Resolved XSD path is cached after first successful load  
**Expected Improvement:** ~100-200ms faster on subsequent loads

**Implementation:**
- Added `pagexml_xsd_resolved_path` cache variable
- Cache is used on subsequent loads to skip fallback chain
- Cache is cleared if it becomes invalid

### 3. ✅ Deferred Non-Critical Scripts
**Before:** All scripts loaded synchronously, blocking parsing  
**After:** Non-critical scripts (TIFF.js, Turf.js, xmllint.js) use `defer` attribute  
**Expected Improvement:** ~200-300ms faster startup

**Implementation:**
- Added `defer` attribute to:
  - `tiff-2016-11-01.min.js`
  - `turf-5.1.6.min.js`
  - `xmllint.js`

### 4. ✅ Performance Timing & Monitoring
**Added:** Comprehensive performance logging to track startup milestones

**Metrics Tracked:**
- Scripts loaded
- Window load event
- XSLT loading started
- Import XSLTs loaded
- Export XSLTs loaded
- XSD loading started
- XSD loaded
- Initialization complete

**Output:** Performance summary logged to console with timing breakdown

## Expected Total Improvement

- **First load:** ~500-800ms faster (PDF.js not loaded)
- **Subsequent loads:** ~800-1300ms faster (with XSD caching)

## How to View Performance Metrics

1. Launch the application
2. Open DevTools:
   - **macOS:** `Cmd+Option+I`
   - **Windows/Linux:** `Ctrl+Shift+I`
3. Go to the **Console** tab
4. Look for messages prefixed with `[PERF]`
5. At the end, you'll see:
   ```
   [PERF] === Startup Performance Summary ===
   [PERF] Total startup time: XXX.XXms
   [PERF] Breakdown:
   [PERF]   Scripts loaded: XX.XXms (X.X%)
   [PERF]   Window load event: XX.XXms (X.X%)
   ...
   ```

## Testing

Run the test script:
```bash
./test-startup-performance.sh
```

Or launch the application and check the console:
```bash
./bin/visual-page-editor
```

## Files Modified

1. `html/index.html` - Removed PDF.js, added defer attributes
2. `js/page-canvas.js` - Added PDF.js lazy loading
3. `js/nw-app.js` - Added XSD caching and performance timing
4. `debian/visual-page-editor/usr/share/visual-page-editor/html/index.html` - Same changes
5. `debian/visual-page-editor/usr/share/visual-page-editor/js/page-canvas.js` - Same changes
6. `debian/visual-page-editor/usr/share/visual-page-editor/js/nw-app.js` - Same changes

## Notes

- PDF.js will still load when needed (when opening a PDF file)
- XSD caching only helps on subsequent application launches
- Deferred scripts still load, just don't block initial parsing
- Performance metrics are logged to console (non-intrusive)
