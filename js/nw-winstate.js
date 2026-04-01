document.addEventListener('DOMContentLoaded', function() {
  'use strict';
  /**
   * https://github.com/nwjs/nw.js/wiki/Preserve-window-state-between-sessions
   *
   * Cross-platform window state preservation.
   * Yes this code is quite complicated, but this is the best I came up with for
   * current state of node-webkit Window API (v0.7.3 and later).
   *
   * Known issues:
   * - Unmaximization not always sets the window (x, y) in the lastly used coordinates.
   * - Unmaximization animation sometimes looks wierd.
   * - Extra height added to window, at least in linux x64 gnome-shell env. It seems that
   *   when we read height then it returns it with window frame, but if we resize window
   *   then it applies dimensions only to internal document without external frame.
   *   Need to test in other environments with different visual themes.
   *
   * Change log:
   * 2013-12-01
   * - Workaround of extra height in gnome-shell added.
   *
   * 2014-03-22
   * - Repared workaround (from 2013-12-01) behaviour when use frameless window.
   *   Now it works correctly.
   * 2014-10-02
   * - Fixed cannot set windowState of null error when attempting to set localStorage
   *
   * 2015-03-05
   * - Don't call window.show() if dev tools are already open (see initWindowState).
   *
   * 2015-06-15
   * - Don't resize the window when using LiveReload.
   */

  // NW.js 0.13+ uses global nw; 0.12 and earlier used require('nw.gui')
  var gui = (typeof nw !== 'undefined' && nw.Window) ? nw : (function () { try { return require('nw.gui'); } catch (e) { return null; } })();
  if (!gui || !gui.Window) {
    console.error('nw-winstate: NW.js Window API not available');
    return;
  }
  var win = gui.Window.get();
  var winState;
  var currWinMode;
  var resizeTimeout;
  var isMaximizationEvent = false;
  // extra height added in linux x64 gnome-shell env, use it as workaround
  var deltaHeight = (gui.App && gui.App.manifest && gui.App.manifest.window && gui.App.manifest.window.frame) ? 0 : 'disabled';

  function initWindowState() {
    // Don't resize the window when using LiveReload.
    // There seems to be no way to check whether a window was reopened, so let's
    // check for dev tools - they can't be open on the app start, so if
    // dev tools are open, LiveReload was used.
    //if (!win.isDevToolsOpen()) {
      winState = JSON.parse(localStorage.windowState || 'null');

      if (winState) {
        currWinMode = winState.mode;
        if (currWinMode === 'maximized') {
          win.maximize();
        } else {
          restoreWindowState();
        }
      } else {
        currWinMode = 'normal';
        dumpWindowState();
      }

      win.show();
    //}
  }

  function dumpWindowState() {
    if (!winState) {
      winState = {};
    }

    // we don't want to save minimized state, only maximized or normal
    if (currWinMode === 'maximized') {
      winState.mode = 'maximized';
    } else {
      winState.mode = 'normal';
    }

    // when window is maximized you want to preserve normal
    // window dimensions to restore them later (even between sessions)
    if (currWinMode === 'normal') {
      winState.x = win.x;
      winState.y = win.y;
      winState.width = win.width;
      winState.height = win.height;

      // save delta only of it is not zero
      if (deltaHeight !== 'disabled' && deltaHeight !== 0 && currWinMode !== 'maximized') {
        winState.deltaHeight = deltaHeight;
      }
    }
  }

  function restoreWindowState() {
    // deltaHeight already saved, so just restore it and adjust window height
    if (deltaHeight !== 'disabled' && typeof winState.deltaHeight !== 'undefined') {
      deltaHeight = winState.deltaHeight;
      winState.height = winState.height - deltaHeight;
    }


    // Make sure that the window is displayed somewhere on a screen that is connected to the PC.
    if (gui.Screen && typeof gui.Screen.Init === 'function') { gui.Screen.Init(); }
    var screens = (gui.Screen && gui.Screen.screens) ? gui.Screen.screens : [{ bounds: { x: 0, y: 0, width: 9999, height: 9999 } }];

    // Primary screen: one containing (0,0) or first screen. Use work_area when available (excludes taskbar).
    function getPrimaryArea() {
      var area = { x: 0, y: 0, width: 800, height: 600 };
      if (screens.length === 0) return area;
      var primary = screens[0], b;
      for (var p = 0; p < screens.length; p++) {
        b = screens[p].bounds;
        if (b.x <= 0 && b.x + b.width > 0 && b.y <= 0 && b.y + b.height > 0) {
          primary = screens[p];
          break;
        }
      }
      b = primary.bounds;
      if (primary.work_area && primary.work_area.width > 0 && primary.work_area.height > 0) {
        area = primary.work_area;
      } else {
        area = { x: b.x, y: b.y, width: b.width, height: b.height };
      }
      return area;
    }

    var locationIsOnAScreen = false, b;
    for (var i = 0; i < screens.length; i++) {
      var screen = screens[i];
      b = screen.bounds;
      if (winState.x >= b.x && winState.x < b.x + b.width && winState.y >= b.y && winState.y < b.y + b.height) {
        locationIsOnAScreen = true;
        break;
      }
    }

    var w = Math.max(1, Number(winState.width) || 800);
    var h = Math.max(1, Number(winState.height) || 600);

    if (!locationIsOnAScreen) {
      // Center on primary screen explicitly (setPosition('center') can misbehave on scaled/multi-monitor)
      var primary = getPrimaryArea();
      var centerX = primary.x + Math.floor((primary.width - w) / 2);
      var centerY = primary.y + Math.floor((primary.height - h) / 2);
      win.resizeTo(w, h);
      win.moveTo(centerX, centerY);
    }
    else {
      // Clamp to union of all screens so window stays visible (e.g. not above the screen)
      var union = { x: 0, y: 0, width: 0, height: 0 };
      if (screens.length > 0) {
        var b0 = screens[0].bounds;
        union.x = b0.x;
        union.y = b0.y;
        union.width = b0.width;
        union.height = b0.height;
        for (var j = 1; j < screens.length; j++) {
          b = screens[j].bounds;
          var uRight = union.x + union.width, uBottom = union.y + union.height;
          var bRight = b.x + b.width, bBottom = b.y + b.height;
          union.x = Math.min(union.x, b.x);
          union.y = Math.min(union.y, b.y);
          union.width = Math.max(uRight, bRight) - union.x;
          union.height = Math.max(uBottom, bBottom) - union.y;
        }
      }
      var clampX = Math.max(union.x, Math.min(winState.x, union.x + union.width - w));
      var clampY = Math.max(union.y, Math.min(winState.y, union.y + union.height - h));
      win.resizeTo(w, h);
      win.moveTo(clampX, clampY);
    }
  }

  function saveWindowState() {
    dumpWindowState();
    localStorage.windowState = JSON.stringify(winState);
  }
  window.saveWindowState = saveWindowState;

  initWindowState();

  win.on('maximize', function () {
    isMaximizationEvent = true;
    currWinMode = 'maximized';
    saveWindowState();
  });

  win.on('unmaximize', function () {
    currWinMode = 'normal';
    restoreWindowState();
    saveWindowState();
  });

  win.on('minimize', function () {
    currWinMode = 'minimized';
    saveWindowState();
  });

  win.on('restore', function () {
    currWinMode = 'normal';
    saveWindowState();
  });

  win.window.addEventListener('resize', function () {
    // resize event is fired many times on one resize action,
    // this hack with setTiemout forces it to fire only once
    clearTimeout(resizeTimeout);
    resizeTimeout = setTimeout(function () {

      // on MacOS you can resize maximized window, so it's no longer maximized
      if (isMaximizationEvent) {
        // first resize after maximization event should be ignored
        isMaximizationEvent = false;
      } else {
        if (currWinMode === 'maximized') {
          currWinMode = 'normal';
        }
      }

      // there is no deltaHeight yet, calculate it and adjust window size
      if (deltaHeight !== 'disabled' && deltaHeight === false) {
        deltaHeight = win.height - winState.height;

        // set correct size
        if (deltaHeight !== 0) {
          win.resizeTo(winState.width, win.height - deltaHeight);
        }
      }

      saveWindowState();

    }, 500);
  }, false);

  win.on('close', function () {
    try {
      saveWindowState();
    } catch(err) {
      console.log("winstateError: " + err);
    }
    this.close(true);
  });
});
