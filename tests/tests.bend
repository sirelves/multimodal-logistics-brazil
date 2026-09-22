# Automated checks. Exit code 1 if any check fails.
#   bend tests/tests.bend
import Base
import ../src/graph.bend as G
import ../src/pareto.bend as P
import ../src/sp.bend as SP
import ../src/flow.bend as F
import ../src/risk.bend as K
import ../src/brute.bend as B
import ../src/season.bend as S
import ../src/params.bend as Q
import ../src/network.bend as N

type Check is Data:
  Check{ok: Bool, msg: String}

def near(+name: String, +got: F32, +want: F32, +tol: F32) -> Check:
  +err = (F32.abs((got - want : F32)) / F32.max(F32.abs(want), 1.0e-30) : F32)
  Check{(err < tol : F32), name ++ ": got " ++ F32.show(got) ++ ", expected " ++ F32.show(want) ++ " (rel tol " ++ F32.show(tol) ++ ")"}

def truth(+name: String, +b: Bool) -> Check:
  Check{b, name}

# ---- toy graph (hand-checked) ----
#   0 -a0-> 1 -a1-> 3        cost 20, 10 h, fast and expensive
#   0 -a2-> 2 -a3-> 3        cost 10, 40 h, slow and cheap
#   1 -a4-> 2                links them: 0-1-2-3 costs 16, 26 h
def toy() -> List<&2, G.Arc>:
  [G.Arc{0, 0, 1, 0, 10.0, 5.0, 0.01, 5.0},
   G.Arc{1, 1, 3, 0, 10.0, 5.0, 0.01, 5.0},
   G.Arc{2, 0, 2, 1, 5.0, 20.0, 0.05, 10.0},
   G.Arc{3, 2, 3, 1, 5.0, 20.0, 0.05, 10.0},
   G.Arc{4, 1, 2, 2, 1.0, 1.0, 0.0, 10.0}]

def costs(+ls: List<&2, P.Lab>) -> List<&2, F32>:
  match ls:
    case []:
      []
    case l <> t:
      P.Lab.c(l) <> costs(t)

def same_fs(+xs: List<&2, F32>, +ys: List<&2, F32>) -> Bool:
  match xs:
    case []:
      List.is_empty(&2, F32, ys)
    case x <> xt:
      match ys:
        case []:
          False{}
        case y <> yt:
          Bool.and(B.close(x, y), same_fs(xt, yt))

# ---- Brazil network ----

def nn() -> Nat:
  N.n_nodes()

def drought() -> N.Scenario:
  N.drought()

def everything() -> N.Scenario:
  N.with_drought(N.rails())

def blocked163() -> N.Scenario:
  N.with_blocked(N.base(), [3])

def pareto_vs_brute(+label: String, +m: U32, +sc: N.Scenario) -> Check:
  +a = N.arcs(m, sc)
  +fast = P.front(nn(), a, N.SOR(), N.CHN())
  +slow = B.front(nn(), a, N.SOR(), N.CHN())
  truth("Pareto front == brute-force enumeration of simple paths [" ++ label ++ ", "
    ++ Nat.show(List.length(&2, P.Lab, fast)) ++ " labels]",
    Bool.and(B.same_front(fast, slow), B.none_dominates(fast, fast)))

def min_by(+ls: List<&2, P.Lab>, +w: SP.Weights, +best: F32) -> F32:
  match ls:
    case []:
      best
    case l <> t:
      SP.Weights{wc, wt, wr} = w
      min_by(t, w, F32.min(best, (wc * P.Lab.c(l) + wt * P.Lab.t(l) + wr * P.Lab.r(l) : F32)))

# the front contains the optimum of every positive scalarization
def scalar_on_front(+label: String, +m: U32, +w: SP.Weights) -> Check:
  +a = N.arcs(m, N.base())
  +fr = P.front(nn(), a, N.SOR(), N.CHN())
  near("front minimum == Bellman-Ford optimum [" ++ label ++ "]", min_by(fr, w, G.inf()),
    SP.Route.g(SP.route(nn(), a, w, N.SOR(), N.CHN())), 0.00001)

# consecutive legs change mode only through a transfer leg
def modes_ok(+all: List<&2, G.Arc>, +ids: List<&2, U32>) -> Bool:
  match ids:
    case []:
      True{}
    case i <> rest:
      match rest:
        case []:
          True{}
        case j <> more:
          +mi = G.Arc.mode(Maybe.default(&2, G.Arc, G.arc_at(all, i), G.Arc{0, 0, 0, 9, 0.0, 0.0, 0.0, 0.0}))
          +mj = G.Arc.mode(Maybe.default(&2, G.Arc, G.arc_at(all, j), G.Arc{0, 0, 0, 9, 0.0, 0.0, 0.0, 0.0}))
          +x = Q.XFER()
          Bool.and(Bool.or(U32.is_eq(mi, mj), Bool.or(U32.is_eq(mi, x), U32.is_eq(mj, x))), modes_ok(all, rest))

