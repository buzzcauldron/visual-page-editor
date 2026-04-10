/**
 * PanZoom — viewport state and all view-navigation operations for the SVG canvas.
 * Extracted from js/svg-canvas.js.
 *
 * Constructor accepts DOM references and callbacks so svg-canvas.js remains
 * decoupled and this module stays independently testable.
 *
 * Global side-effects (Mousetrap, interact, jQuery, svgRoot.setAttribute) are
 * isolated here rather than spread through svg-canvas.js.
 */

/* global $, Mousetrap, interact */

export const FITTED = Object.freeze({ NONE: 0, WIDTH: 1, HEIGHT: 2, PAGE: 3 });

export class PanZoom {
  /**
   * @param {object}   opts
   * @param {Element}  opts.svgRoot           The root <svg> element.
   * @param {Element}  opts.svgContainer       The container element (for size measurement).
   * @param {Array}    opts.onPanZoomChange    Callback array fired after every view change.
   * @param {Function} opts.dragpointScale     Called as dragpointScale(boxW, boxH) after view changes.
   * @param {Function} opts.selectedCenter     Returns SVG coords of the currently selected element.
   * @param {object}   opts.util               SvgCanvas util object (for util.dragging flag).
   */
  constructor({ svgRoot, svgContainer, onPanZoomChange, dragpointScale, selectedCenter, util }) {
    this._svgRoot = svgRoot;
    this._svgContainer = svgContainer;
    this._onPanZoomChange = onPanZoomChange;
    this._dragpointScaleCb = dragpointScale;
    this._selectedCenter = selectedCenter;
    this._util = util;

    this._boxX0 = 0;
    this._boxY0 = 0;
    this._boxW = 0;
    this._boxH = 0;
    this._canvasW = 0;
    this._canvasH = 0;
    this._canvasR = 1;
    this._xmin = 0;
    this._ymin = 0;
    this._width = 0;
    this._height = 0;
    this._svgR = 1;
    this._fitState = FITTED.NONE;
    this._active = false;
  }

  /**
   * Activates pan/zoom for the given content range and sets up all event handlers.
   * Mirrors the old self.svgPanZoom() call — safe to call again on SVG replacement.
   */
  init( xmin, ymin, width, height ) {
    this._active = true;
    this._xmin = xmin;
    this._ymin = ymin;
    this._width = width;
    this._height = height;
    this._svgR = width / height;

    this._adjustSize();
    this._bindEvents();
    this.fitPage();

    $(window).resize( () => this.adjustViewBox() );
  }

  // ─── Fit operations ─────────────────────────────────────────────────────────

  fitWidth() {
    this._boxW = this._width;
    this._boxH = this._width / this._canvasR;
    this._boxX0 = this._xmin;
    this._boxY0 = this._ymin + ( this._svgR < this._canvasR ? 0 : ( this._height - this._boxH ) / 2 );
    this._applyViewBox();
    this._fitState = FITTED.WIDTH;
    this.dragpointScale();
    this._firePanZoomChange();
    return false;
  }

  fitHeight() {
    this._boxH = this._height;
    this._boxW = this._height * this._canvasR;
    this._boxY0 = this._ymin;
    this._boxX0 = this._xmin + ( this._svgR > this._canvasR ? 0 : ( this._width - this._boxW ) / 2 );
    this._applyViewBox();
    this._fitState = FITTED.HEIGHT;
    this.dragpointScale();
    this._firePanZoomChange();
    return false;
  }

  fitPage() {
    if ( this._svgR < this._canvasR )
      this.fitHeight();
    else
      this.fitWidth();
    this._fitState = FITTED.PAGE;
    return false;
  }

  fitElem( elem ) {
    var rect = elem[0].getBBox();
    if ( rect.width / rect.height < this._canvasR && rect.height > 0 ) {
      this._boxH = rect.height;
      this._boxW = this._boxH * this._canvasR;
      this._boxY0 = rect.y;
      this._boxX0 = rect.x + ( rect.width - this._boxW ) / 2;
    }
    else if ( rect.width > 0 ) {
      this._boxW = rect.width;
      this._boxH = this._boxW / this._canvasR;
      this._boxX0 = rect.x;
      this._boxY0 = rect.y + ( rect.height - this._boxH ) / 2;
    }
    else
      return false;
    this._applyViewBox();
    this._fitState = FITTED.NONE;
    this.dragpointScale();
    this._firePanZoomChange();
    return false;
  }

  // ─── Pan / zoom ──────────────────────────────────────────────────────────────

