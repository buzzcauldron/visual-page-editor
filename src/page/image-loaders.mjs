/**
 * Image loaders for PDF and TIFF formats.
 * Extracted from js/page-canvas.js.
 *
 * Each loader is created via a factory function that accepts injected dependencies
 * so the module has no hard reference to the PageCanvas closure.
 *
 * Loader signature: loader(image, onLoad[, cached])
 *   - If called with a string, returns true if the loader handles that file extension.
 *   - If called with a jQuery image element, loads it and calls onLoad(image) when done.
 */

/* global PDFJS, Tiff, ensurePageEditorHeavyVendors */

// ─── PDF Loader ───────────────────────────────────────────────────────────────

/**
 * Creates a PDF page loader backed by PDF.js.
 *
 * @param {object}   opts
 * @param {Function} opts.onError              Throw-style error callback (msg).
 * @param {Function} opts.onWarning            Warning callback (msg).
 * @param {Function} opts.getPagePath          Returns the current page file path string.
 * @param {Function} opts.onImageSizeMismatch  Called when PDF aspect ratio differs from XML.
 */
export function createPdfLoader({ onError, onWarning, getPagePath, onImageSizeMismatch }) {
  let pendingLimitPdfCache = false;

  async function limitPdfCache() { // jshint ignore:line
    if ( ! pendingLimitPdfCache )
      return;
    const maxCached = 200;
    const pdfcache = await caches.open('pdfs'); // jshint ignore:line
    const pdfreqs = await pdfcache.keys(); // jshint ignore:line
    for ( let n = 0; n < pdfreqs.length-maxCached; n++ )
      pdfcache.delete(pdfreqs[n]);
    pendingLimitPdfCache = false;
  }

  function scheduleLimitPdfCache() {
    pendingLimitPdfCache = true;
    setTimeout( limitPdfCache, 15000 );
  }

  function imageLoadBlob( blob, image, onLoad, pdfPagePathSize ) {
    if ( typeof pdfPagePathSize !== 'undefined' ) {
      pdfPagePathSize = pdfPagePathSize.replace(/^file:\/\//,'http://file');
      var
      headers = new Headers({ 'Last-Modified': new Date().toGMTString() }),
      response = new Response( blob, { headers: headers } );
      caches.open('pdfs').then( cache => cache.put( pdfPagePathSize, response ) );
      scheduleLimitPdfCache();
    }
    var url = URL.createObjectURL(blob);
    image.attr( 'data-rhref', url );
    image.on('destroyed', function() { URL.revokeObjectURL(url); });
    onLoad(image);
  }

  function loadPdfPage( pdf, pdfPagePath, pageNum, image, onLoad ) {
    var
    imgWidth  = parseInt(image.attr('width')),
    imgHeight = parseInt(image.attr('height'));

    if ( pageNum < 1 || pageNum > pdf.numPages )
      onError( 'Unexpected page number: '+pageNum );

    pdf.getPage(pageNum)
      .then( function( page ) {
        var viewport = page.getViewport(1.0);
        var ratio_diff = imgWidth < imgHeight ?
          imgWidth/imgHeight - viewport.width/viewport.height :
          imgHeight/imgWidth - viewport.height/viewport.width;
        if ( Math.abs(ratio_diff) > 1e-2 ) {
          var msg = 'aspect ratio differs between pdf page and XML: '+viewport.width+'/'+viewport.height+' vs. '+imgWidth+'/'+imgHeight;
          if ( onImageSizeMismatch( msg, image ) )
            onWarning(msg);
        }

        viewport = page.getViewport( imgWidth/viewport.width );

        var
        pdfPagePathSize = pdfPagePath+':'+imgWidth+'x'+imgHeight,
        canvas = document.createElement('canvas'),
        context = canvas.getContext('2d');
        canvas.height = imgHeight;
        canvas.width  = imgWidth;

        try {
          var fstat = require('fs').statSync(pdfPagePath.replace(/^file:\/\//, '').replace(/\[[0-9]+]$/, ''));
          pdfPagePathSize += ':'+fstat.size+':'+fstat.mtimeMs;
        } finally {}

        page.render({ canvasContext: context, viewport: viewport })
          .then(
            function () {
              canvas.toBlob( function(blob) {
                imageLoadBlob( blob, image, onLoad, pdfPagePathSize );
              }, 'image/webp' );
            },
            function ( err ) {
              onError( 'problems rendering pdf: '+err );
            }
          );
      },
      function ( err ) {
        onError( 'problems getting pdf page: '+err );
      } );
  }

  function pdfLoader( image, onLoad, cached ) {
    if ( typeof image === 'string' )
      return /\.pdf(\[[0-9]+]|)$/i.test(image);
    if ( typeof PDFJS === 'undefined' ) {
      ensurePageEditorHeavyVendors( function () {
        if ( typeof PDFJS === 'undefined' ) {
          onLoad( image );
          onError( 'Unable to load PDF.js' );
          return;
        }
        pdfLoader( image, onLoad, cached );
      } );
      return;
    }

    var
    pagePath = getPagePath(),
    url = image.attr('data-rhref').replace(/\[[0-9]+]$/,''),
    delim = pagePath.substr(1,2) === ':\\' ? '\\' : '/',
    pdfPagePath = pagePath.replace(/[/\\][^/\\]+$/,'')+delim+image.attr('data-href'),
    pdfPagePathSize = pdfPagePath+':'+image.attr('width')+'x'+image.attr('height'),
    pageNum = /]$/.test(image.attr('data-rhref')) ? parseInt(image.attr('data-rhref').replace(/.*\[([0-9]+)]$/,'$1'))+1 : 1;

    try {
      var fstat = require('fs').statSync(url.replace(/^file:\/\//, ''));
      pdfPagePathSize += ':'+fstat.size+':'+fstat.mtimeMs;
    } finally {}

    var request = new Request(pdfPagePathSize.replace(/^file:\/\//,'http://file'));
    if ( typeof cached === 'undefined' ) {
      caches.match(request).then( response => pdfLoader( image, onLoad, typeof response === 'undefined' ? false : response ) );
      return;
    }
    else if ( cached ) {
      caches.match(request).then( response => response.blob().then( blob => imageLoadBlob( blob, image, onLoad ) ) );
      return;
    }

    PDFJS.getDocument(url)
      .then( pdf => loadPdfPage( pdf, pdfPagePath, pageNum, image, onLoad ) )
      .catch( () => { onLoad(image); onError( 'Unable to load pdf: '+url ); } );
  }

  return pdfLoader;
}

// ─── TIFF Loader ──────────────────────────────────────────────────────────────

/**
 * Creates a TIFF page loader backed by tiff.js.
 *
 * @param {object}   opts
 * @param {Function} opts.onError  Throw-style error callback (msg).
 */
export function createTiffLoader({ onError }) {
  function tiffLoader( image, onLoad ) {
    if ( typeof image === 'string' )
      return /\.tif{1,2}(\[[0-9]+]|)$/i.test(image);
    if ( typeof Tiff === 'undefined' ) {
      ensurePageEditorHeavyVendors( function () {
        if ( typeof Tiff === 'undefined' ) {
          onLoad( image );
          onError( 'Unable to load tiff.js' );
          return;
        }
        tiffLoader( image, onLoad );
      } );
      return;
    }

    var
    url = image.attr('data-rhref').replace(/\[[0-9]+]$/,''),
    pageNum = /]$/.test(image.attr('data-rhref')) ? parseInt(image.attr('data-rhref').replace(/.*\[([0-9]+)]$/,'$1'))+1 : 1;

    Tiff.initialize({TOTAL_MEMORY: 16777216 * 10});
    var xhr = new XMLHttpRequest();
    xhr.open('GET', url);
    xhr.responseType = 'arraybuffer';
    xhr.onload = function () {
      var buffer = xhr.response;
      var tiff = new Tiff({buffer: buffer});
      if ( pageNum < 1 || pageNum > tiff.countDirectory() )
        onError( 'Unexpected page number: '+pageNum );
      tiff.setDirectory(pageNum-1);
      var canvas = tiff.toCanvas();
      canvas.toBlob( function(blob) {
        var blobUrl = URL.createObjectURL(blob);
        image.attr( 'data-rhref', blobUrl );
        image.on('destroyed', function() { URL.revokeObjectURL(blobUrl); });
        onLoad(image);
      } );
    };
    xhr.addEventListener('error', () => { onLoad(image); onError( 'Unable to load tiff: '+url ); } );
    xhr.send();
  }

  return tiffLoader;
}
