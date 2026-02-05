# Workflow speed review

Summary of hot paths and optimizations for the visual page editor.

## Startup and document load

- **XSLT loading**: XSLT stylesheets are preloaded asynchronously when config is set (e.g. by nw-app). Document load no longer uses synchronous XSLT fetches; it waits for the preload via `ensureXsltReady()` so the main thread is never blocked by 8 sequential sync requests.
- **Script loading**: Optional scripts (`marked`, `xmllint`) use `defer` so they do not block initial parse; they run before DOMContentLoaded and are available for user actions (Readme, Validate).

## Hot paths

1. **Selection (click on element)**  
   - `selectElem` → unselect, add class, then in **rAF**: pan (if enabled), **onSelect** callbacks.  
   - **onSelect** (page-editor): type/id/modeElement, baseline type, textedit, parent classes, then **updateSelectedInfo** (heavy: getGroupMembersWithConf, getPropertiesWithConf, etc.).  
   - **Optimization**: `updateSelectedInfo()` runs once, deferred to `requestAnimationFrame` so the sidebar and selection paint first; skips if selection changed during rapid clicks (avoids wasted work).

2. **Mode switch (radio click)**  
   - `handleEditMode()` runs: 30+ jQuery selectors, then one `pageCanvas.mode.xxx()` which sets up click/dblclick on editables.  
   - **Optimization**: Mode panel jQuery refs are cached on first `handleEditMode` call and reused on subsequent mode switches to avoid repeated DOM queries.

3. **Mouse move**  
   - Every move: viewbox coords update, then **onMouseMove** (e.g. cursor X/Y in footer).  
   - **Optimization**: Coords still updated every move; **onMouseMove** callbacks are throttled with `requestAnimationFrame` so they run at most once per frame.

4. **Create → finish baseline**  
   - `finishBaseline`: setPolystripe, set editable, then either `setEditing` (point-edit + dragpoints) or just select.  
   - **Optimization**: When "Edit mode after create" is unchecked, `setEditing` is skipped and only selection runs (in rAF), so the next "Create" click is not blocked by dragpoint setup.

## Already in good shape

- **selectElem**: Pan and onSelect already run in rAF so selection highlight appears immediately.  
- **removeEditings**: Early exit when no `.editing` elements.  
- **getSortedEditables**: Cached; invalidated on load, mode change, sort change.

## Possible future improvements

- **Implemented (cache + delegation)**: Cached sorted editables; event delegation for editable click/dblclick.  
- **handleEditMode**: Cache could be invalidated if the mode panel DOM is ever rebuilt (e.g. dynamic drawer); currently the panel is static.
