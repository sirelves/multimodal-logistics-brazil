# Interruption risk, by Monte Carlo (2^14 sampled trips per case):
#  1. by month: fixed expected-cost route vs adaptive re-planning (mean, CVaR95)
#  2. January: every route of the Pareto front followed as a fixed plan
# Writes results/disruption_by_month.csv, results/front_risk_jan.csv, two charts.
import Base
import ../src/graph.bend as G
import ../src/sp.bend as SP
import ../src/pareto.bend as P
import ../src/risk.bend as K
import ../src/network.bend as N
import ../src/svg.bend as V
import ../src/io.bend as IOF
import ../src/report.bend as R

def depth() -> Nat:
  14n

def best(+m: U32, +sc: N.Scenario) -> List<&2, G.Arc>:
  +a = N.arcs(m, sc)
  G.pick_arcs(a, SP.Route.arcs(SP.route(N.n_nodes(), K.expected_arcs(a), K.cost_only(), N.SOR(), N.CHN())))

def outs(+m: U32, +sc: N.Scenario) -> List<&2, K.Out>:
  +r = best(m, sc)
  K.tree(depth(), K.Job{K.Plan{N.n_nodes(), N.arcs(m, sc), N.CHN()}, r, r}, 1)

type Duo is Data:
  Duo{fixed: K.Stats, adaptive: K.Stats}

def duo(+m: U32, +sc: N.Scenario) -> Duo:
  +os = outs(m, sc)
  Duo{K.stats(K.sort(K.firsts(os))), K.stats(K.sort(K.seconds(os)))}

def Duo.fixed(+p: Duo) -> K.Stats:
  Duo{f, a} = p
  f

def Duo.adaptive(+p: Duo) -> K.Stats:
  Duo{f, a} = p
  a

def stat_cells(+s: K.Stats) -> List<&2, String>:
  [R.fmt(K.Stats.mean(s), 1n), R.fmt(K.Stats.p95(s), 1n), R.fmt(K.Stats.cvar95(s), 1n), R.fmt(K.Stats.pmax(s), 1n)]

def ids(+r: List<&2, G.Arc>) -> List<&2, U32>:
  match r:
    case []:
      []
    case a <> t:
      G.Arc.id(a) <> ids(t)

def month_row(+name: String, +sc: N.Scenario, +m: U32, +p: Duo) -> String:
  +r = best(m, sc)
  R.csv(List.concat(&2, String, [[name, R.month(m), N.port_of(r, ids(r)),
    R.fmt(K.nominal_cost(r), 1n), R.fmt(K.expected_cost(r), 1n)], stat_cells(Duo.fixed(p)), stat_cells(Duo.adaptive(p))]))

def month_rows(+ds: List<&2, Duo>, +name: String, +sc: N.Scenario, +m: U32) -> List<&2, String>:
  match ds:
    case []:
      []
    case d <> rest:
      month_row(name, sc, m, d) <> month_rows(rest, name, sc, (m + 1 : U32))

# ---- the January front, each route as a fixed plan ----

def lab_route(+m: U32, +sc: N.Scenario, +l: P.Lab) -> List<&2, G.Arc>:
  G.pick_arcs(N.arcs(m, sc), P.Lab.arcs(l))

def fixed_stats(+m: U32, +sc: N.Scenario, +route: List<&2, G.Arc>) -> K.Stats:
  +os = K.tree(depth(), K.Job{K.Plan{N.n_nodes(), N.arcs(m, sc), N.CHN()}, route, route}, 1)
  K.stats(K.sort(K.firsts(os)))

type Row is Data:
  Row{lab: P.Lab, st: K.Stats}

def rows_of(+m: U32, +sc: N.Scenario, +ls: List<&2, P.Lab>) -> List<&2, Row>:
  match ls:
    case []:
      []
    case l <> t:
      Row{l, fixed_stats(m, sc, lab_route(m, sc, l))} <> rows_of(m, sc, t)

def front_rows(+m: U32, +sc: N.Scenario, +rs: List<&2, Row>) -> List<&2, String>:
  match rs:
    case []:
      []
    case Row{l, st} <> t:
      +route = lab_route(m, sc, l)
      R.csv(List.concat(&2, String, [[N.port_of(N.arcs(m, sc), P.Lab.arcs(l)), R.fmt(P.Lab.c(l), 1n),
        R.fmt((P.Lab.t(l) / 24.0 : F32), 2n), R.fmt((100.0 * P.p_any(P.Lab.r(l)) : F32), 2n),
        R.fmt(K.expected_cost(route), 1n)], stat_cells(st), [R.route(N.arcs(m, sc), P.Lab.arcs(l))]]))
        <> front_rows(m, sc, t)

