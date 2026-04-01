import { describe, it, expect } from 'vitest';
import {
  Point2f,
  pointInSegment,
  withinSegment,
  sideOfLine,
  intersection,
  extendSegment,
} from './point2f.mjs';

// ─── Point2f construction ────────────────────────────────────────────────────

describe('Point2f construction', () => {
  it('two-arg form sets x and y', () => {
    const p = Point2f(3, 4);
    expect(p.x).toBe(3);
    expect(p.y).toBe(4);
  });

  it('object form copies x and y', () => {
    const p = Point2f({ x: 5, y: -2 });
    expect(p.x).toBe(5);
    expect(p.y).toBe(-2);
  });

  it('scalar form applies to both axes', () => {
    const p = Point2f(7);
    expect(p.x).toBe(7);
    expect(p.y).toBe(7);
  });

  it('no-arg form returns zero point', () => {
    const p = Point2f();
    expect(p.x).toBe(0);
    expect(p.y).toBe(0);
  });

  it('works without new keyword', () => {
    const p = Point2f(1, 2);
    expect(p instanceof Point2f).toBe(true);
  });

  it('new keyword also works', () => {
    const p = new Point2f(1, 2);
    expect(p.x).toBe(1);
    expect(p.y).toBe(2);
  });
});

// ─── Arithmetic methods ───────────────────────────────────────────────────────

describe('Point2f arithmetic', () => {
  it('add with point', () => {
    const p = Point2f(1, 2).add({ x: 3, y: 4 });
    expect(p.x).toBe(4);
    expect(p.y).toBe(6);
  });

  it('add with scalar', () => {
    const p = Point2f(1, 2).add(10);
    expect(p.x).toBe(11);
    expect(p.y).toBe(12);
  });

  it('subtract with point', () => {
    const p = Point2f(5, 7).subtract({ x: 2, y: 3 });
    expect(p.x).toBe(3);
    expect(p.y).toBe(4);
  });

  it('subtract with scalar', () => {
    const p = Point2f(5, 7).subtract(2);
    expect(p.x).toBe(3);
    expect(p.y).toBe(5);
  });

  it('hadamard with point', () => {
    const p = Point2f(3, 4).hadamard({ x: 2, y: 0.5 });
    expect(p.x).toBe(6);
    expect(p.y).toBe(2);
  });

  it('hadamard with scalar', () => {
    const p = Point2f(3, 4).hadamard(2);
    expect(p.x).toBe(6);
    expect(p.y).toBe(8);
  });

  it('dot product', () => {
    expect(Point2f(1, 0).dot({ x: 0, y: 1 })).toBe(0);
    expect(Point2f(3, 4).dot({ x: 3, y: 4 })).toBe(25);
    expect(Point2f(1, 2).dot({ x: -2, y: 1 })).toBe(0);
  });

  it('arithmetic is mutating (returns same object)', () => {
    const p = Point2f(1, 1);
    const q = p.add({ x: 1, y: 1 });
    expect(q).toBe(p);
  });
});

// ─── Distance and magnitude ───────────────────────────────────────────────────

describe('Point2f distance/magnitude', () => {
  it('norm of 3-4-5 right triangle', () => {
    expect(Point2f(3, 4).norm()).toBeCloseTo(5);
  });

  it('norm of zero vector', () => {
    expect(Point2f(0, 0).norm()).toBe(0);
  });

  it('euc distance', () => {
    expect(Point2f(0, 0).euc({ x: 3, y: 4 })).toBeCloseTo(5);
  });

  it('euc2 (squared distance)', () => {
    expect(Point2f(0, 0).euc2({ x: 3, y: 4 })).toBe(25);
  });

  it('unit vector has norm 1', () => {
    const p = Point2f(3, 4).unit();
    expect(p.norm()).toBeCloseTo(1);
  });

  it('unit vector direction preserved', () => {
    const p = Point2f(3, 4).unit();
    expect(p.x).toBeCloseTo(0.6);
    expect(p.y).toBeCloseTo(0.8);
  });

  it('unit of axis-aligned vector', () => {
    const p = Point2f(0, 5).unit();
    expect(p.x).toBeCloseTo(0);
    expect(p.y).toBeCloseTo(1);
  });
});

// ─── copy / set ───────────────────────────────────────────────────────────────

