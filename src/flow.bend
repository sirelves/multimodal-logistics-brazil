# Capacitated allocation: ship `supply` kt/month from src to dst at minimum
# total generalized cost, by successive shortest paths on the residual graph
# (Ahuja, Magnanti & Orlin 1993, ch. 9). Arc costs are linear, so the result
# is the exact min-cost flow; each augmentation saturates an arc or meets the
# demand, so the number of rounds is bounded by (arcs + 1).
#
# Residual arc ids: 2*id forward (remaining capacity), 2*id+1 backward
# (undo flow, negated cost / hours / risk).
import Base
import ./graph.bend as G
import ./sp.bend as SP

def eps() -> F32:
  1.0e-3

def residual(+arcs: List<&2, G.Arc>, +flow: List<&2, F32>) -> List<&2, G.Arc>:
  match arcs:
    case []:
      []
    case G.Arc{id, s, d, m, c, h, r, k} <> rest:
      +f = G.nth_f(flow, U32.to_nat(id))
      G.cons_if((k - f > eps() : F32), G.Arc{(2 * id : U32), s, d, m, c, h, r, (k - f : F32)},
        G.cons_if((f > eps() : F32), G.Arc{(2 * id + 1 : U32), d, s, m, (0.0 - c : F32), (0.0 - h : F32), (0.0 - r : F32), f},
          residual(rest, flow)))

def bottleneck(+res: List<&2, G.Arc>, +ids: List<&2, U32>, +acc: F32) -> F32:
  match ids:
    case []:
      acc
    case i <> rest:
      +k = Maybe.default(&2, G.Arc, G.arc_at(res, i), G.Arc{0, 0, 0, 0, 0.0, 0.0, 0.0, 0.0})
      bottleneck(res, rest, F32.min(acc, G.Arc.cap(k)))

def push(+ids: List<&2, U32>, +delta: F32, +flow: List<&2, F32>) -> List<&2, F32>:
  match ids:
    case []:
      flow
    case i <> rest:
      +a = U32.to_nat(U32.shrn(i, 1n))
      +f = G.nth_f(flow, a)
      +nf = Bool.pick(F32, U32.is_even(i), (f + delta : F32), (f - delta : F32))
      push(rest, delta, G.set_f(flow, a, nf))

# stop: no augmenting path left, or the demand is met
type Alloc is Data:
  Alloc{flow: List<&2, F32>, shipped: F32, marginal: F32, left: F32, stop: Bool}

def Alloc.flow(+x: Alloc) -> List<&2, F32>:
  Alloc{f, s, m, l, st} = x
  f

def Alloc.shipped(+x: Alloc) -> F32:
  Alloc{f, s, m, l, st} = x
  s

# generalized cost of the last unit shipped, R$/t (inf if demand not met)
def Alloc.marginal(+x: Alloc) -> F32:
  Alloc{f, s, m, l, st} = x
  Bool.pick(F32, (l <= eps() : F32), m, G.inf())

# One successive-shortest-path augmentation.
def step(+n: Nat, +arcs: List<&2, G.Arc>, +w: SP.Weights, +src: U32, +dst: U32, +x: Alloc) -> Alloc:
  Alloc{flow, shipped, marg, left, st} = x
  +res = residual(arcs, flow)
  +rt = SP.route(n, res, w, src, dst)
  +ids = SP.Route.arcs(rt)
  +empty = List.is_empty(&2, U32, ids)
  +delta = F32.min(left, bottleneck(res, ids, G.inf()))
  +left2 = (left - delta : F32)
  Bool.pick(Alloc, empty, Alloc{flow, shipped, marg, left, True{}},
    Alloc{push(ids, delta, flow), (shipped + delta : F32), SP.Route.g(rt), left2, (left2 <= eps() : F32)})

def augment(+fuel: Nat, +n: Nat, +arcs: List<&2, G.Arc>, +w: SP.Weights, +src: U32, +dst: U32,
  +x: Alloc) -> Alloc:
  match fuel:
    case 0n:
      x
    case 1n+k:
      match x:
        case Alloc{f, s, m, l, st}:
          match st:
            case True{}:
              Alloc{f, s, m, l, True{}}
            case False{}:
              augment(k, n, arcs, w, src, dst, step(n, arcs, w, src, dst, Alloc{f, s, m, l, False{}}))