def fronts_modes_ok(+all: List<&2, G.Arc>, +ls: List<&2, P.Lab>) -> Bool:
  match ls:
    case []:
      True{}
    case l <> t:
      Bool.and(modes_ok(all, P.Lab.arcs(l)), fronts_modes_ok(all, t))

def gen() -> SP.Weights:
  SP.Weights{1.0, Q.vot(), 0.0}

def flow_checks(+label: String, +m: U32, +sc: N.Scenario, +supply: F32) -> List<&2, Check>:
  +a = N.arcs(m, sc)
  +r = F.solve(nn(), N.n_legs(), a, gen(), N.SOR(), N.CHN(), supply)
  +fl = F.Alloc.flow(r)
  +sh = F.Alloc.shipped(r)
  [truth("flow within capacities [" ++ label ++ "]", F.within_caps(a, fl)),
   truth("flow conserved at every inner node [" ++ label ++ "]", F.conserved(nn(), a, fl, N.SOR(), N.CHN())),
   near("flow leaving the origin == shipped [" ++ label ++ "]", F.net_out(a, fl, N.SOR()), sh, 0.0001),
   truth("min-cost certificate: no negative cycle in the residual graph [" ++ label ++ ", shipped "
     ++ F32.show(sh) ++ " kt]", F.optimal(nn(), a, gen(), fl))]

def mc_route(+m: U32, +sc: N.Scenario) -> List<&2, G.Arc>:
  +a = N.arcs(m, sc)
  G.pick_arcs(a, SP.Route.arcs(SP.route(nn(), K.expected_arcs(a), K.cost_only(), N.SOR(), N.CHN())))

def mc_job(+m: U32, +sc: N.Scenario) -> K.Job:
  K.Job{K.Plan{nn(), N.arcs(m, sc), N.CHN()}, mc_route(m, sc), mc_route(m, sc)}

def unifs(+n: Nat, +i: U32) -> List<&2, F32>:
  match n:
    case 0n:
      []
    case 1n+k:
      K.unif(i, 7, 3) <> unifs(k, (i + 1 : U32))

def below(+xs: List<&2, F32>, +c: F32) -> List<&2, F32>:
  match xs:
    case []:
      []
    case x <> t:
      Bool.pick(F32, (x < c : F32), 1.0, 0.0) <> below(t, c)

def frac_below(+xs: List<&2, F32>, +c: F32) -> F32:
  (K.mean(below(xs, c)) : F32)

def has_leg(+a: List<&2, G.Arc>, +id: U32) -> Bool:
  Maybe.is_some(&2, G.Arc, G.arc_at(a, id))

def risk_checks(+m: U32, +sc: N.Scenario) -> List<&2, Check>:
  +os = K.tree(14n, mc_job(m, sc), 1)
  +fx = K.mean(K.firsts(os))
  +ad = K.mean(K.seconds(os))
  [near("Monte Carlo mean (fixed route, 2^14 trips) == exact expected cost [month " ++ U32.show(m) ++ "]",
     fx, K.expected_cost(mc_route(m, sc)), 0.003),
   truth("adaptive re-planning does not raise the mean cost [month " ++ U32.show(m) ++ ": "
     ++ F32.show(ad) ++ " vs " ++ F32.show(fx) ++ "]", (ad <= fx * 1.001 : F32))]

