# Multi-objective shortest paths: every Pareto-optimal (cost, hours, risk)
# path from one source, by label correcting in Bellman-Ford rounds.
#
# All three criteria are additive and non-negative, so every Pareto-optimal
# path is simple (a cycle only adds) and has at most n-1 arcs: n-1 rounds of
# relaxing every arc reach the exact front (Hansen 1980; Martins 1984 is the
# label-setting version). Ties within a relative 1e-5 count as dominated, so
# the front keeps one representative per point.
import Base
import ./graph.bend as G

# path: arc ids, last arc first
type Lab is Data:
  Lab{c: F32, t: F32, r: F32, path: List<&2, U32>}

def Lab.c(+l: Lab) -> F32:
  Lab{c, t, r, p} = l
  c

def Lab.t(+l: Lab) -> F32:
  Lab{c, t, r, p} = l
  t

def Lab.r(+l: Lab) -> F32:
  Lab{c, t, r, p} = l
  r

# arc ids from first to last
def Lab.arcs(+l: Lab) -> List<&2, U32>:
  Lab{c, t, r, p} = l
  List.reverse(&2, U32, p)

def le(+a: F32, +b: F32) -> Bool:
  (a <= b + 1.0e-5 * F32.abs(b) + 1.0e-6 : F32)

def dominates(+a: Lab, +b: Lab) -> Bool:
  Bool.and(le(Lab.c(a), Lab.c(b)), Bool.and(le(Lab.t(a), Lab.t(b)), le(Lab.r(a), Lab.r(b))))

def any_dom(+xs: List<&2, Lab>, +b: Lab) -> Bool:
  match xs:
    case []:
      False{}
    case a <> t:
      Bool.or(dominates(a, b), any_dom(t, b))

def keep_if(+keep: Bool, +x: Lab, +rest: List<&2, Lab>) -> List<&2, Lab>:
  match keep:
    case True{}:
      x <> rest
    case False{}:
      rest

def drop_dominated(+xs: List<&2, Lab>, +a: Lab) -> List<&2, Lab>:
  match xs:
    case []:
      []
    case b <> t:
      keep_if(Bool.not(dominates(a, b)), b, drop_dominated(t, a))

def insert_if(+dom: Bool, +front: List<&2, Lab>, +a: Lab) -> List<&2, Lab>:
  match dom:
    case True{}:
      front
    case False{}:
      a <> drop_dominated(front, a)

def insert(+front: List<&2, Lab>, +a: Lab) -> List<&2, Lab>:
  insert_if(any_dom(front, a), front, a)

def merge(+cands: List<&2, Lab>, +front: List<&2, Lab>) -> List<&2, Lab>:
  match cands:
    case []:
      front
    case a <> t:
      merge(t, insert(front, a))

def extend(+ls: List<&2, Lab>, +a: G.Arc) -> List<&2, Lab>:
  match ls:
    case []:
      []
    case Lab{c, t, r, p} <> rest:
      Lab{(c + G.Arc.cost(a) : F32), (t + G.Arc.hours(a) : F32), (r + G.Arc.risk(a) : F32),
        G.Arc.id(a) <> p} <> extend(rest, a)

# ---- per-node label table ----

def get(+tb: List<&2, List<&2, Lab>>, +i: Nat) -> List<&2, Lab>:
  match tb:
    case []:
      []
    case h <> t:
      match i:
        case 0n:
          h
        case 1n+k:
          get(t, k)

def put(+tb: List<&2, List<&2, Lab>>, +i: Nat, +v: List<&2, Lab>) -> List<&2, List<&2, Lab>>:
  match tb:
    case []:
      []
    case h <> t:
      match i:
        case 0n:
          v <> t
        case 1n+k:
          h <> put(t, k, v)

def relax(+arcs: List<&2, G.Arc>, +tb: List<&2, List<&2, Lab>>) -> List<&2, List<&2, Lab>>:
  match arcs:
    case []:
      tb
    case a <> rest:
      +d = U32.to_nat(G.Arc.dst(a))
      +cands = extend(get(tb, U32.to_nat(G.Arc.src(a))), a)
      relax(rest, put(tb, d, merge(cands, get(tb, d))))

def rounds(+n: Nat, +arcs: List<&2, G.Arc>, +tb: List<&2, List<&2, Lab>>) -> List<&2, List<&2, Lab>>:
  match n:
    case 0n:
      tb
    case 1n+k:
      rounds(k, arcs, relax(arcs, tb))

def by_cost(a: Lab, b: Lab) -> Bool:
  Lab{ca, ta, ra, pa} = a
  Lab{cb, tb, rb, pb} = b
  (ca <= cb : F32)

# Pareto front at every node, for a graph with nodes 0..n-1.
def table(+n: Nat, +arcs: List<&2, G.Arc>, +src: U32) -> List<&2, List<&2, Lab>>:
  +empty = List.replicate(List<&2, Lab>, n, [])
  rounds(n, arcs, put(empty, U32.to_nat(src), [Lab{0.0, 0.0, 0.0, []}]))

# Pareto front at dst, sorted by increasing cost.
def front(+n: Nat, +arcs: List<&2, G.Arc>, +src: U32, +dst: U32) -> List<&2, Lab>:
  List.sort(~Lab, ~by_cost, get(table(n, arcs, src), U32.to_nat(dst)))

# P(at least one interruption) from the additive risk.
def p_any(+r: F32) -> F32:
  (1.0 - F32.exp((0.0 - r : F32)) : F32)
