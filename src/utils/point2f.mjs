/**
 * 2D float point class and geometry helpers — pure math, no DOM dependency.
 * Extracted from js/page-canvas.js for testability and reuse.
 */

export function Point2f( val1, val2 ) {
  if ( ! ( this instanceof Point2f ) )
    return new Point2f(val1,val2);
  if ( typeof val1 === 'undefined' && typeof val2 === 'undefined' )
    return new Point2f(0,0);
  if ( typeof val2 === 'undefined' ) {
    this.x += typeof val1.x === 'undefined' ? val1 : val1.x ;
    this.y += typeof val1.y === 'undefined' ? val1 : val1.y ;
  }
  else {
    this.x = val1;
    this.y = val2;
  }
  return this;
}
Point2f.prototype.x = null;
Point2f.prototype.y = null;
Point2f.prototype.set = function( val ) {
  if ( ! val || typeof val.x === 'undefined' || typeof val.y === 'undefined' )
    return false;
  val.x = this.x;
  val.y = this.y;
  return true;
};
Point2f.prototype.copy = function( val ) {
  this.x = val.x;
  this.y = val.y;
  return this;
};
Point2f.prototype.add = function( val ) {
  this.x += typeof val.x === 'undefined' ? val : val.x ;
  this.y += typeof val.y === 'undefined' ? val : val.y ;
  return this;
};
Point2f.prototype.subtract = function( val ) {
  this.x -= typeof val.x === 'undefined' ? val : val.x ;
  this.y -= typeof val.y === 'undefined' ? val : val.y ;
  return this;
};
Point2f.prototype.hadamard = function( val ) {
  this.x *= typeof val.x === 'undefined' ? val : val.x ;
  this.y *= typeof val.y === 'undefined' ? val : val.y ;
  return this;
};
Point2f.prototype.dot = function( val ) {
  return this.x*val.x + this.y*val.y ;
};
Point2f.prototype.norm = function() {
  return Math.sqrt( this.x*this.x + this.y*this.y );
};
Point2f.prototype.euc2 = function( val ) {
  var dx = this.x-val.x, dy = this.y-val.y;
  return dx*dx + dy*dy;
};
Point2f.prototype.euc = function( val ) {
  var dx = this.x-val.x, dy = this.y-val.y;
  return Math.sqrt( dx*dx + dy*dy );
};
Point2f.prototype.unit = function() {
  var norm = Math.sqrt( this.x*this.x + this.y*this.y );
  if ( norm === 0 ) return this;
  this.x /= norm;
  this.y /= norm;
  return this;
};

/**
 * Checks if a point lies within the bounds of a line segment (between endpoints, inclusive).
 */
export function pointInSegment( segm_start, segm_end, point ) {
  var
  segm = Point2f(segm_end).subtract(segm_start),
  start_point = Point2f(segm_start).subtract(point),
  end_point = Point2f(segm_end).subtract(point);
  return 1.0001*segm.dot(segm) >= start_point.dot(start_point) + end_point.dot(end_point);
}

/**
 * Checks if a point is collinear with and within a line segment.
 * Returns 0 if within segment, +1 if beyond end, -1 if before start.
 * Returns undefined if the point is not collinear with the segment.
 */
export function withinSegment( segm_start, segm_end, point ) {
  var
  a = Point2f(segm_start),
  b = Point2f(segm_end),
  c = Point2f(point),
  ab = a.euc(b),
  ac = a.euc(c),
  bc = b.euc(c),
  area = Math.abs( a.x*(b.y-c.y) + b.x*(c.y-a.y) + c.x*(a.y-b.y) ) / (2*(ab+ac+bc)*(ab+ac+bc));

  if ( area > 1e-3 )
    return;
  if ( ac <= ab && bc <= ab )
    return 0;
  return ac > bc ? 1 : -1;
}

/**
 * Returns +1, -1 or 0 depending on which side of a directed line a point lies.
 */
export function sideOfLine( line_p1, line_p2, point ) {
  var val = (line_p1.x-line_p2.x)*(point.y-line_p2.y)-(line_p1.y-line_p2.y)*(point.x-line_p2.x);
  if ( val === 0 )
    return 0;
  return val > 0 ? 1 : -1;
}

/**
 * Finds the intersection point between two lines (each defined by two points).
 * Writes the result into _ipoint and returns true, or returns false if lines are parallel.
 */
export function intersection( line1_point1, line1_point2, line2_point1, line2_point2, _ipoint ) {
  var
  x = Point2f(line2_point1).subtract(line1_point1),
  direct1 = Point2f(line1_point2).subtract(line1_point1),
  direct2 = Point2f(line2_point2).subtract(line2_point1),
  cross = direct1.x*direct2.y - direct1.y*direct2.x;
  if( Math.abs(cross) < 1e-8 )
    return false;

  var t1 = (x.x * direct2.y - x.y * direct2.x)/cross;
  Point2f(line1_point1).add(direct1.hadamard(t1)).set(_ipoint);

  return true;
}

/**
 * Computes the point on a line that extends beyond a segment by factor * segment_length.
 * Writes result into _point.
 */
export function extendSegment( segment1, segment2, factor, _point ) {
  var
  segment = Point2f(segment2).subtract(segment1),
  length = segment.norm();
  segment.x /= length;
  segment.y /= length;
  Point2f( segment2 )
    .add( segment.hadamard(factor*length) )
    .set( _point );
}