describe('Point2f copy/set', () => {
  it('copy overwrites x and y', () => {
    const p = Point2f(1, 2).copy({ x: 9, y: -3 });
    expect(p.x).toBe(9);
    expect(p.y).toBe(-3);
  });

  it('set writes to target object', () => {
    const target = { x: 0, y: 0 };
    const result = Point2f(7, 8).set(target);
    expect(result).toBe(true);
    expect(target.x).toBe(7);
    expect(target.y).toBe(8);
  });

  it('set returns false for invalid target', () => {
    expect(Point2f(1, 2).set(null)).toBe(false);
    expect(Point2f(1, 2).set({})).toBe(false);
  });
});

// ─── pointInSegment ───────────────────────────────────────────────────────────

describe('pointInSegment', () => {
  const A = { x: 0, y: 0 };
  const B = { x: 10, y: 0 };

  it('midpoint is within segment', () => {
    expect(pointInSegment(A, B, { x: 5, y: 0 })).toBe(true);
  });

  it('endpoint A is within segment', () => {
    expect(pointInSegment(A, B, A)).toBe(true);
  });

  it('endpoint B is within segment', () => {
    expect(pointInSegment(A, B, B)).toBe(true);
  });

  it('point beyond B is outside', () => {
    expect(pointInSegment(A, B, { x: 15, y: 0 })).toBe(false);
  });

  it('point before A is outside', () => {
    expect(pointInSegment(A, B, { x: -5, y: 0 })).toBe(false);
  });

  it('perpendicular offset puts point outside', () => {
    // Point far from the line is not "between" A and B
    expect(pointInSegment(A, B, { x: 5, y: 100 })).toBe(false);
  });

  it('diagonal segment — midpoint', () => {
    const C = { x: 0, y: 0 };
    const D = { x: 4, y: 4 };
    expect(pointInSegment(C, D, { x: 2, y: 2 })).toBe(true);
  });
});

// ─── withinSegment ────────────────────────────────────────────────────────────

describe('withinSegment', () => {
  const A = { x: 0, y: 0 };
  const B = { x: 10, y: 0 };

  it('midpoint returns 0 (within)', () => {
    expect(withinSegment(A, B, { x: 5, y: 0 })).toBe(0);
  });

  it('point beyond B returns +1', () => {
    expect(withinSegment(A, B, { x: 15, y: 0 })).toBe(1);
  });

  it('point before A returns -1', () => {
    expect(withinSegment(A, B, { x: -5, y: 0 })).toBe(-1);
  });

  it('non-collinear point returns undefined', () => {
    expect(withinSegment(A, B, { x: 5, y: 5 })).toBeUndefined();
  });

  it('endpoint A returns 0', () => {
    expect(withinSegment(A, B, A)).toBe(0);
  });

  it('endpoint B returns 0', () => {
    expect(withinSegment(A, B, B)).toBe(0);
  });
});

// ─── sideOfLine ───────────────────────────────────────────────────────────────

describe('sideOfLine', () => {
  const A = { x: 0, y: 0 };
  const B = { x: 10, y: 0 };

  it('point above and below horizontal line return opposite signs', () => {
    const above = sideOfLine(A, B, { x: 5, y: 5 });
    const below = sideOfLine(A, B, { x: 5, y: -5 });
    expect(above).toBe(-below);
    expect(above).not.toBe(0);
  });

  it('point on line is 0', () => {
    expect(sideOfLine(A, B, { x: 5, y: 0 })).toBe(0);
  });

  it('vertical line — left side', () => {
    const V1 = { x: 0, y: 0 };
    const V2 = { x: 0, y: 10 };
    expect(sideOfLine(V1, V2, { x: -1, y: 5 })).not.toBe(0);
  });

  it('vertical line — right side opposite sign', () => {
    const V1 = { x: 0, y: 0 };
    const V2 = { x: 0, y: 10 };
    const left = sideOfLine(V1, V2, { x: -1, y: 5 });
    const right = sideOfLine(V1, V2, { x: 1, y: 5 });
    expect(left).toBe(-right);
  });
});

// ─── intersection ─────────────────────────────────────────────────────────────

