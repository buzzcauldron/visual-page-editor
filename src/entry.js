/**
 * Bundle entry point — imports app scripts in their original load order.
 * Vendor scripts (jQuery, interact, mousetrap, marked, xmllint) remain as
 * separate <script> tags in index.html and are expected as window globals.
 *
 * Load order mirrors the original <script> tags in html/index.html:
 *   vendor-loader  → svg-canvas → page-canvas → page-editor
 *   → editor-config → nw-app → nw-winstate
 */

/* global $, Mousetrap, interact, nw, PDFJS, Tiff, turf, xmllint */

import '../js/vendor-loader.js';
import '../js/svg-canvas.js';
import '../js/page-canvas.js';
import '../js/page-editor.js';
import '../js/editor-config.js';
import '../js/nw-app.js';
import '../js/nw-winstate.js';
