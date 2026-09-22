# Pareto fronts (cost, time, interruption risk), Sorriso -> Shanghai, per month
# and scenario. Writes results/fronts.csv and two charts.
import Base
import ../src/graph.bend as G
import ../src/pareto.bend as P
import ../src/network.bend as N
import ../src/svg.bend as V
import ../src/io.bend as IOF
import ../src/report.bend as R

def rows(+sc_name: String, +m: U32, +all: List<&2, G.Arc>, +ls: List<&2, P.Lab>) -> List<&2, String>:
  match ls:
    case []:
      []
    case l <> t:
      R.csv([sc_name, R.month(m), R.fmt(P.Lab.c(l), 1n), R.fmt((P.Lab.t(l) / 24.0 : F32), 2n),
        R.fmt((100.0 * P.p_any(P.Lab.r(l)) : F32), 2n), N.port_of(all, P.Lab.arcs(l)), R.route(all, P.Lab.arcs(l))])
        <> rows(sc_name, m, all, t)

def front_of(+m: U32, +sc: N.Scenario) -> List<&2, P.Lab>:
  P.front(N.n_nodes(), N.arcs(m, sc), N.SOR(), N.CHN())

def table(+sc_name: String, +sc: N.Scenario, +ms: List<&2, U32>) -> List<&2, String>:
  match ms:
    case []:
      []
    case m <> rest:
      List.append(&2, String, rows(sc_name, m, N.arcs(m, sc), front_of(m, sc)), table(sc_name, sc, rest))

# (days, R$/t) points of a front
def pts(+ls: List<&2, P.Lab>) -> List<&2, V.XY>:
  match ls:
    case []:
      []
    case l <> t:
      V.XY{(P.Lab.t(l) / 24.0 : F32), P.Lab.c(l)} <> pts(t)

def tags(+f: V.Frame, +all: List<&2, G.Arc>, +ls: List<&2, P.Lab>) -> String:
  match ls:
    case []:
      ""
    case l <> t:
      R.tag(f, (P.Lab.t(l) / 24.0 : F32), P.Lab.c(l), N.port_of(all, P.Lab.arcs(l)) ++ " " ++ R.fmt((100.0 * P.p_any(P.Lab.r(l)) : F32), 1n) ++ "%")
        ++ tags(f, all, t)

def frame() -> V.Frame:
  V.Frame{41.0, 49.0, 420.0, 580.0, False{}, False{}}

# legend entry only; the points are drawn as markers (a 3-criteria front has
# no natural order to connect in 2-D)
def series(+name: String, +ci: Nat, +m: U32, +sc: N.Scenario) -> V.Series:
  V.Series{[], V.color(ci), "", name}

def marks(+ci: Nat, +m: U32, +sc: N.Scenario) -> String:
  +f = frame()
  R.dots(f, pts(front_of(m, sc)), V.color(ci), "4.5") ++ tags(f, N.arcs(m, sc), front_of(m, sc))

def by_month() -> String:
  +b = N.base()
  V.chart("Pareto fronts by month, base network",
    "Sorriso (MT) to Shanghai. Each point is a non-dominated route; label = export port, P(interruption).",
    "door-to-door time (days)", "freight + handling cost (R$/t)", frame(),
    [series("Jan", 0n, 0, b), series("Apr", 1n, 3, b), series("Jul", 2n, 6, b), series("Oct", 3n, 9, b)],
    marks(0n, 0, b) ++ marks(1n, 3, b) ++ marks(2n, 6, b) ++ marks(3n, 9, b))

def all_rows() -> String:
  +ms = R.months()
  R.csv(["scenario", "month", "cost_brl_t", "days", "p_interrupt_pct", "port", "route"])
    ++ R.lines(table("base", N.base(), ms))
    ++ R.lines(table("drought", N.drought(), ms))
    ++ R.lines(table("ferrograo", N.ferrograo(), ms))
    ++ R.lines(table("rumo_ext", N.rumo(), ms))
    ++ R.lines(table("br163_blocked", N.br163_blocked(), ms))
    ++ R.lines(table("drought_ferrograo", N.with_drought(N.ferrograo()), ms))

def main() -> IO(Unit):
  do IO<Unit>:
    IOF.write_file("results/fronts.csv", all_rows())
    IOF.write_file("results/pareto_fronts_by_month.svg", by_month())
