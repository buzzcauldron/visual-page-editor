/**
 * Type definitions for SvgCanvas and PageCanvas APIs.
 * Used by page-editor.js, web-app.js, nw-app.js.
 */

/// <reference lib="dom" />

/** Config object passed to SvgCanvas/PageCanvas constructors */
export interface SvgCanvasConfig {
  stylesId?: string;
  textareaId?: string;
  registerChangeEnabled?: boolean;
  handleError?: (err: Error | string) => boolean | void;
  handleWarning?: (msg: string) => void;
  onLoad?: () => void;
  onUnload?: () => void;
  onSelect?: (elem: Element) => void;
  onUnselect?: (elem: Element) => void;
  onChange?: () => void;
  onFirstChange?: () => void;
  onMouseMove?: (x: number, y: number) => void;
  onSetConfig?: ((config: object) => void)[];
  onPanZoomChange?: ((boxW: number, boxH: number) => void)[];
  modeFilter?: string;
  centerOnSelection?: boolean;
  textFormatter?: (html: string) => string;
  textValidator?: (text: string, strict: boolean, elem?: Element) => boolean | string;
  pagexmlns?: string;
  [key: string]: unknown;
}

/** Config object for PageCanvas (extends SvgCanvas) */
export interface PageCanvasConfig extends SvgCanvasConfig {
  importSvgXsltHref?: string | string[];
  exportSvgXsltHref?: string | string[];
  getImageFromXMLPath?: ((path: string) => string) | null;
  readingDirection?: 'ltr' | 'rtl' | 'ttb';
  baselineType?: 'default' | 'margin';
  baselineFirstAngleRange?: [number, number] | null;
  polyrectOffset?: number;
  baselineMaxPoints?: number;
  coordsMaxPoints?: number;
  tableSize?: [number, number];
  editAfterCreate?: boolean;
  editablesSortCompare?: ((a: Element, b: Element) => number) | null;
  ajaxVersionStamp?: string;
  [key: string]: unknown;
}

/** Utility methods on SvgCanvas/PageCanvas instances */
export interface SvgCanvasUtil {
  svgRoot: SVGElement | null;
  sns: string;
  xns: string;
  getSortedEditables: () => JQuery;
  getBaselineType: (elem: Element) => string;
  getBaselineOrientation: (elem: Element) => string;
  getTextConf: (elem: Element) => number | null;
  getCoordsConf: (elem: Element) => number | null;
  getBaselineConf: (elem: Element) => number | null;
  getPropertiesWithConf: (elem: Element | JQuery) => Array<{ key: string; value: string; conf?: number }>;
  getGroupMembersWithConf: (elem: Element) => unknown[];
  getReadingDirection: (elem?: Element) => string;
  isReadOnly: (elem: Element) => boolean;
  isAxisAligned: (elem: Element) => boolean;
  setProperty: (key: string, val: string, elem: Element, add?: boolean, conf?: number, setBy?: string) => void;
  delProperty: (key: string, elem: Element) => void;
  setBaselineType: (elem: Element, type: string) => void;
  setTextClipping: (enabled: boolean) => void;
  isValidCoords: (points: Array<{ x: number; y: number }>, elem: Element, complete: boolean, regionType?: string) => boolean;
  strXmlValidate: (text: string, strict: boolean) => boolean | string;
  rotatePage: (angle: number, sel?: JQuery) => void;
  panZoomTo: (fact: number, limits?: boolean, sel?: string | JQuery) => void;
  selectFiltered: (selector: string) => void;
  [key: string]: unknown;
}