  zoom( amount, point, factor ) {
    point = typeof point === 'undefined' ? { x: this._boxX0 + 0.5*this._boxW, y: this._boxY0 + 0.5*this._boxH } : point;
    factor = typeof factor === 'undefined' ? 0.05 : factor;
    var
    center = 0.2,
    scale = amount > 0 ?
      Math.pow( 1.0-factor, amount ) :
      Math.pow( 1.0+factor, -amount );
    this._boxW *= scale;
    this._boxH *= scale;
    this._boxX0 = scale * ( this._boxX0 - point.x ) + point.x;
    this._boxY0 = scale * ( this._boxY0 - point.y ) + point.y;
    this._boxX0 = (1-center) * this._boxX0 + center * ( point.x - 0.5*this._boxW );
    this._boxY0 = (1-center) * this._boxY0 + center * ( point.y - 0.5*this._boxH );
    this._viewBoxLimits();
    this._applyViewBox();
    this._fitState = FITTED.NONE;
    this.dragpointScale();
    this._firePanZoomChange();
    return false;
  }

  pan( dx, dy ) {
    var S = this._boxW < this._boxH ? this._boxW : this._boxH;
    this._boxX0 -= dx * S;
    this._boxY0 -= dy * S;
    this._viewBoxLimits();
    this._applyViewBox();
    this._firePanZoomChange();
    return false;
  }

  setViewBox( x, y, w, h ) {
    this._boxX0 = x;
    this._boxY0 = y;
    this._boxW = w;
    this._boxH = h;
    this._applyViewBox();
  }

  /**
   * Centers the viewbox on the currently selected element.
   * Shifts left slightly when the drawer is open so the selected element
   * remains visible behind the 350px right-side panel.
   */
  panToSelected() {
    var point = this._selectedCenter();
    if ( ! point )
      return;
    var drawerOpen = document.body && document.body.classList.contains('drawer-open');
    var centerBiasX = drawerOpen ? 0.4 : 0.5, centerBiasY = 0.5;
    this._boxX0 = point.x - centerBiasX * this._boxW;
    this._boxY0 = point.y - centerBiasY * this._boxH;
    this._viewBoxLimits();
    if ( isNaN(this._boxX0) || isNaN(this._boxY0) || isNaN(this._boxW) || isNaN(this._boxH) )
      return;
    this._applyViewBox();
  }

  /**
   * Pans the view by the minimum amount so the current selection's bounding box is inside
   * the viewport (with a small margin). Unlike snapImageToLeft(), does not force the
   * document left edge into view — use after selectElem(..., nocenter) so new elements
   * stay visible without the old "jump to xmin" behavior.
   */
  ensureSelectedInView() {
    if ( ! this._svgRoot || ! this._active )
      return;
    var sel = $(this._svgRoot).find('.selected').closest('g');
    if ( sel.length === 0 || sel.hasClass('dragging') )
      return;
    var rect = sel[0].getBBox();
    if ( ( ! rect.width && ! rect.height ) || isNaN(rect.x) )
      return;
    var rx0 = rect.x, ry0 = rect.y, rx1 = rect.x + rect.width, ry1 = rect.y + rect.height;
    var vx0 = this._boxX0, vy0 = this._boxY0, vw = this._boxW, vh = this._boxH;
    var m = Math.min( vw, vh ) * 0.02;
    if ( m < 2 ) m = 2;
    if ( m * 2 >= vw ) m = 0;
    if ( m * 2 >= vh ) m = 0;
    if ( rx0 >= vx0 + m && ry0 >= vy0 + m && rx1 <= vx0 + vw - m && ry1 <= vy0 + vh - m )
      return;
    var nx = vx0, ny = vy0;
    if ( rx1 - rx0 <= vw - 2 * m ) {
      var xLo = rx1 - vw + m, xHi = rx0 - m;
      nx = xLo <= xHi ? Math.min( Math.max( vx0, xLo ), xHi ) : rx0 - m;
    } else {
      nx = rx0 - m;
    }
    if ( ry1 - ry0 <= vh - 2 * m ) {
      var yLo = ry1 - vh + m, yHi = ry0 - m;
      ny = yLo <= yHi ? Math.min( Math.max( vy0, yLo ), yHi ) : ry0 - m;
    } else {
      ny = ry0 - m;
    }
    this._boxX0 = nx;
    this._boxY0 = ny;
    this._viewBoxLimits();
    this._applyViewBox();
    this.dragpointScale();
    this._firePanZoomChange();
  }

  /**
   * Snaps the view so the left edge of content aligns with the left side of the viewport.
   */
  snapImageToLeft() {
    if ( ! this._svgRoot )
      return;
    if ( typeof this._xmin === 'undefined' || isNaN(this._xmin) )
      return;
    this._boxX0 = this._xmin;
    this._viewBoxLimits();
    this._boxX0 = this._xmin; // re-apply after limits clamp
    if ( isNaN(this._boxX0) || isNaN(this._boxY0) || isNaN(this._boxW) || isNaN(this._boxH) )
      return;
    this._applyViewBox();
  }