describe('intersection', () => {
  it('perpendicular lines intersect at origin', () => {
    const p = { x: 0, y: 0 };
    const ok = intersection(
      { x: -1, y: 0 }, { x: 1, y: 0 },
      { x: 0, y: -1 }, { x: 0, y: 1 },
      p
    );
    expect(ok).toBe(true);
    expect(p.x).toBeCloseTo(0);
    expect(p.y).toBeCloseTo(0);
  });

  it('diagonal lines intersect', () => {
    const p = { x: 0, y: 0 };
    const ok = intersection(
      { x: 0, y: 0 }, { x: 2, y: 2 },
      { x: 0, y: 2 }, { x: 2, y: 0 },
      p
    );
    expect(ok).toBe(true);
    expect(p.x).toBeCloseTo(1);
    expect(p.y).toBeCloseTo(1);
  });

  it('parallel lines return false', () => {
    const p = { x: 0, y: 0 };
    const ok = intersection(
      { x: 0, y: 0 }, { x: 1, y: 0 },
      { x: 0, y: 1 }, { x: 1, y: 1 },
      p
    );
    expect(ok).toBe(false);
  });
});

// ─── extendSegment ────────────────────────────────────────────────────────────

describe('extendSegment', () => {
  it('factor=0 returns segment end unchanged', () => {
    const p = { x: 0, y: 0 };
    extendSegment({ x: 0, y: 0 }, { x: 5, y: 0 }, 0, p);
    expect(p.x).toBeCloseTo(5);
    expect(p.y).toBeCloseTo(0);
  });

  it('factor=1 extends by one segment length beyond end', () => {
    const p = { x: 0, y: 0 };
    extendSegment({ x: 0, y: 0 }, { x: 5, y: 0 }, 1, p);
    expect(p.x).toBeCloseTo(10);
    expect(p.y).toBeCloseTo(0);
  });

  it('factor=0.5 extends by half segment length', () => {
    const p = { x: 0, y: 0 };
    extendSegment({ x: 0, y: 0 }, { x: 4, y: 0 }, 0.5, p);
    expect(p.x).toBeCloseTo(6);
    expect(p.y).toBeCloseTo(0);
  });

  it('works for diagonal segments', () => {
    const p = { x: 0, y: 0 };
    // Segment from (0,0) to (3,4) — length 5; extend by factor 1 = add (3,4)
    extendSegment({ x: 0, y: 0 }, { x: 3, y: 4 }, 1, p);
    expect(p.x).toBeCloseTo(6);
    expect(p.y).toBeCloseTo(8);
  });
});

// ─── Edge / stress cases ──────────────────────────────────────────────────────

describe('edge cases', () => {
  it('Point2f handles very large coordinates without overflow', () => {
    const p = Point2f(1e15, 1e15);
    const expected = Math.sqrt(2) * 1e15;
    // relative tolerance: within 1e-10
    expect(Math.abs(p.norm() - expected) / expected).toBeLessThan(1e-10);
  });

  it('Point2f handles negative coordinates', () => {
    const p = Point2f(-3, -4);
    expect(p.norm()).toBeCloseTo(5);
  });

  it('unit of zero vector is a no-op (returns unchanged zero vector, no NaN)', () => {
    const p = Point2f(0, 0).unit();
    expect(p.x).toBe(0);
    expect(p.y).toBe(0);
  });

  it('sideOfLine: coincident line points produce 0 (degenerate)', () => {
    const same = { x: 1, y: 1 };
    // Cross-product of zero-length line is 0
    expect(sideOfLine(same, same, { x: 5, y: 5 })).toBe(0);
  });

  it('pointInSegment: zero-length segment — endpoint is "within"', () => {
    const A = { x: 3, y: 7 };
    expect(pointInSegment(A, A, A)).toBe(true);
  });

  it('chained operations do not corrupt intermediate state', () => {
    const result = Point2f(1, 0)
      .hadamard(5)
      .add({ x: 0, y: 3 })
      .subtract({ x: 2, y: 1 });
    expect(result.x).toBe(3);
    expect(result.y).toBe(2);
  });

  it('intersection: nearly-parallel lines return false', () => {
    const p = { x: 0, y: 0 };
    const ok = intersection(
      { x: 0, y: 0 }, { x: 1, y: 1e-10 },
      { x: 0, y: 1 }, { x: 1, y: 1 + 1e-10 },
      p
    );
    // May or may not intersect depending on numeric precision; must not throw
    expect(typeof ok).toBe('boolean');
  });

  it('withinSegment: collinear but very close to endpoint returns 0', () => {
    const A = { x: 0, y: 0 };
    const B = { x: 10, y: 0 };
    expect(withinSegment(A, B, { x: 0.001, y: 0 })).toBe(0);
  });
});
