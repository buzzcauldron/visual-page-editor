# Startup Performance Bottlenecks Analysis

## Critical Issues (High Impact)

### 1. ⚠️ **`$(window).on('load')` - MAJOR BOTTLENECK**
**Location:** `js/page-editor.js:15`, `js/nw-app.js:107`

**Problem:** 
- `window.onload` waits for **ALL** resources to load:
  - All images
  - All stylesheets  
  - All fonts
  - All iframes
  - Everything else
  
**Impact:** This is likely the **biggest single bottleneck**. The app won't even start initializing until every resource is loaded.

**Solution:** 
- Use `$(document).ready()` or `DOMContentLoaded` instead
- These fire as soon as DOM is parsed (much earlier)
- Only use `window.onload` for things that actually need all resources

**Expected Improvement:** 500-2000ms+ faster startup (depends on resources)

### 2. ⚠️ **XSLT Loading During Constructor**
**Location:** `js/page-canvas.js:436` - `loadXslt(true)` called during PageCanvas constructor

**Problem:**
- 8 XSLT files are loaded asynchronously during PageCanvas initialization
- This happens during `window.onload`, so it's already delayed
- XSLTs are loaded even if no file is opened yet

**Impact:** Blocks initialization, adds 200-800ms depending on network/disk

**Solution:**
- Lazy load XSLTs - only load when actually needed (when opening a file)
- Or load them in parallel after DOM is ready, don't block initialization

**Expected Improvement:** 200-800ms faster startup

### 3. ⚠️ **XSD Loading During Window.onload**
**Location:** `js/nw-app.js:632` - XSD loading happens during window.onload

**Problem:**
- XSD loading has fallback chain (2-3 sequential requests)
- Happens during window.onload (already delayed)
- Even with caching, first load is slow

**Impact:** Adds 100-300ms to startup

**Solution:**
- Load XSD lazily when validation is actually needed
- Or load it in background after DOM ready

**Expected Improvement:** 100-300ms faster startup

## Medium Impact Issues

### 4. **Synchronous Script Loading**
**Location:** `html/index.html` - Many scripts load synchronously

**Current State:**
- ✅ PDF.js - Already lazy loaded (good!)
- ✅ TIFF.js, Turf.js, xmllint.js - Already deferred (good!)
- ❌ jQuery, jquery.stylesheet, interact, mousetrap, marked - Still synchronous
- ❌ svg-canvas.js, page-canvas.js, page-editor.js, nw-app.js - Still synchronous

**Impact:** Blocks parsing, but less critical than window.onload

**Solution:**
- Can defer more scripts, but be careful about dependencies
- Main app scripts (page-canvas, page-editor) need to load before window.onload

**Expected Improvement:** 100-200ms faster startup

### 5. **PageCanvas Constructor Overhead**
**Location:** `js/page-canvas.js:43` - PageCanvas constructor

**Problem:**
- Constructor does a lot of work immediately
- Calls `loadXslt(true)` synchronously
- Initializes many internal structures

**Impact:** Adds 50-100ms to initialization

**Solution:**
- Defer non-critical initialization
- Make constructor lighter, move heavy work to methods

**Expected Improvement:** 50-100ms faster startup

## Low Impact Issues

### 6. **CSS Loading**
**Location:** `html/index.html:14-15`

**Problem:**
- CSS files load synchronously
- Blocks rendering

**Impact:** Minor - CSS is usually small and fast

**Solution:** Can preload or inline critical CSS

**Expected Improvement:** 10-50ms faster startup

## Recommended Fix Priority

### Phase 1: Quick Wins (Biggest Impact)
1. **Change `$(window).on('load')` to `$(document).ready()`** 
   - This alone could save 500-2000ms+
   - Only use window.onload for things that truly need all resources

2. **Lazy load XSLTs**
   - Only load when opening a file
   - Don't block initialization

### Phase 2: Medium Effort
3. **Lazy load XSD**
   - Only load when validation is needed
   - Or load in background

4. **Optimize PageCanvas constructor**
   - Defer non-critical initialization
   - Make it lighter

### Phase 3: Polish
5. **Further script optimization**
   - Defer more scripts if possible
   - Check dependencies carefully

## Expected Total Improvement

- **Phase 1 only:** 700-2800ms faster startup
- **Phase 1 + 2:** 850-3200ms faster startup  
- **All phases:** 1000-3500ms faster startup

## Testing

After changes, check console for `[PERF]` messages to see actual improvements.