def front_pts(+rs: List<&2, Row>) -> List<&2, V.XY>:
  match rs:
    case []:
      []
    case Row{l, st} <> t:
      V.XY{K.Stats.mean(st), K.Stats.cvar95(st)} <> front_pts(t)

def front_tags(+f: V.Frame, +m: U32, +sc: N.Scenario, +rs: List<&2, Row>) -> String:
  match rs:
    case []:
      ""
    case Row{l, st} <> t:
      R.tag(f, K.Stats.mean(st), K.Stats.cvar95(st), R.short(N.arcs(m, sc), P.Lab.arcs(l)))
        ++ front_tags(f, m, sc, t)

def jan_front() -> List<&2, P.Lab>:
  P.front(N.n_nodes(), N.arcs(0, N.base()), N.SOR(), N.CHN())

def front_chart(+rs: List<&2, Row>) -> String:
  +f : V.Frame = V.Frame{500.0, 620.0, 590.0, 660.0, False{}, False{}}
  V.chart("January: expected cost vs tail cost of each Pareto route",
    "Each route of the (cost, time, risk) front followed as a fixed plan; 16,384 sampled trips each.",
    "mean cost (R$/t, generalized, with interruptions)", "CVaR95: mean of the worst 5% (R$/t)", f,
    [V.Series{[], V.color(0n), "", "Pareto routes"}],
    R.dots(f, front_pts(rs), V.color(0n), "5") ++ front_tags(f, 0, N.base(), rs))

# ---- by-month chart ----

def x(+m: U32) -> F32:
  (U32.to_f32(m) + 1.0 : F32)

def duos(+sc: N.Scenario, +ms: List<&2, U32>) -> List<&2, Duo>:
  match ms:
    case []:
      []
    case m <> rest:
      duo(m, sc) <> duos(sc, rest)

# which: 0 = fixed mean, 1 = fixed CVaR95, 2 = adaptive CVaR95
def pick_stat(+d: Duo, +which: U32) -> F32:
  Bool.pick(F32, U32.is_eq(which, 0), K.Stats.mean(Duo.fixed(d)),
    Bool.pick(F32, U32.is_eq(which, 1), K.Stats.cvar95(Duo.fixed(d)), K.Stats.cvar95(Duo.adaptive(d))))

def pts(+ds: List<&2, Duo>, +which: U32, +m: U32) -> List<&2, V.XY>:
  match ds:
    case []:
      []
    case d <> rest:
      V.XY{x(m), pick_stat(d, which)} <> pts(rest, which, (m + 1 : U32))

def month_chart(+b: List<&2, Duo>, +d: List<&2, Duo>) -> String:
  V.chart("Tail cost of interruptions by month: wait it out vs re-plan",
    "Expected-cost route from Sorriso; CVaR95 = mean cost of the worst 5% of 16,384 sampled trips.",
    "month (1 = Jan)", "R$/t (generalized)", V.Frame{1.0, 12.0, 500.0, 700.0, False{}, False{}},
    [V.Series{pts(b, 0, 0), V.color(0n), "2 4", "mean, fixed route"},
     V.Series{pts(b, 1, 0), V.color(7n), "", "CVaR95, fixed route"},
     V.Series{pts(b, 2, 0), V.color(2n), "", "CVaR95, adaptive re-planning"},
     V.Series{pts(d, 1, 0), V.color(7n), "6 4", "CVaR95 fixed, drought year"},
     V.Series{pts(d, 2, 0), V.color(2n), "6 4", "CVaR95 adaptive, drought year"}],
    "")

def main() -> IO(Unit):
  +ms = R.months()
  +b = duos(N.base(), ms)
  +d = duos(N.drought(), ms)
  +rs = rows_of(0, N.base(), jan_front())
  do IO<Unit>:
    IOF.write_file("results/disruption_by_month.csv",
      R.csv(["scenario", "month", "port", "nominal_brl_t", "expected_brl_t", "fixed_mean", "fixed_p95", "fixed_cvar95",
        "fixed_max", "adaptive_mean", "adaptive_p95", "adaptive_cvar95", "adaptive_max"])
        ++ R.lines(month_rows(b, "base", N.base(), 0)) ++ R.lines(month_rows(d, "drought", N.drought(), 0)))
    IOF.write_file("results/front_risk_jan.csv",
      R.csv(["port", "cost_brl_t", "days", "p_interrupt_pct", "expected_brl_t", "mean", "p95", "cvar95", "max", "route"])
        ++ R.lines(front_rows(0, N.base(), rs)))
    IOF.write_file("results/disruption_by_month.svg", month_chart(b, d))
    IOF.write_file("results/front_risk_jan.svg", front_chart(rs))
