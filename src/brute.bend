# Reference implementations used only to validate the fast algorithms:
# exhaustive enumeration of simple paths, and a negative-cycle test that
# certifies a min-cost flow as optimal.
import Base
import ./graph.bend as G
import ./pareto.bend as P

def app(+xs: List<&2, P.Lab>, +ys: List<&2, P.Lab>) -> List<&2, P.Lab>:
  List.append(&2, P.Lab, xs, ys)

def grow(+l: P.Lab, +a: G.Arc) -> P.Lab:
  P.Lab{c, t, r, p} = l
  P.Lab{(c + G.Arc.cost(a) : F32), (t + G.Arc.hours(a) : F32), (r + G.Arc.risk(a) : F32), G.Arc.id(a) <> p}

# which: 0 = skip the arc, 1 = it reaches dst, 2 = descend through it
def which(+a: G.Arc, +node: U32, +seen: List<&2, U32>, +dst: U32) -> U32:
  +ok = Bool.and(U32.is_eq(G.Arc.src(a), node), Bool.not(G.mem(seen, G.Arc.dst(a))))
  Bool.pick(U32, ok, Bool.pick(U32, U32.is_eq(G.Arc.dst(a), dst), 1, 2), 0)

# Every simple path from node to dst, as labels. fuel bounds the depth.
def paths(+fuel: Nat, +todo: List<&2, G.Arc>, +all: List<&2, G.Arc>, +node: U32,
  +seen: List<&2, U32>, +lab: P.Lab, +dst: U32) -> List<&2, P.Lab>:
  match fuel:
    case 0n:
      []
    case 1n+k:
      match todo:
        case []:
          []
        case a <> rest:
          +w = which(a, node, seen, dst)
          +hit = Bool.pick(List<&2, P.Lab>, U32.is_eq(w, 1), [grow(lab, a)], [])
          # descend only through w = 2; otherwise the call gets no arcs and stops
          +next = Bool.pick(List<&2, G.Arc>, U32.is_eq(w, 2), all, [])
          +deep = paths(k, next, all, G.Arc.dst(a), G.Arc.dst(a) <> seen, grow(lab, a), dst)
          app(hit, app(deep, paths(fuel, rest, all, node, seen, lab, dst)))

def all_paths(+n: Nat, +arcs: List<&2, G.Arc>, +src: U32, +dst: U32) -> List<&2, P.Lab>:
  paths(n, arcs, arcs, src, [src], P.Lab{0.0, 0.0, 0.0, []}, dst)

# Non-dominated subset, sorted by cost: the brute-force Pareto front.
def front(+n: Nat, +arcs: List<&2, G.Arc>, +src: U32, +dst: U32) -> List<&2, P.Lab>:
  List.sort(~P.Lab, ~P.by_cost, P.merge(all_paths(n, arcs, src, dst), []))

# Two fronts agree point by point (cost, hours, risk) within rel tol.
def close(+a: F32, +b: F32) -> Bool:
  (F32.abs((a - b : F32)) <= 1.0e-4 * F32.max(1.0, F32.abs(b)) : F32)

def same_front(+xs: List<&2, P.Lab>, +ys: List<&2, P.Lab>) -> Bool:
  match xs:
    case []:
      List.is_empty(&2, P.Lab, ys)
    case x <> xt:
      match ys:
        case []:
          False{}
        case y <> yt:
          Bool.and(Bool.and(close(P.Lab.c(x), P.Lab.c(y)), Bool.and(close(P.Lab.t(x), P.Lab.t(y)), close(P.Lab.r(x), P.Lab.r(y)))),
            same_front(xt, yt))

def count_dom(+ys: List<&2, P.Lab>, +x: P.Lab) -> U32:
  match ys:
    case []:
      0
    case y <> t:
      (Bool.pick(U32, P.dominates(y, x), 1, 0) + count_dom(t, x) : U32)

# No label of the front dominates another one (each is dominated only by itself).
def none_dominates(+xs: List<&2, P.Lab>, +ys: List<&2, P.Lab>) -> Bool:
  match xs:
    case []:
      True{}
    case x <> t:
      Bool.and(U32.is_eq(count_dom(ys, x), 1), none_dominates(t, ys))