# arc ids must be 0..m-1 (the network's leg ids)
def solve(+n: Nat, +m: Nat, +arcs: List<&2, G.Arc>, +w: SP.Weights, +src: U32, +dst: U32,
  +supply: F32) -> Alloc:
  augment(Nat.add(m, 2n), n, arcs, w, src, dst,
    Alloc{G.fill_f(m, 0.0), 0.0, 0.0, supply, (supply <= eps() : F32)})

# total generalized cost of a flow, in kt * R$/t = thousand R$
def total(+arcs: List<&2, G.Arc>, +w: SP.Weights, +flow: List<&2, F32>) -> F32:
  match arcs:
    case []:
      0.0
    case a <> rest:
      (G.nth_f(flow, U32.to_nat(G.Arc.id(a))) * SP.gcost(w, a) + total(rest, w, flow) : F32)

# flow leaving src by mode of the arc it rides through `mode`, summed over arcs of that mode
def by_mode(+arcs: List<&2, G.Arc>, +flow: List<&2, F32>, +mode: U32) -> F32:
  match arcs:
    case []:
      0.0
    case a <> rest:
      +here = Bool.pick(F32, U32.is_eq(G.Arc.mode(a), mode), G.nth_f(flow, U32.to_nat(G.Arc.id(a))), 0.0)
      (here + by_mode(rest, flow, mode) : F32)

# flow on one arc id
def on(+flow: List<&2, F32>, +id: U32) -> F32:
  G.nth_f(flow, U32.to_nat(id))

# ---- optimality certificate ----
# A feasible flow is min-cost iff its residual graph has no negative cycle
# (Ahuja et al. 1993, thm 9.1). Bellman-Ford from a virtual source (every
# distance 0): after n rounds, any arc that still relaxes lies on or behind one.

def still_relaxes(+arcs: List<&2, G.Arc>, +w: SP.Weights, +dist: List<&2, F32>) -> Bool:
  match arcs:
    case []:
      False{}
    case a <> rest:
      +nd = (G.nth_f(dist, U32.to_nat(G.Arc.src(a))) + SP.gcost(w, a) : F32)
      Bool.or(SP.better(nd, G.nth_f(dist, U32.to_nat(G.Arc.dst(a)))), still_relaxes(rest, w, dist))

def neg_cycle(+n: Nat, +res: List<&2, G.Arc>, +w: SP.Weights) -> Bool:
  +x = SP.rounds(n, res, w, SP.DP{G.fill_f(n, 0.0), G.fill_u(n, G.none())})
  still_relaxes(res, w, SP.DP.dist(x))

def optimal(+n: Nat, +arcs: List<&2, G.Arc>, +w: SP.Weights, +flow: List<&2, F32>) -> Bool:
  Bool.not(neg_cycle(n, residual(arcs, flow), w))

# net outflow at node v (out - in)
def net_out(+arcs: List<&2, G.Arc>, +flow: List<&2, F32>, +v: U32) -> F32:
  match arcs:
    case []:
      0.0
    case a <> rest:
      +f = G.nth_f(flow, U32.to_nat(G.Arc.id(a)))
      +o = Bool.pick(F32, U32.is_eq(G.Arc.src(a), v), f, 0.0)
      +i = Bool.pick(F32, U32.is_eq(G.Arc.dst(a), v), f, 0.0)
      (o - i + net_out(rest, flow, v) : F32)

def within_caps(+arcs: List<&2, G.Arc>, +flow: List<&2, F32>) -> Bool:
  match arcs:
    case []:
      True{}
    case a <> rest:
      +f = G.nth_f(flow, U32.to_nat(G.Arc.id(a)))
      Bool.and(Bool.and((f >= 0.0 - eps() : F32), (f <= G.Arc.cap(a) + eps() : F32)), within_caps(rest, flow))

# flow is conserved at every node but src and dst (nodes 0..n-1)
def conserved(+n: Nat, +arcs: List<&2, G.Arc>, +flow: List<&2, F32>, +src: U32, +dst: U32) -> Bool:
  match n:
    case 0n:
      True{}
    case 1n+k:
      +v = U32.from_nat(k)
      +end = Bool.or(U32.is_eq(v, src), U32.is_eq(v, dst))
      Bool.and(Bool.or(end, (F32.abs(net_out(arcs, flow, v)) < 0.01 : F32)), conserved(k, arcs, flow, src, dst))
