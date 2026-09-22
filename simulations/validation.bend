# Falsification test: feed the model the volume Mato Grosso actually exported
# each month (Comex Stat) and compare the port split it chooses with the one
# observed. Writes results/validation.csv and two charts.
#
# The drought scenario is applied to Sep-Nov 2024 (the Madeira was effectively
# shut from September to 27 November 2024) and not to 2025.
import Base
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

# 2024 had a drought; Sep-Nov is when it closed the Madeira
def scenario(+year: U32, +month: U32, +friction: F32) -> N.Scenario:
  +dry = Bool.and(U32.is_eq(year, 2024), Bool.and(U32.is_ge(month, 8), U32.is_le(month, 10)))
  N.with_friction(Bool.pick(N.Scenario, dry, N.drought(), N.base()), friction)

# the friction that best reproduces the observed split (fitted below:
# results/validation_fit.csv has the whole curve)
def best_friction() -> F32:
  30.0

def solve_at(+year: U32, +month: U32, +friction: F32) -> F.Alloc:
  +o = O.month_of(year, month)
  F.solve(N.n_nodes(), N.n_legs(), N.arcs(month, scenario(year, month, friction)), gen(), N.SOR(), N.CHN(), O.Obs.total(o))

def solve(+year: U32, +month: U32) -> F.Alloc:
  solve_at(year, month, best_friction())

# modelled flow through port i, kt (ship legs 24..28 are in port order)
def modelled_at(+year: U32, +month: U32, +i: U32, +friction: F32) -> F32:
  F.on(F.Alloc.flow(solve_at(year, month, friction)), (24 + i : U32))

def modelled(+year: U32, +month: U32, +i: U32) -> F32:
  modelled_at(year, month, i, best_friction())

def share(+x: F32, +tot: F32) -> F32:
  (100.0 * x / F32.max(tot, 1.0e-6) : F32)

def cells(+year: U32, +month: U32, +i: U32) -> List<&2, String>:
  +o = O.month_of(year, month)
  [R.fmt(O.Obs.port(o, i), 0n), R.fmt(modelled(year, month, i), 0n),
   R.fmt(share(O.Obs.port(o, i), O.Obs.total(o)), 1n), R.fmt(share(modelled(year, month, i), O.Obs.total(o)), 1n)]

def row(+year: U32, +month: U32) -> String:
  +o = O.month_of(year, month)
  R.csv(List.concat(&2, String,
    [[U32.show(year), R.month(month), R.fmt(O.Obs.total(o), 0n), R.fmt(F.Alloc.shipped(solve(year, month)), 0n)],
     cells(year, month, 0), cells(year, month, 1), cells(year, month, 2), cells(year, month, 3), cells(year, month, 4)]))

def rows(+year: U32, +ms: List<&2, U32>) -> List<&2, String>:
  match ms:
    case []:
      []
    case m <> rest:
      row(year, m) <> rows(year, rest)

# mean absolute error of the modelled share, in percentage points
def err_one(+year: U32, +month: U32, +i: U32, +fr: F32) -> F32:
  +o = O.month_of(year, month)
  F32.abs((share(modelled_at(year, month, i, fr), O.Obs.total(o)) - share(O.Obs.port(o, i), O.Obs.total(o)) : F32))

def err_month(+year: U32, +month: U32, +fr: F32) -> F32:
  ((err_one(year, month, 0, fr) + err_one(year, month, 1, fr) + err_one(year, month, 2, fr)
    + err_one(year, month, 3, fr) + err_one(year, month, 4, fr)) / 5.0 : F32)

def err_sum(+year: U32, +ms: List<&2, U32>, +fr: F32) -> F32:
  match ms:
    case []:
      0.0
    case m <> rest:
      (err_month(year, m, fr) + err_sum(year, rest, fr) : F32)

def mae_at(+year: U32, +fr: F32) -> F32:
  (err_sum(year, R.months(), fr) / 12.0 : F32)

def mae(+year: U32) -> F32:
  mae_at(year, best_friction())

# ---- fitting the friction ----

def grid(+n: Nat, +fr: F32) -> List<&2, F32>:
  match n:
    case 0n:
      []
    case 1n+k:
      fr <> grid(k, (fr + 10.0 : F32))

def fit_rows(+frs: List<&2, F32>) -> List<&2, String>:
  match frs:
    case []:
      []
    case fr <> rest:
      R.csv([R.fmt(fr, 0n), R.fmt(mae_at(2024, fr), 2n), R.fmt(mae_at(2025, fr), 2n),
        R.fmt(((mae_at(2024, fr) + mae_at(2025, fr)) / 2.0 : F32), 2n)]) <> fit_rows(rest)

