# Capacitated allocation month by month: min-cost flow of a fixed monthly
# supply from the Sorriso cluster, under each infrastructure / climate
# scenario. Writes results/seasonal.csv and three charts.
import Base
import ../src/graph.bend as G
import ../src/sp.bend as SP
import ../src/flow.bend as F
import ../src/params.bend as Q
import ../src/network.bend as N
import ../src/svg.bend as V
import ../src/io.bend as IOF
import ../src/report.bend as R

def supply() -> F32:
  4000.0

def gen() -> SP.Weights:
  SP.Weights{1.0, Q.vot(), 0.0}

def solve(+m: U32, +sc: N.Scenario) -> F.Alloc:
  F.solve(N.n_nodes(), N.n_legs(), N.arcs(m, sc), gen(), N.SOR(), N.CHN(), supply())

# average generalized cost of what was shipped, R$/t
def avg(+m: U32, +sc: N.Scenario) -> F32:
  +r = solve(m, sc)
  (F.total(N.arcs(m, sc), gen(), F.Alloc.flow(r)) / F.Alloc.shipped(r) : F32)

def shipped(+m: U32, +sc: N.Scenario) -> F32:
  F.Alloc.shipped(solve(m, sc))

# flow through one export port's ship leg (legs 24..28 = Santos .. Itacoatiara)
def port(+m: U32, +sc: N.Scenario, +leg: U32) -> F32:
  F.on(F.Alloc.flow(solve(m, sc)), leg)

def row(+name: String, +sc: N.Scenario, +m: U32) -> String:
  +r = solve(m, sc)
  +fl = F.Alloc.flow(r)
  R.csv([name, R.month(m), R.fmt(supply(), 0n), R.fmt(F.Alloc.shipped(r), 0n), R.fmt(avg(m, sc), 1n),
    R.fmt(F.Alloc.marginal(r), 1n), R.fmt(F.on(fl, 24), 0n), R.fmt(F.on(fl, 25), 0n), R.fmt(F.on(fl, 26), 0n),
    R.fmt(F.on(fl, 27), 0n), R.fmt(F.on(fl, 28), 0n), R.fmt(F.on(fl, 13), 0n), R.fmt(F.on(fl, 15), 0n)])

def rows(+name: String, +sc: N.Scenario, +ms: List<&2, U32>) -> List<&2, String>:
  match ms:
    case []:
      []
    case m <> rest:
      row(name, sc, m) <> rows(name, sc, rest)

def scenarios() -> List<&2, String>:
  +ms = R.months()
  List.concat(&2, String,
    [rows("base", N.base(), ms), rows("drought", N.drought(), ms), rows("ferrograo", N.ferrograo(), ms),
     rows("rumo_ext", N.rumo(), ms), rows("both_rails", N.rails(), ms),
     rows("drought_both_rails", N.with_drought(N.rails()), ms), rows("br163_blocked", N.br163_blocked(), ms)])

# ---- charts (x = month 1..12) ----

def x(+m: U32) -> F32:
  (U32.to_f32(m) + 1.0 : F32)

def avg_pts(+sc: N.Scenario, +ms: List<&2, U32>) -> List<&2, V.XY>:
  match ms:
    case []:
      []
    case m <> rest:
      V.XY{x(m), avg(m, sc)} <> avg_pts(sc, rest)

def ship_pts(+sc: N.Scenario, +ms: List<&2, U32>) -> List<&2, V.XY>:
  match ms:
    case []:
      []
    case m <> rest:
      V.XY{x(m), shipped(m, sc)} <> ship_pts(sc, rest)

def port_pts(+sc: N.Scenario, +leg: U32, +ms: List<&2, U32>) -> List<&2, V.XY>:
  match ms:
    case []:
      []
    case m <> rest:
      V.XY{x(m), port(m, sc, leg)} <> port_pts(sc, leg, rest)

def s(+pts: List<&2, V.XY>, +ci: Nat, +dash: String, +name: String) -> V.Series:
  V.Series{pts, V.color(ci), dash, name}

def month_axis() -> String:
  "month (1 = Jan)"

def cost_chart() -> String:
  +ms = R.months()
  V.chart("Average cost per tonne shipped, by month and scenario",
    "Min-cost flow of 4,000 kt/month from Sorriso; generalized cost = freight + handling + R$0.05/t/h x hours.",
    month_axis(), "R$/t (generalized)", V.Frame{1.0, 12.0, 450.0, 650.0, False{}, False{}},
    [s(avg_pts(N.base(), ms), 0n, "", "base"), s(avg_pts(N.drought(), ms), 7n, "", "drought year"),
     s(avg_pts(N.ferrograo(), ms), 2n, "", "+ Ferrograo"), s(avg_pts(N.rumo(), ms), 3n, "", "+ Rumo ext."),
     s(avg_pts(N.rails(), ms), 6n, "", "+ both"), s(avg_pts(N.with_drought(N.rails()), ms), 6n, "6 4", "+ both, drought year")],
    "")

def shipped_chart() -> String:
  +ms = R.months()
  V.chart("What the network can carry: tonnes shipped of 4,000 kt/month",
    "Below the dashed line the export capacity reachable from Sorriso binds (ports, barges, rail).",
    month_axis(), "kt shipped per month", V.Frame{1.0, 12.0, 3000.0, 4200.0, False{}, False{}},
    [s(ship_pts(N.base(), ms), 0n, "", "base"), s(ship_pts(N.drought(), ms), 7n, "", "drought year"),
     s(ship_pts(N.br163_blocked(), ms), 1n, "", "BR-163 north blocked"),
     s(ship_pts(N.with_drought(N.rails()), ms), 6n, "6 4", "both railways, drought year")],
    V.hmark(V.Frame{1.0, 12.0, 3000.0, 4200.0, False{}, False{}}, 4000.0, "demand"))

def ports_chart(+title: String, +sc: N.Scenario) -> String:
  +ms = R.months()
  V.chart(title, "kt/month through each export port in the min-cost allocation of 4,000 kt/month.",
    month_axis(), "kt per month", V.Frame{1.0, 12.0, 0.0, 2000.0, False{}, False{}},
    [s(port_pts(sc, 24, ms), 0n, "", "Santos"), s(port_pts(sc, 25, ms), 1n, "", "Paranagua"),
     s(port_pts(sc, 26, ms), 2n, "", "Santarem"), s(port_pts(sc, 27, ms), 3n, "", "Barcarena"),
     s(port_pts(sc, 28, ms), 4n, "", "Itacoatiara")],
    "")

def main() -> IO(Unit):
  do IO<Unit>:
    IOF.write_file("results/seasonal.csv",
      R.csv(["scenario", "month", "supply_kt", "shipped_kt", "avg_cost_brl_t", "marginal_brl_t", "santos_kt",
        "paranagua_kt", "santarem_kt", "barcarena_kt", "itacoatiara_kt", "rumo_rail_kt", "ferrograo_kt"])
        ++ R.lines(scenarios()))
    IOF.write_file("results/seasonal_cost.svg", cost_chart())
    IOF.write_file("results/seasonal_shipped.svg", shipped_chart())
    IOF.write_file("results/ports_base.svg", ports_chart("Export port mix by month, base network", N.base()))
    IOF.write_file("results/ports_drought.svg", ports_chart("Export port mix by month, drought year", N.drought()))
