/**
 * Lazy-loads PDF.js, tiff.js, and turf after first paint to speed cold start.
 * Exposes window.ensurePageEditorHeavyVendors(callback).
 *
 * @version 1.2.0
 */

/*jshint esversion: 6 */
/*global PDFJS, Tiff, turf */

(function ( global ) {
  'use strict';

  var
  promise = null,
  scripts = [
    '../js/tiff-2016-11-01.min.js',
    '../js/pdfjs-1.8.579.min.js',
    '../js/turf-5.1.6.min.js'
  ];

  function loadScript( src ) {
    return new Promise( function ( resolve, reject ) {
      var s = document.createElement( 'script' );
      s.src = src;
      s.onload = function () { resolve(); };
      s.onerror = function () { reject( new Error( 'Failed to load ' + src ) ); };
      document.head.appendChild( s );
    } );
  }

  function loadAll() {
    if ( promise )
      return promise;
    promise = scripts.reduce( function ( chain, src ) {
      return chain.then( function () { return loadScript( src ); } );
    }, Promise.resolve() );
    return promise;
  }

  /**
   * Ensures PDFJS, Tiff, and turf globals exist (loads scripts once).
   * @param {function} done  Called when ready (or on load error, after console.error).
   */
  function ensurePageEditorHeavyVendors( done ) {
    if ( typeof PDFJS !== 'undefined' && typeof Tiff !== 'undefined' && typeof turf !== 'undefined' )
      return done();
    loadAll()
      .then( function () { done(); } )
      .catch( function ( e ) {
        console.error( e );
        done();
      } );
  }

  global.ensurePageEditorHeavyVendors = ensurePageEditorHeavyVendors;
}( typeof window !== 'undefined' ? window : this ));