def fit_pts(+frs: List<&2, F32>) -> List<&2, V.XY>:
  match frs:
    case []:
      []
    case fr <> rest:
      V.XY{fr, ((mae_at(2024, fr) + mae_at(2025, fr)) / 2.0 : F32)} <> fit_pts(rest)

def fit_chart(+frs: List<&2, F32>) -> String:
  V.chart("How much extra cost the northern corridors need to match reality",
    "Mean absolute error of the modelled port split (5 ports, 24 months) against Comex Stat.",
    "friction added to the BR-163 / BR-364 truck legs (R$/t)", "mean absolute share error (pp)",
    V.Frame{0.0, 200.0, 0.0, 20.0, False{}, False{}},
    [V.Series{fit_pts(frs), V.color(0n), "", "2024 + 2025"}], "")

# ---- charts ----

def x(+m: U32) -> F32:
  (U32.to_f32(m) + 1.0 : F32)

def obs_pts(+year: U32, +i: U32, +ms: List<&2, U32>) -> List<&2, V.XY>:
  match ms:
    case []:
      []
    case m <> rest:
      +o = O.month_of(year, m)
      V.XY{x(m), share(O.Obs.port(o, i), O.Obs.total(o))} <> obs_pts(year, i, rest)

def mod_pts(+year: U32, +i: U32, +ms: List<&2, U32>) -> List<&2, V.XY>:
  match ms:
    case []:
      []
    case m <> rest:
      V.XY{x(m), share(modelled(year, m, i), O.Obs.total(O.month_of(year, m)))} <> mod_pts(year, i, rest)

def chart(+year: U32) -> String:
  +ms = R.months()
  V.chart("Model vs reality: share of Mato Grosso grain by export port, " ++ U32.show(year),
    "Solid = observed (Comex Stat, soybean + corn, MT origin). Dashed = min-cost allocation of the same monthly volume.",
    "month (1 = Jan)", "% of the month's MT volume", V.Frame{1.0, 12.0, 0.0, 100.0, False{}, False{}},
    [V.Series{obs_pts(year, 0, ms), V.color(0n), "", "Santos, observed"},
     V.Series{mod_pts(year, 0, ms), V.color(0n), "6 4", "Santos, model"},
     V.Series{obs_pts(year, 3, ms), V.color(2n), "", "Barcarena, observed"},
     V.Series{mod_pts(year, 3, ms), V.color(2n), "6 4", "Barcarena, model"},
     V.Series{obs_pts(year, 2, ms), V.color(1n), "", "Santarem, observed"},
     V.Series{mod_pts(year, 2, ms), V.color(1n), "6 4", "Santarem, model"},
     V.Series{obs_pts(year, 4, ms), V.color(3n), "", "Itacoatiara, observed"},
     V.Series{mod_pts(year, 4, ms), V.color(3n), "6 4", "Itacoatiara, model"}],
    "")

def main() -> IO(Unit):
  +ms = R.months()
  +frs = grid(21n, 0.0)
  do IO<Unit>:
    IOF.write_file("results/validation_fit.csv",
      R.csv(["friction_brl_t", "mae_2024_pp", "mae_2025_pp", "mae_mean_pp"]) ++ R.lines(fit_rows(frs)))
    IOF.write_file("results/validation_fit.svg", fit_chart(frs))
    IOF.write_file("results/validation.csv",
      R.csv(["year", "month", "mt_volume_kt", "shipped_kt",
        "santos_obs_kt", "santos_model_kt", "santos_obs_pct", "santos_model_pct",
        "paranagua_obs_kt", "paranagua_model_kt", "paranagua_obs_pct", "paranagua_model_pct",
        "santarem_obs_kt", "santarem_model_kt", "santarem_obs_pct", "santarem_model_pct",
        "barcarena_obs_kt", "barcarena_model_kt", "barcarena_obs_pct", "barcarena_model_pct",
        "itacoatiara_obs_kt", "itacoatiara_model_kt", "itacoatiara_obs_pct", "itacoatiara_model_pct"])
        ++ R.lines(rows(2024, ms)) ++ R.lines(rows(2025, ms)))
    IOF.write_file("results/validation_2024.svg", chart(2024))
    IOF.write_file("results/validation_2025.svg", chart(2025))
    IO.print("mean absolute share error: 2024 " ++ R.fmt(mae(2024), 1n) ++ " pp, 2025 " ++ R.fmt(mae(2025), 1n) ++ " pp")