/** Mode methods on SvgCanvas/PageCanvas instances */
export interface SvgCanvasMode {
  current: () => void;
  pageSelect: () => void;
  regionSelect: (textChecked?: boolean) => void;
  regionBaselines: () => void;
  regionCoords: (textChecked?: boolean, restriction?: string) => void;
  regionDrag: (textChecked?: boolean) => void;
  regionCoordsCreate: (restriction?: string) => void;
  lineSelect: (textChecked?: boolean) => void;
  lineBaseline: (textChecked?: boolean, restriction?: string) => void;
  lineCoords: (textChecked?: boolean, restriction?: string) => void;
  lineDrag: (textChecked?: boolean) => void;
  lineCoordsCreate: (restriction?: string) => void;
  lineBaselineCreate: (restriction?: string) => void;
  wordSelect: (textChecked?: boolean) => void;
  wordCoords: (textChecked?: boolean, restriction?: string) => void;
  wordDrag: (textChecked?: boolean) => void;
  wordCoordsCreate: (restriction?: string) => void;
  glyphSelect: (textChecked?: boolean) => void;
  glyphCoords: (textChecked?: boolean, restriction?: string) => void;
  glyphDrag: (textChecked?: boolean) => void;
  glyphCoordsCreate: (restriction?: string) => void;
  cellSelect: (textChecked?: boolean) => void;
  tablePoints: (restriction?: string | null) => void;
  tableDrag: () => void;
  tableCreate: (restriction?: string | null) => void;
  groupSelect: () => void;
  addGroup: (memberType: string, size: [number, number], initType: string, afterAdd?: (elem: Element) => void) => void;
  modifyGroup: (memberType: string, size: [number, number]) => void;
  allSelect: (textChecked?: boolean) => void;
  select: (tapSelector: string, pointsSelector: string) => void;
  rect: (tapSelector: string, pointsSelector: string, dropSelector: string, isvalidpoly: (...args: unknown[]) => boolean) => void;
  points: (tapSelector: string, pointsSelector: string, dropSelector: string, isvalidpoly: (...args: unknown[]) => boolean) => void;
  drag: (tapSelector: string, dropSelector: string, moveFunc?: unknown, pointsSelector?: string) => void;
  editModeCoordsCreate: (restriction: string, elemSelector: string, elemType: string, dropSelector: string, idPrefix: string, afterCreate?: (elem: Element) => void) => void;
  [key: string]: unknown;
}

/** SvgCanvas instance (constructor return type) */
export interface SvgCanvasInstance {
  cfg: SvgCanvasConfig;
  util: SvgCanvasUtil;
  mode: SvgCanvasMode;
  enum: { restrict: { AxisAligned: string; AxisAlignedRectangle: string; RotatedAxisAligned: string } };
  setConfig: (config: object) => void;
  getVersion: () => Record<string, string>;
  throwError: (err: Error | string) => void;
  warning: (message: string) => void;
  registerChange: (changeType: string) => void;
  adjustViewBox: () => void;
  snapImageToLeft?: () => void;
  [key: string]: unknown;
}

/** PageCanvas instance (extends SvgCanvas) */
export interface PageCanvasInstance extends SvgCanvasInstance {
  cfg: PageCanvasConfig;
  clearCanvas: () => void;
  closeDocument: () => void;
  loadXmlPage: (data: string | undefined, basePath: string, onError?: (msg: string) => void) => void;
  getXmlPage: () => string;
  newXmlPage: (creator: string, filename: string, width: number, height: number) => string;
  hasChanged: () => boolean;
  setChanged: () => void;
  setUnchanged: () => void;
  fitPage?: () => void;
  [key: string]: unknown;
}

/** SvgCanvas constructor */
export interface SvgCanvasConstructor {
  new (containerId: string, config?: SvgCanvasConfig): SvgCanvasInstance;
}

/** PageCanvas constructor */
export interface PageCanvasConstructor {
  new (containerId: string, config?: PageCanvasConfig): PageCanvasInstance;
}

declare global {
  interface Window {
    SvgCanvas: SvgCanvasConstructor;
    PageCanvas: PageCanvasConstructor;
    pageCanvas?: PageCanvasInstance;
  }
}

export {};