def checks() -> List<&2, Check>:
  +u = unifs(20000n, 1)
  +toyf = P.front(4n, toy(), 0, 3)
  +toyflow = F.solve(4n, 5n, toy(), SP.Weights{1.0, 0.0, 0.0}, 0, 3, 12.0)
  +toymax = F.solve(4n, 5n, toy(), SP.Weights{1.0, 0.0, 0.0}, 0, 3, 40.0)
  List.concat(&2, Check,
   [[truth("toy: front costs are 10, 16, 20", same_fs(costs(toyf), [10.0, 16.0, 20.0])),
     truth("toy: Pareto == brute force", B.same_front(toyf, B.front(4n, toy(), 0, 3))),
     # 0-2-3 (10/t) fills a3 (cap 10); 0-1-2-3 then needs a3 too, so the next is 0-1-3 (20/t)
     near("toy flow: 12 units cost 10*10 + 2*20", F.total(toy(), SP.Weights{1.0, 0.0, 0.0}, F.Alloc.flow(toyflow)), 140.0, 0.00001),
     near("toy flow: marginal cost of the 12th unit = 20", F.Alloc.marginal(toyflow), 20.0, 0.00001),
     # max flow: a2 (10) + a0 (5) out of the source
     near("toy flow: demand 40 ships the max flow 15", F.Alloc.shipped(toymax), 15.0, 0.00001),
     truth("toy flow: unmet demand gives an infinite marginal cost", (F.Alloc.marginal(toymax) > 1.0e29 : F32)),
     near("hash: mean of 20000 uniforms = 1/2", K.mean(u), 0.5, 0.01),
     near("hash: P(u < 0.1) = 0.1", frac_below(u, 0.1), 0.1, 0.05),
     truth("season: Dec-Mar window wraps (Jan in, Jun out)", Bool.and(S.within(0, 11, 2), Bool.not(S.within(5, 11, 2)))),
     truth("season: no effect bits = identity factor", Bool.and(F32.is_eq(S.SF.cmul(S.factor(0, 3, True{})), 1.0), F32.is_eq(S.SF.tadd(S.factor(0, 3, True{})), 0.0))),
     truth("drought closes the Madeira barge in Oct, not in Jun", Bool.and(Bool.not(has_leg(N.arcs(9, drought()), 18)), has_leg(N.arcs(5, drought()), 18))),
     truth("normal year keeps the Madeira barge open in Oct", has_leg(N.arcs(9, N.base()), 18)),
     truth("base network has 37 legs, with both railways 42", Bool.and(Nat.is_eq(List.length(&2, G.Arc, N.arcs(5, N.base())), 37n),
       Nat.is_eq(List.length(&2, G.Arc, N.arcs(5, N.rails())), 42n))),
     truth("per-origin supply caps reach the flow model", Bool.and(
       F32.is_eq(G.Arc.cap(Maybe.default(&2, G.Arc, G.arc_at(N.set_supply(N.arcs(5, N.base()), 100.0, 50.0, 25.0), 31), G.Arc{0, 0, 0, 0, 0.0, 0.0, 0.0, 0.0})), 50.0),
       F32.is_eq(G.Arc.cap(Maybe.default(&2, G.Arc, G.arc_at(N.set_supply(N.arcs(5, N.base()), 100.0, 50.0, 25.0), 32), G.Arc{0, 0, 0, 0, 0.0, 0.0, 0.0, 0.0})), 25.0))),
     truth("a blocked leg leaves the graph", Bool.not(has_leg(N.arcs(0, blocked163()), 3))),
     truth("mode changes only through transfer legs (Jan and Oct fronts, all scenarios)",
       Bool.and(fronts_modes_ok(N.arcs(0, N.base()), P.front(nn(), N.arcs(0, N.base()), N.SOR(), N.CHN())),
         fronts_modes_ok(N.arcs(9, everything()), P.front(nn(), N.arcs(9, everything()), N.SOR(), N.CHN()))))],
    [pareto_vs_brute("Jan base", 0, N.base()),
     pareto_vs_brute("Apr base", 3, N.base()),
     pareto_vs_brute("Jul base", 6, N.base()),
     pareto_vs_brute("Oct base", 9, N.base()),
     pareto_vs_brute("Oct drought + Ferrograo + Rumo", 9, everything()),
     pareto_vs_brute("Jan BR-163 blocked", 0, blocked163()),
     scalar_on_front("cost only", 0, SP.Weights{1.0, 0.0, 0.0}),
     scalar_on_front("hours only", 0, SP.Weights{0.0, 1.0, 0.0}),
     scalar_on_front("risk only", 0, SP.Weights{0.0, 0.0, 1.0}),
     scalar_on_front("cost + vot * hours", 3, gen()),
     scalar_on_front("cost + 10 h + 500 risk", 9, SP.Weights{1.0, 10.0, 500.0})],
    flow_checks("Jan base, 4000 kt", 0, N.base(), 4000.0),
    flow_checks("Oct drought, 4000 kt (demand not met)", 9, drought(), 4000.0),
    flow_checks("Mar all railways, 6000 kt", 2, everything(), 6000.0),
    risk_checks(0, N.base()),
    risk_checks(9, drought())])

def report(+cs: List<&2, Check>, +fails: U32) -> IO(U32):
  match cs:
    case []:
      IO.pure(U32, fails)
    case Check{ok, msg} <> rest:
      do IO<U32>:
        IO.print(Bool.pick(String, ok, "PASS  ", "FAIL  ") ++ msg)
        report(rest, Bool.pick(U32, ok, fails, (fails + 1 : U32)))

def finish.go(+ok: Bool, +fails: U32) -> IO(Unit):
  match ok:
    case True{}:
      IO.print("All checks passed.")
    case False{}:
      IO.die(Unit, 1, U32.show(fails) ++ " check(s) failed")

def finish(+fails: U32) -> IO(Unit):
  finish.go(U32.is_eq(fails, 0), fails)

def main() -> IO(Unit):
  do IO<Unit>:
    fails : U32 <- report(checks(), 0)
    finish(fails)
