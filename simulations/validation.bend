# Falsification test: feed the model the volume Mato Grosso actually exported
# each month (Comex Stat) and compare the port split it chooses with the one
# observed, over the six modelled ports.
#
# Two free parameters, both fitted on 2024 and then tested out of sample on
# 2025:
#   * how the month's volume splits between the three origin regions (USDA
#     quotes tariffs for North, Northeast and Southeast MT);
#   * a friction added to the northern truck hauls, standing in for whatever
#     keeps cargo out of the Arco Norte beyond corridor cost.
#
# The drought scenario is applied to Sep-Nov 2024 (the Madeira was effectively
# shut from September to 27 November 2024) and not to 2025.
import Base
import ../src/graph.bend as G
import ../src/sp.bend as SP
import ../src/flow.bend as F
import ../src/params.bend as Q
import ../src/network.bend as N
import ../src/observed.bend as O
import ../src/svg.bend as V
import ../src/io.bend as IOF
import ../src/report.bend as R

def gen() -> SP.Weights:
  SP.Weights{1.0, Q.vot(), 0.0}

# share of the month's volume starting in North MT (Sorriso) and in Northeast
# MT (Canarana); the rest starts in Southeast MT (Primavera do Leste).
type Fit is Data:
  Fit{north: F32, ne: F32, friction: F32}

def Fit.north(+f: Fit) -> F32:
  Fit{a, b, c} = f
  a

def Fit.ne(+f: Fit) -> F32:
  Fit{a, b, c} = f
  b

def Fit.friction(+f: Fit) -> F32:
  Fit{a, b, c} = f
  c

# Fitted on 2024 over the grid in results/validation_fit.csv: 60% of the
# month's volume starts in North MT and the friction is not needed. How the
# remaining 40% splits between Northeast and Southeast MT does not matter --
# every split scores the same, because the model gives both regions the same
# choices (Santos, Paranagua, Itaqui).
def best() -> Fit:
  Fit{0.6, 0.2, 0.0}

def one_origin() -> Fit:
  Fit{1.0, 0.0, 0.0}

# the best a single origin can do, with the friction fitted
def one_origin_fitted() -> Fit:
  Fit{1.0, 0.0, 30.0}

def scenario(+year: U32, +month: U32, +f: Fit) -> N.Scenario:
  +dry = Bool.and(U32.is_eq(year, 2024), Bool.and(U32.is_ge(month, 8), U32.is_le(month, 10)))
  N.with_friction(Bool.pick(N.Scenario, dry, N.drought(), N.base()), Fit.friction(f))

def arcs_of(+year: U32, +month: U32, +f: Fit) -> List<&2, G.Arc>:
  +v = O.Obs.total(O.month_of(year, month))
  +n = (v * Fit.north(f) : F32)
  +e = (v * Fit.ne(f) : F32)
  N.set_supply(N.arcs(month, scenario(year, month, f)), n, e, (v - n - e : F32))

def solve_at(+year: U32, +month: U32, +f: Fit) -> F.Alloc:
  F.solve(N.n_nodes(), N.n_legs(), arcs_of(year, month, f), gen(), N.SRC(), N.CHN(),
    O.Obs.total(O.month_of(year, month)))

# modelled flow through port i: ship legs 24..28, and Itaqui on leg 41
def modelled_at(+year: U32, +month: U32, +i: U32, +f: Fit) -> F32:
  F.on(F.Alloc.flow(solve_at(year, month, f)), Bool.pick(U32, U32.is_eq(i, 5), 41, (24 + i : U32)))

def share(+x: F32, +tot: F32) -> F32:
  (100.0 * x / F32.max(tot, 1.0e-6) : F32)

# ---- error metric: mean absolute share error, in percentage points ----

def err_one(+year: U32, +month: U32, +i: U32, +f: Fit) -> F32:
  +o = O.month_of(year, month)
  F32.abs((share(modelled_at(year, month, i, f), O.Obs.total(o)) - share(O.Obs.port(o, i), O.Obs.total(o)) : F32))

def err_ports(+i: Nat, +year: U32, +month: U32, +f: Fit) -> F32:
  match i:
    case 0n:
      0.0
    case 1n+k:
      (err_one(year, month, U32.from_nat(k), f) + err_ports(k, year, month, f) : F32)

