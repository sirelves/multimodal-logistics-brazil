# Interruptions: Monte Carlo over independent leg failures.
#
# A leg of mode m fails on a trip with probability p = 1 - exp(-risk); a
# failure costs an exponential delay with mean P.delay(m), valued at P.stall(m).
# Randomness is a stateless hash of (scenario, leg, salt), so scenarios are
# independent pure calls and the scenario tree runs as parallel calls.
#
# Policies for one shipment:
#   fixed    follow a planned route; wait out every failure
#   adaptive follow the expected-cost route; at the first failure, knowing its
#            duration, either wait or pay P.reroute_fee() and re-plan from the
#            failed leg's origin on the graph without that leg (later
#            failures on either route are waited out)
import Base
import ./graph.bend as G
import ./sp.bend as SP
import ./params.bend as P

# ---- randomness ----

# lowbias32 (C. Wellons), a 32-bit integer hash with good avalanche
def mix(+x: U32) -> U32:
  +a = (x .^. U32.shrn(x, 16n) : U32)
  +b = (a * 2146121005 : U32)
  +c = (b .^. U32.shrn(b, 15n) : U32)
  +d = (c * 2221713035 : U32)
  (d .^. U32.shrn(d, 16n) : U32)

# uniform in (0, 1)
def unif(+seed: U32, +leg: U32, +salt: U32) -> F32:
  +h = mix((mix((seed * 2654435769 + salt : U32)) .^. (leg * 2246822519 + 374761393 : U32) : U32))
  ((U32.to_f32(U32.shrn(h, 8n)) + 0.5) / 16777216.0 : F32)

def p_fail(+a: G.Arc) -> F32:
  (1.0 - F32.exp((0.0 - G.Arc.risk(a) : F32)) : F32)

def fails(+seed: U32, +a: G.Arc, +salt: U32) -> Bool:
  (unif(seed, G.Arc.id(a), salt) < p_fail(a) : F32)

# delay hours given that the leg failed
def delay(+seed: U32, +a: G.Arc, +salt: U32) -> F32:
  (0.0 - P.delay(G.Arc.mode(a)) * F32.log(unif(seed, G.Arc.id(a), (salt + 7919 : U32))) : F32)

# ---- expected-cost view ----

# nominal generalized cost of a leg, R$/t
def nominal(+a: G.Arc) -> F32:
  (G.Arc.cost(a) + P.vot() * G.Arc.hours(a) : F32)

# expected extra cost from failures of a leg, R$/t
def penalty(+a: G.Arc) -> F32:
  (p_fail(a) * P.stall(G.Arc.mode(a)) * P.delay(G.Arc.mode(a)) : F32)

# The same graph with cost = nominal + expected failure penalty, so a plain
# shortest path minimizes the exact expected cost of a fixed route
# (linearity of expectation; no independence needed).
def expected_arcs(+as: List<&2, G.Arc>) -> List<&2, G.Arc>:
  match as:
    case []:
      []
    case a <> rest:
      G.Arc{id, s, d, m, c, h, r, k} = a
      G.Arc{id, s, d, m, (nominal(a) + penalty(a) : F32), 0.0, 0.0, k} <> expected_arcs(rest)

def cost_only() -> SP.Weights:
  SP.Weights{1.0, 0.0, 0.0}

def expected_cost(+route: List<&2, G.Arc>) -> F32:
  match route:
    case []:
      0.0
    case a <> rest:
      (nominal(a) + penalty(a) + expected_cost(rest) : F32)

def nominal_cost(+route: List<&2, G.Arc>) -> F32:
  match route:
    case []:
      0.0
    case a <> rest:
      (nominal(a) + nominal_cost(rest) : F32)

# ---- one sampled trip ----

# fixed policy: nominal cost plus every sampled failure delay
def fixed(+seed: U32, +route: List<&2, G.Arc>, +salt: U32) -> F32:
  match route:
    case []:
      0.0
    case a <> rest:
      +pen = Bool.pick(F32, fails(seed, a, salt), (P.stall(G.Arc.mode(a)) * delay(seed, a, salt) : F32), 0.0)
      (nominal(a) + pen + fixed(seed, rest, salt) : F32)

type Plan is Data:
  Plan{n: Nat, all: List<&2, G.Arc>, dst: U32}

def replan(+pl: Plan, +a: G.Arc) -> List<&2, G.Arc>:
  Plan{n, all, dst} = pl
  +ex = expected_arcs(G.without(all, G.Arc.id(a)))
  +rt = SP.route(n, ex, cost_only(), G.Arc.src(a), dst)
  G.pick_arcs(all, SP.Route.arcs(rt))

# cost of re-planning at the failed leg a (inf if nothing else reaches dst)
def detour_cost(+alt: List<&2, G.Arc>) -> F32:
  Bool.pick(F32, List.is_empty(&2, G.Arc, alt), G.inf(), (P.reroute_fee() + expected_cost(alt) : F32))