  /**
   * Centers and optionally zooms the viewbox on a selected element.
   * @param {object} fact         Zoom factor: { w: fraction } or { h: fraction }.
   * @param {boolean} [limits]    Whether to apply viewbox limits (default true).
   * @param {string|jQuery|Element} [sel]  Target element (default '.selected').
   */
  panZoomTo( fact, limits, sel ) {
    if ( typeof sel === 'undefined' )
      sel = '.selected';
    if ( typeof sel === 'string' )
      sel = $(this._svgRoot).find(sel).closest('g');
    if ( typeof sel === 'object' && ! ( sel instanceof jQuery ) )
      sel = $(sel);
    if ( sel.length === 0 || sel.hasClass('dragging') )
      return;
    var rect = sel[0].getBBox();

    if ( typeof fact.w !== 'undefined' ) {
      this._boxW = rect.width / fact.w;
      this._boxH = this._boxW / this._canvasR;
    }
    else if ( typeof fact.h !== 'undefined' ) {
      this._boxH = rect.height / fact.h;
      this._boxW = this._boxH * this._canvasR;
    }

    var centerBiasX = 0.35, centerBiasY = 0.5;
    this._boxX0 = (rect.x + 0.5*rect.width) - centerBiasX * this._boxW;
    this._boxY0 = (rect.y + 0.5*rect.height) - centerBiasY * this._boxH;

    if ( typeof limits === 'undefined' || limits )
      this._viewBoxLimits();

    this._applyViewBox();
    this.dragpointScale();
    this._firePanZoomChange();
  }

  /**
   * Re-measures container and re-applies the current fit mode.
   * Called on window resize.
   */
  adjustViewBox() {
    if ( ! this._svgRoot )
      return;
    this._adjustSize();
    this._viewBoxLimits();
    switch ( this._fitState ) {
      case FITTED.WIDTH:  this.fitWidth();  break;
      case FITTED.HEIGHT: this.fitHeight(); break;
      case FITTED.PAGE:   this.fitPage();   break;
      default:
        this._applyViewBox();
    }
  }

  /**
   * Public wrapper — re-measures container and updates SVG width/height attributes.
   * Safe to call before init() (just measures, no fit recalculation).
   */
  adjustSize() {
    this._adjustSize();
  }

  /**
   * Fires the dragpointScale callback with current box dimensions.
   * Called after any view change that affects the scale of drag handles.
   */
  dragpointScale() {
    this._dragpointScaleCb( this._boxW, this._boxH );
  }

  /** Returns the current content range (mirrors self.util.canvasRange). */
  canvasRange() {
    return { width: this._width, height: this._height, x: this._xmin, y: this._ymin };
  }

  /** Returns a snapshot of the viewBox state for undo history. */
  getHistoryState() {
    return [ this._xmin, this._ymin, this._width, this._height,
             this._boxX0, this._boxY0, this._boxW, this._boxH ];
  }

  get active()    { return this._active; }
  get fitState()  { return this._fitState; }
  get FITTED()    { return FITTED; }
  get boxW()      { return this._boxW; }
  get boxH()      { return this._boxH; }

  // ─── Private helpers ─────────────────────────────────────────────────────────

  _adjustSize() {
    var prevW = this._canvasW, prevH = this._canvasH;
    this._canvasW = $(this._svgContainer).innerWidth();
    this._canvasH = $(this._svgContainer).innerHeight();
    if ( ! this._canvasH )
      this._canvasH = 1;
    this._canvasR = this._canvasW / this._canvasH;
    if ( typeof prevW === 'number' && typeof prevH === 'number' && prevW > 0 && prevH > 0 ) {
      this._boxW *= this._canvasW / prevW;
      this._boxH *= this._canvasH / prevH;
    }
    this._svgRoot.setAttribute( 'width',  this._canvasW );
    this._svgRoot.setAttribute( 'height', this._canvasH );
  }

