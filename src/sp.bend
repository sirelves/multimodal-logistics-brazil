# Single-objective shortest path (Bellman-Ford) on a generalized cost
#   g(arc) = wc * cost + wt * hours + wr * risk
# Negative arc weights are allowed (residual arcs in the flow model), as long
# as there is no negative cycle, which min-cost flow guarantees.
import Base
import ./graph.bend as G

type Weights is Data:
  Weights{wc: F32, wt: F32, wr: F32}

def gcost(+w: Weights, +a: G.Arc) -> F32:
  Weights{wc, wt, wr} = w
  (wc * G.Arc.cost(a) + wt * G.Arc.hours(a) + wr * G.Arc.risk(a) : F32)

type DP is Data:
  DP{dist: List<&2, F32>, pred: List<&2, U32>}

def DP.dist(+x: DP) -> List<&2, F32>:
  DP{d, p} = x
  d

def DP.pred(+x: DP) -> List<&2, U32>:
  DP{d, p} = x
  p

def better(+nd: F32, +old: F32) -> Bool:
  (nd < old - 1.0e-5 * F32.abs(old) - 1.0e-6 : F32)

def relax_one(+x: DP, +a: G.Arc, +nd: F32, +d: Nat, +go: Bool) -> DP:
  match go:
    case True{}:
      DP{G.set_f(DP.dist(x), d, nd), G.set_u(DP.pred(x), d, G.Arc.id(a))}
    case False{}:
      x

def relax(+arcs: List<&2, G.Arc>, +w: Weights, +x: DP) -> DP:
  match arcs:
    case []:
      x
    case a <> rest:
      +du = G.nth_f(DP.dist(x), U32.to_nat(G.Arc.src(a)))
      +d = U32.to_nat(G.Arc.dst(a))
      +nd = (du + gcost(w, a) : F32)
      +go = Bool.and((du < 1.0e29 : F32), better(nd, G.nth_f(DP.dist(x), d)))
      relax(rest, w, relax_one(x, a, nd, d, go))

def rounds(+n: Nat, +arcs: List<&2, G.Arc>, +w: Weights, +x: DP) -> DP:
  match n:
    case 0n:
      x
    case 1n+k:
      rounds(k, arcs, w, relax(arcs, w, x))

def run(+n: Nat, +arcs: List<&2, G.Arc>, +w: Weights, +src: U32) -> DP:
  rounds(n, arcs, w, DP{G.set_f(G.fill_f(n, G.inf()), U32.to_nat(src), 0.0), G.fill_u(n, G.none())})

# The arc that last improved v, if any.
def pred_arc(+arcs: List<&2, G.Arc>, +pred: List<&2, U32>, +v: U32) -> Maybe<&2, G.Arc>:
  +pa = G.nth_u(pred, U32.to_nat(v))
  Bool.pick(Maybe<&2, G.Arc>, U32.is_eq(pa, G.none()), None{}, G.arc_at(arcs, pa))

# Arc ids from the source to the arc m, following pred; fuel bounds the walk.
def back(+fuel: Nat, +arcs: List<&2, G.Arc>, +pred: List<&2, U32>, +m: Maybe<&2, G.Arc>, +acc: List<&2, U32>) -> List<&2, U32>:
  match fuel:
    case 0n:
      acc
    case 1n+k:
      match m:
        case None{}:
          acc
        case Some{a}:
          back(k, arcs, pred, pred_arc(arcs, pred, G.Arc.src(a)), G.Arc.id(a) <> acc)

type Route is Data:
  Route{g: F32, arcs: List<&2, U32>}

def Route.g(+r: Route) -> F32:
  Route{g, a} = r
  g

def Route.arcs(+r: Route) -> List<&2, U32>:
  Route{g, a} = r
  a

# Shortest route src -> dst; g = inf and no arcs when dst is unreachable.
def route(+n: Nat, +arcs: List<&2, G.Arc>, +w: Weights, +src: U32, +dst: U32) -> Route:
  +x = run(n, arcs, w, src)
  +g = G.nth_f(DP.dist(x), U32.to_nat(dst))
  Route{g, Bool.pick(List<&2, U32>, (g < 1.0e29 : F32), back(n, arcs, DP.pred(x), pred_arc(arcs, DP.pred(x), dst), []), [])}
