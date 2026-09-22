# Logistics supply curve: marginal and average cost of exporting S kt/month
# from Sorriso in the March peak, for S = 250 .. 7000, per scenario, and a
# sensitivity on export-terminal capacity. Writes results/capacity.csv and
# two charts.
import Base
import ../src/sp.bend as SP
import ../src/flow.bend as F
import ../src/params.bend as Q
import ../src/network.bend as N
import ../src/svg.bend as V
import ../src/io.bend as IOF
import ../src/report.bend as R

def month() -> U32:
  2

def gen() -> SP.Weights:
  SP.Weights{1.0, Q.vot(), 0.0}

def solve(+sc: N.Scenario, +s: F32) -> F.Alloc:
  F.solve(N.n_nodes(), N.n_legs(), N.arcs(month(), sc), gen(), N.SOR(), N.CHN(), s)

def avg(+sc: N.Scenario, +s: F32) -> F32:
  +r = solve(sc, s)
  (F.total(N.arcs(month(), sc), gen(), F.Alloc.flow(r)) / F.Alloc.shipped(r) : F32)

# marginal cost, capped at the chart top when demand cannot be met
def marg(+sc: N.Scenario, +s: F32) -> F32:
  F32.min(F.Alloc.marginal(solve(sc, s)), 2000.0)

def grid.go(+n: Nat, +s: F32) -> List<&2, F32>:
  match n:
    case 0n:
      []
    case 1n+k:
      s <> grid.go(k, (s + 250.0 : F32))

# 250, 500, .. 7000 kt/month
def grid() -> List<&2, F32>:
  grid.go(28n, 250.0)

def rows(+name: String, +sc: N.Scenario, +ss: List<&2, F32>) -> List<&2, String>:
  match ss:
    case []:
      []
    case s <> rest:
      +r = solve(sc, s)
      R.csv([name, R.fmt(s, 0n), R.fmt(F.Alloc.shipped(r), 0n), R.fmt(avg(sc, s), 1n), R.fmt(F.Alloc.marginal(r), 1n)])
        <> rows(name, sc, rest)

def pts_m(+sc: N.Scenario, +ss: List<&2, F32>) -> List<&2, V.XY>:
  match ss:
    case []:
      []
    case s <> rest:
      V.XY{s, marg(sc, s)} <> pts_m(sc, rest)

def pts_a(+sc: N.Scenario, +ss: List<&2, F32>) -> List<&2, V.XY>:
  match ss:
    case []:
      []
    case s <> rest:
      V.XY{s, avg(sc, s)} <> pts_a(sc, rest)

def ports15() -> N.Scenario:
  N.with_ports(N.base(), 1.5)

def rails15() -> N.Scenario:
  N.with_ports(N.rails(), 1.5)

def frame() -> V.Frame:
  V.Frame{250.0, 7000.0, 400.0, 800.0, False{}, False{}}

def marginal_chart() -> String:
  +g = grid()
  V.chart("Logistics supply curve in the March peak: cost of the last tonne",
    "Min-cost flow from Sorriso; a step is a corridor filling up. Off the top = demand cannot be met.",
    "supply to export (kt/month)", "marginal cost (R$/t, generalized)", frame(),
    [V.Series{pts_m(N.base(), g), V.color(0n), "", "base"},
     V.Series{pts_m(N.ferrograo(), g), V.color(2n), "", "+ Ferrograo"},
     V.Series{pts_m(N.rails(), g), V.color(6n), "", "+ both railways"},
     V.Series{pts_m(ports15(), g), V.color(1n), "6 4", "ports x1.5"},
     V.Series{pts_m(rails15(), g), V.color(3n), "6 4", "both railways + ports x1.5"}],
    "")

def average_chart() -> String:
  +g = grid()
  V.chart("Average cost per tonne in the March peak",
    "Same allocations as the marginal-cost chart; only volume actually shipped is averaged.",
    "supply to export (kt/month)", "average cost (R$/t, generalized)", V.Frame{250.0, 7000.0, 450.0, 650.0, False{}, False{}},
    [V.Series{pts_a(N.base(), g), V.color(0n), "", "base"},
     V.Series{pts_a(N.ferrograo(), g), V.color(2n), "", "+ Ferrograo"},
     V.Series{pts_a(N.rails(), g), V.color(6n), "", "+ both railways"},
     V.Series{pts_a(ports15(), g), V.color(1n), "6 4", "ports x1.5"},
     V.Series{pts_a(rails15(), g), V.color(3n), "6 4", "both railways + ports x1.5"}],
    "")

def main() -> IO(Unit):
  +g = grid()
  do IO<Unit>:
    IOF.write_file("results/capacity.csv",
      R.csv(["scenario", "supply_kt", "shipped_kt", "avg_cost_brl_t", "marginal_brl_t"])
        ++ R.lines(rows("base", N.base(), g)) ++ R.lines(rows("ferrograo", N.ferrograo(), g))
        ++ R.lines(rows("both_rails", N.rails(), g)) ++ R.lines(rows("ports_x1.5", ports15(), g))
        ++ R.lines(rows("both_rails_ports_x1.5", rails15(), g)))
    IOF.write_file("results/supply_curve_marginal.svg", marginal_chart())
    IOF.write_file("results/supply_curve_average.svg", average_chart())