def err_month(+year: U32, +month: U32, +f: Fit) -> F32:
  (err_ports(6n, year, month, f) / 6.0 : F32)

def err_sum(+ms: List<&2, U32>, +year: U32, +f: Fit) -> F32:
  match ms:
    case []:
      0.0
    case m <> rest:
      (err_month(year, m, f) + err_sum(rest, year, f) : F32)

def mae(+year: U32, +f: Fit) -> F32:
  (err_sum(R.months(), year, f) / 12.0 : F32)

# ---- the grid of origin splits ----

def steps(+n: Nat, +v: F32, +d: F32) -> List<&2, F32>:
  match n:
    case 0n:
      []
    case 1n+k:
      v <> steps(k, (v + d : F32), d)

def keep_fit(+keep: Bool, +f: Fit, +rest: List<&2, Fit>) -> List<&2, Fit>:
  match keep:
    case True{}:
      f <> rest
    case False{}:
      rest

def with_ne(+n: F32, +es: List<&2, F32>, +fr: F32) -> List<&2, Fit>:
  match es:
    case []:
      []
    case e <> rest:
      keep_fit((n + e <= 1.0001 : F32), Fit{n, e, fr}, with_ne(n, rest, fr))

# every (north, ne) pair on the simplex grid, at one friction
def combos(+ns: List<&2, F32>, +es: List<&2, F32>, +fr: F32) -> List<&2, Fit>:
  match ns:
    case []:
      []
    case n <> rest:
      List.append(&2, Fit, with_ne(n, es, fr), combos(rest, es, fr))

def fit_row(+f: Fit) -> String:
  R.csv([R.fmt(Fit.north(f), 2n), R.fmt(Fit.ne(f), 2n), R.fmt((1.0 - Fit.north(f) - Fit.ne(f) : F32), 2n),
    R.fmt(Fit.friction(f), 0n), R.fmt(mae(2024, f), 2n), R.fmt(mae(2025, f), 2n)])

# the same weights at several frictions
def frictions(+frs: List<&2, F32>, +n: F32, +e: F32) -> List<&2, Fit>:
  match frs:
    case []:
      []
    case fr <> rest:
      Fit{n, e, fr} <> frictions(rest, n, e)

def fit_rows(+fs: List<&2, Fit>) -> List<&2, String>:
  match fs:
    case []:
      []
    case f <> rest:
      fit_row(f) <> fit_rows(rest)

# ---- per-month table ----

def cells(+year: U32, +month: U32, +i: U32) -> List<&2, String>:
  +o = O.month_of(year, month)
  [R.fmt(O.Obs.port(o, i), 0n), R.fmt(modelled_at(year, month, i, best()), 0n),
   R.fmt(share(O.Obs.port(o, i), O.Obs.total(o)), 1n),
   R.fmt(share(modelled_at(year, month, i, best()), O.Obs.total(o)), 1n)]

def row(+year: U32, +month: U32) -> String:
  +o = O.month_of(year, month)
  R.csv(List.concat(&2, String,
    [[U32.show(year), R.month(month), R.fmt(O.Obs.total(o), 0n), R.fmt(F.Alloc.shipped(solve_at(year, month, best())), 0n)],
     cells(year, month, 0), cells(year, month, 1), cells(year, month, 2),
     cells(year, month, 3), cells(year, month, 4), cells(year, month, 5)]))

def rows(+ms: List<&2, U32>, +year: U32) -> List<&2, String>:
  match ms:
    case []:
      []
    case m <> rest:
      row(year, m) <> rows(rest, year)

# ---- charts ----

def x(+m: U32) -> F32:
  (U32.to_f32(m) + 1.0 : F32)

def obs_pts(+ms: List<&2, U32>, +year: U32, +i: U32) -> List<&2, V.XY>:
  match ms:
    case []:
      []
    case m <> rest:
      +o = O.month_of(year, m)
      V.XY{x(m), share(O.Obs.port(o, i), O.Obs.total(o))} <> obs_pts(rest, year, i)

def mod_pts(+ms: List<&2, U32>, +year: U32, +i: U32, +f: Fit) -> List<&2, V.XY>:
  match ms:
    case []:
      []
    case m <> rest:
      V.XY{x(m), share(modelled_at(year, m, i, f), O.Obs.total(O.month_of(year, m)))} <> mod_pts(rest, year, i, f)