# at a failure of a: wait (sampled delay, then the rest) or detour, whichever
# is cheaper in expectation given the now-known delay; then sample the choice
def decide(+seed: U32, +pl: Plan, +a: G.Arc, +rest: List<&2, G.Arc>) -> F32:
  +d = (P.stall(G.Arc.mode(a)) * delay(seed, a, 1) : F32)
  +alt = replan(pl, a)
  +wait_exp = (d + nominal(a) + expected_cost(rest) : F32)
  +wait_real = (d + nominal(a) + fixed(seed, rest, 1) : F32)
  +go_real = (P.reroute_fee() + fixed(seed, alt, 2) : F32)
  Bool.pick(F32, (detour_cost(alt) < wait_exp : F32), go_real, wait_real)

# The trip up to its first failure: nominal cost so far, the failed leg (if
# any) and the legs after it.
type Split is Data:
  Split{cost: F32, failed: Maybe<&2, G.Arc>, rest: List<&2, G.Arc>}

def prepend(+a: G.Arc, +failed: Bool, +rest: List<&2, G.Arc>, +sub: Split) -> Split:
  Split{c, f, r} = sub
  Bool.pick(Split, failed, Split{0.0, Some{a}, rest}, Split{(nominal(a) + c : F32), f, r})

def split(+seed: U32, +route: List<&2, G.Arc>) -> Split:
  match route:
    case []:
      Split{0.0, None{}, []}
    case a <> rest:
      prepend(a, fails(seed, a, 1), rest, split(seed, rest))

def after(+seed: U32, +pl: Plan, +f: Maybe<&2, G.Arc>, +rest: List<&2, G.Arc>) -> F32:
  match f:
    case None{}:
      0.0
    case Some{a}:
      decide(seed, pl, a, rest)

def finish(+seed: U32, +pl: Plan, +sp: Split) -> F32:
  Split{c, f, r} = sp
  (c + after(seed, pl, f, r) : F32)

def adaptive(+seed: U32, +pl: Plan, +route: List<&2, G.Arc>) -> F32:
  finish(seed, pl, split(seed, route))

# ---- scenario tree ----

# costs of one trip under each policy, R$/t
type Out is Data:
  Out{fixed: F32, adaptive: F32}

def Out.fixed(+o: Out) -> F32:
  Out{f, a} = o
  f

def Out.adaptive(+o: Out) -> F32:
  Out{f, a} = o
  a

type Job is Data:
  Job{plan: Plan, fixed_route: List<&2, G.Arc>, adaptive_route: List<&2, G.Arc>}

def trip(+job: Job, +seed: U32) -> Out:
  Job{pl, fr, ar} = job
  Out{fixed(seed, fr, 1), adaptive(seed, pl, ar)}

# 2^depth scenarios with seeds base*2^depth .. ; the two halves run in parallel
def tree(+depth: Nat, +job: Job, +seed: U32) -> List<&2, Out>:
  match depth:
    case 0n:
      [trip(job, seed)]
    case 1n+k:
      l r = tree(k, job, (seed * 2 : U32)) tree(k, job, (seed * 2 + 1 : U32))
      List.append(&2, Out, l, r)

# ---- statistics ----

def firsts(+os: List<&2, Out>) -> List<&2, F32>:
  match os:
    case []:
      []
    case o <> t:
      Out.fixed(o) <> firsts(t)

def seconds(+os: List<&2, Out>) -> List<&2, F32>:
  match os:
    case []:
      []
    case o <> t:
      Out.adaptive(o) <> seconds(t)

def fle(a: F32, b: F32) -> Bool:
  (a <= b : F32)

def sort(+xs: List<&2, F32>) -> List<&2, F32>:
  List.sort(~F32, ~fle, xs)

type Stats is Data:
  Stats{mean: F32, p95: F32, cvar95: F32, pmax: F32}

def mean(+xs: List<&2, F32>) -> F32:
  (G.sum_f(xs) / F32.from_nat(List.length(&2, F32, xs)) : F32)

def last(+xs: List<&2, F32>) -> F32:
  Maybe.default(&2, F32, List.last(&2, F32, xs), 0.0)

# xs ascending; tail = the worst 5 %
def stats(+xs: List<&2, F32>) -> Stats:
  +n = List.length(&2, F32, xs)
  +k = Nat.sub(n, Nat.max(1n, Nat.div(n, 20n)))
  +tail = List.drop(&2, F32, xs, k)
  Stats{mean(xs), G.nth_f(xs, k), mean(tail), last(xs)}

def Stats.mean(+s: Stats) -> F32:
  Stats{m, p, c, x} = s
  m

def Stats.p95(+s: Stats) -> F32:
  Stats{m, p, c, x} = s
  p

def Stats.cvar95(+s: Stats) -> F32:
  Stats{m, p, c, x} = s
  c

def Stats.pmax(+s: Stats) -> F32:
  Stats{m, p, c, x} = s
  x