  _viewBoxLimits() {
    var
    W = this._width, H = this._height,
    factW = W > 0 ? this._boxW / W : 1,
    factH = H > 0 ? this._boxH / H : 1;
    if ( factW > 1.2 && factH > 1.2 ) {
      if ( factW < factH ) {
        this._boxW = 1.2 * W;
        this._boxH = W / this._canvasR;
      }
      else {
        this._boxH = 1.2 * H;
        this._boxW = H * this._canvasR;
      }
    }
    if ( factW > 1 && factH > 1 ) {
      this._boxX0 = ( W - this._boxW ) / 2;
      this._boxY0 = ( H - this._boxH ) / 2;
    }

    var xmin = this._xmin, ymin = this._ymin;
    if ( this._boxX0 < xmin + ( this._boxW <= W ? 0 : W-this._boxW ) )
         this._boxX0 = xmin + ( this._boxW <= W ? 0 : W-this._boxW );
    if ( this._boxY0 < ymin + ( this._boxH <= H ? 0 : H-this._boxH ) )
         this._boxY0 = ymin + ( this._boxH <= H ? 0 : H-this._boxH );
    if ( this._boxX0 > xmin + ( this._boxW <= W ? W-this._boxW : 0 ) )
         this._boxX0 = xmin + ( this._boxW <= W ? W-this._boxW : 0 );
    if ( this._boxY0 > ymin + ( this._boxH <= H ? H-this._boxH : 0 ) )
         this._boxY0 = ymin + ( this._boxH <= H ? H-this._boxH : 0 );
  }

  _applyViewBox() {
    this._svgRoot.setAttribute( 'viewBox',
      this._boxX0+' '+this._boxY0+' '+this._boxW+' '+this._boxH );
  }

  _firePanZoomChange() {
    for ( var k = 0; k < this._onPanZoomChange.length; k++ )
      this._onPanZoomChange[k]( this._boxW, this._boxH );
  }

  _bindEvents() {
    var self = this;

    // Wheel: pan on scroll, zoom on shift+scroll
    $(this._svgRoot).on( 'wheel', function ( event ) {
      event = event.originalEvent;
      if ( event.deltaX === 0 && event.deltaY === 0 )
        return false;
      event.preventDefault();
      if ( event.shiftKey )
        return self.zoom( event.deltaX+event.deltaY > 0 ? 1 : -1, self._selectedCenter() );
      var x = 0, y = 0;
      if ( Math.abs(event.deltaX) > Math.abs(event.deltaY) )
        x = event.deltaX > 0 ? -0.02 : 0.02;
      else
        y = event.deltaY > 0 ? -0.02 : 0.02;
      return self.pan(x, y);
    } );

    // Keyboard shortcuts (see KEYBOARD-SHORTCUTS.md)
    Mousetrap.bind( ['alt+0','mod+0'], function () { return self.fitPage(); } );
    Mousetrap.bind( ['alt+shift+w','mod+shift+w'], function () { return self.fitWidth(); } );
    Mousetrap.bind( ['alt+shift+h','mod+shift+h'], function () { return self.fitHeight(); } );
    Mousetrap.bind( ['alt+=','mod+='], function () { return self.zoom(1, self._selectedCenter()); } );
    Mousetrap.bind( ['alt+-','mod+-'], function () { return self.zoom(-1, self._selectedCenter()); } );
    Mousetrap.bind( ['alt+right','mod+right'], function () { return self.pan(-0.02, 0); } );
    Mousetrap.bind( ['alt+left', 'mod+left'], function () { return self.pan( 0.02, 0); } );
    Mousetrap.bind( ['alt+up',   'mod+up'], function () { return self.pan(0,  0.02); } );
    Mousetrap.bind( ['alt+down', 'mod+down'], function () { return self.pan(0, -0.02); } );

    // Arrow keys: pan when zoomed in, page navigation when fit-to-page
    Mousetrap.bind( 'left',  function () {
      if ( self._fitState !== FITTED.PAGE ) { self.pan( 0.02, 0); return false; }
      $('#prevPage').click(); return false;
    } );
    Mousetrap.bind( 'right', function () {
      if ( self._fitState !== FITTED.PAGE ) { self.pan(-0.02, 0); return false; }
      $('#nextPage').click(); return false;
    } );
    Mousetrap.bind( 'up', function () {
      if ( self._fitState !== FITTED.PAGE ) { self.pan(0,  0.02); return false; }
      $('#prevPage').click(); return false;
    } );
    Mousetrap.bind( 'down', function () {
      if ( self._fitState !== FITTED.PAGE ) { self.pan(0, -0.02); return false; }
      $('#nextPage').click(); return false;
    } );

    // Drag to pan (interact.js)
    if ( typeof interact !== 'undefined' && typeof interact.pointerMoveTolerance === 'function' )
      interact.pointerMoveTolerance( 6 );

    interact(this._svgRoot)
      .draggable( { inertia: true } )
      .styleCursor(false)
      .on( 'dragstart', function () {
        self._util.dragging = true;
      } )
      .on( 'dragend', function () {
        window.setTimeout( function () { self._util.dragging = false; }, 100 );
      } )
      .on( 'dragmove', function ( event ) {
        self.pan( event.dx / self._canvasW, event.dy / self._canvasH );
        event.preventDefault();
      } );
  }
}