def chart(+year: U32, +sub: String, +f: Fit) -> String:
  +ms = R.months()
  V.chart("Model vs reality: Mato Grosso grain by export port, " ++ U32.show(year),
    sub, "month (1 = Jan)", "% of the month's MT volume", V.Frame{1.0, 12.0, 0.0, 80.0, False{}, False{}},
    [V.Series{obs_pts(ms, year, 0), V.color(0n), "", "Santos, observed"},
     V.Series{mod_pts(ms, year, 0, f), V.color(0n), "6 4", "Santos, model"},
     V.Series{obs_pts(ms, year, 3), V.color(2n), "", "Barcarena, observed"},
     V.Series{mod_pts(ms, year, 3, f), V.color(2n), "6 4", "Barcarena, model"},
     V.Series{obs_pts(ms, year, 2), V.color(1n), "", "Santarem, observed"},
     V.Series{mod_pts(ms, year, 2, f), V.color(1n), "6 4", "Santarem, model"},
     V.Series{obs_pts(ms, year, 4), V.color(3n), "", "Itacoatiara, observed"},
     V.Series{mod_pts(ms, year, 4, f), V.color(3n), "6 4", "Itacoatiara, model"}],
    "")

def main() -> IO(Unit):
  +ms = R.months()
  +grid = combos(steps(11n, 0.0, 0.1), steps(11n, 0.0, 0.1), 0.0)
  +frs = steps(11n, 0.0, 10.0)
  +fgrid = List.append(&2, Fit, List.append(&2, Fit, frictions(frs, 1.0, 0.0), frictions(frs, 0.6, 0.2)),
    frictions(frs, 0.4, 0.3))
  do IO<Unit>:
    IOF.write_file("results/validation_fit.csv",
      R.csv(["w_north_mt", "w_northeast_mt", "w_southeast_mt", "friction_brl_t", "mae_2024_pp", "mae_2025_pp"])
        ++ R.lines(fit_rows(grid)))
    IOF.write_file("results/validation_friction.csv",
      R.csv(["w_north_mt", "w_northeast_mt", "w_southeast_mt", "friction_brl_t", "mae_2024_pp", "mae_2025_pp"])
        ++ R.lines(fit_rows(fgrid)))
    IOF.write_file("results/validation.csv",
      R.csv(["year", "month", "mt_volume_kt", "shipped_kt",
        "santos_obs_kt", "santos_model_kt", "santos_obs_pct", "santos_model_pct",
        "paranagua_obs_kt", "paranagua_model_kt", "paranagua_obs_pct", "paranagua_model_pct",
        "santarem_obs_kt", "santarem_model_kt", "santarem_obs_pct", "santarem_model_pct",
        "barcarena_obs_kt", "barcarena_model_kt", "barcarena_obs_pct", "barcarena_model_pct",
        "itacoatiara_obs_kt", "itacoatiara_model_kt", "itacoatiara_obs_pct", "itacoatiara_model_pct",
        "itaqui_obs_kt", "itaqui_model_kt", "itaqui_obs_pct", "itaqui_model_pct"])
        ++ R.lines(rows(ms, 2024)) ++ R.lines(rows(ms, 2025)))
    IOF.write_file("results/validation_2024.svg",
      chart(2024, "Solid = Comex Stat (soybean + corn, MT origin). Dashed = model with three origin regions, fitted on this year.", best()))
    IOF.write_file("results/validation_2025.svg",
      chart(2025, "Out of sample: the parameters fitted on 2024, applied to a year they never saw.", best()))
    IOF.write_file("results/validation_one_origin.svg",
      chart(2025, "One origin, no friction: the plain least-cost allocation.", one_origin()))
    IO.print("MAE three origins (fitted on 2024): 2024 " ++ R.fmt(mae(2024, best()), 2n) ++ " pp, 2025 out of sample "
      ++ R.fmt(mae(2025, best()), 2n) ++ " pp")
    IO.print("MAE one origin, no friction:        2024 " ++ R.fmt(mae(2024, one_origin()), 2n) ++ " pp, 2025 "
      ++ R.fmt(mae(2025, one_origin()), 2n) ++ " pp")
    IO.print("MAE one origin, friction fitted:    2024 " ++ R.fmt(mae(2024, one_origin_fitted()), 2n) ++ " pp, 2025 "
      ++ R.fmt(mae(2025, one_origin_fitted()), 2n) ++ " pp")
