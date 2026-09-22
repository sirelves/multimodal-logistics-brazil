# Multimodal grain logistics in Brazil, in Bend 2

A reproducible study of one question:

> How should soybean from Mato Grosso reach an export ship when the routes
> (truck, rail, barge, ship) trade off **cost, time and interruption risk**, and
> capacity, seasons (harvest peaks, low water) and blockades change by month?

Everything is written in **pure [Bend 2](https://github.com/bendlang/bend)**:
network, algorithms, Monte Carlo, tests and the SVG plotting.

**Short answer (for a stylized, uncalibrated network):**

1. There is **no algorithmic novelty to claim**: at this scale exact textbook
   methods (Pareto label correcting, min-cost flow, Monte Carlo + CVaR) solve
   every case in milliseconds. A contribution, if any, is the *coupled model*
   (monthly Pareto front + seasonal capacitated flow + interruptions with
   recourse) for the MT corridors — to be confirmed by a systematic literature
   search.
2. In the model, **export terminals bind before inland links**: new railways
   (Ferrogrão, Rumo extension) lower the *average* cost by 4–7% but leave the
   *marginal* cost and the export ceiling unchanged; +50% terminal capacity raises
   the ceiling by 34%. This rests on assumed terminal shares and is a hypothesis for
   calibration, not a finding about Brazil.
3. **Re-planning at a failure** cuts the tail cost (CVaR95) by 6–13% at almost
   no change in the mean; choosing a "safer" route buys much less.
4. The Monte Carlo is a tree of Bend parallel calls: **5.1× on 8 threads** (M2)
   with identical results.

Full report with tags (KNOWN / VALIDATED / MODEL / SPECULATIVE):
[`docs/results.md`](docs/results.md). Read [`docs/assumptions.md`](docs/assumptions.md) first.

## Contents

```
docs/
  model.md               graph, the three layers, correctness arguments
  assumptions.md         everything that is stylized or missing
  data-sources.md        sourced ranges (with confidence tags) and the value used for each parameter
  literature-review.md   what is known, and where a contribution could sit
  results.md             results, each tagged
src/
  graph.bend             arcs and list helpers
  params.bend            every per-mode number (rates, speeds, risks, delays, costs)
  season.bend            seasonal effects as composable bitmask factors
  network.bend           23 nodes, 30 legs, scenarios (Ferrograo, Rumo ext., drought, blockades, terminal scale)
  pareto.bend            multi-objective (cost, time, risk) label correcting
  sp.bend                Bellman-Ford shortest path on a weighted sum
  flow.bend              min-cost flow by successive shortest paths + optimality certificate
  risk.bend              interruptions: stateless RNG, fixed vs adaptive policies, parallel scenario tree, CVaR
  brute.bend             exhaustive path enumeration (test oracle)
  report.bend, svg.bend, io.bend, num.bend   formatting, charts, files
simulations/             fronts, seasonal, capacity, disruption, bench
tests/tests.bend         42 checks
scripts/bench.sh         native build + thread scaling
results/                 generated CSV and SVG
```

## Run

```bash
curl -fsSL https://bend-lang.com/install.sh | sh   # Bend 2 (tested with 2.0.25)
make test      # 42 checks, ~2 s  -> "All checks passed."
make figures   # regenerates results/, ~35 s on an M2
make bench     # native build, 1/2/4/8 threads (needs clang >= 14; see Makefile)
```

## Key figures

| | |
|---|---|
| ![](results/pareto_fronts_by_month.svg) | ![](results/supply_curve_marginal.svg) |
| Pareto fronts: southern routes enter only in the rainy season, as the low-risk options. | Logistics supply curve: railways shift the start, terminals set the ceiling. |
| ![](results/seasonal_cost.svg) | ![](results/seasonal_shipped.svg) |
| Average cost by month and scenario. | Drought and BR-163 blockade: what cannot be shipped. |
| ![](results/disruption_by_month.svg) | ![](results/front_risk_jan.svg) |
| Tail cost: waiting vs re-planning. | Each Pareto route's mean vs CVaR95 (January). |

Also: `ports_base.svg`, `ports_drought.svg`, `supply_curve_average.svg`.
