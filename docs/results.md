# Results

Every result carries a tag:

- **KNOWN** — textbook or already in the literature; reproduced as a check.
- **VALIDATED** — an implementation property checked by `tests/tests.bend` (42 checks).
- **MODEL** — a number from the stylized network. Valid *inside* `assumptions.md`;
  it becomes a claim about Brazil only after calibration.
- **SPECULATIVE** — an interpretation that goes beyond what the model shows.

Numbers are generalized costs in R$/t (freight + handling + R$0.05/t/h × hours),
Sorriso (MT) → Shanghai, unless stated.

## 0. Is there a contribution?

**No new algorithm.** Label-correcting Pareto search (Hansen 1980, Martins 1984),
successive-shortest-path min-cost flow (Ahuja et al. 1993) and Monte Carlo with
CVaR (Rockafellar & Uryasev 2000) are textbook, and at this scale (23 nodes,
2–5 routes per front) exact methods are instantaneous: nothing here needs a
cleverer algorithm. **KNOWN.**

A structured search (~2,450 records screened, 35 papers kept, 36/36 DOIs verified;
`literature-review.md` and `litsearch/`) found **no work combining the three
layers**, but it did find, and this study must not claim otherwise:

- multi-objective + **CVaR on soybean/corn intermodal flows** — Marto et al. (2026);
- **stochastic recourse in a Brazilian soybean chain** — Reis et al. (2023);
- **re-routing after link disruption in the Brazilian export network** — L'Her et al. (2024);
- **river level → barge convoy size on the Madeira** — Garcia et al. (2022).

What no screened paper puts inside the optimization is **seasonal capacity**
(low water, harvest peaks) coupled to the multi-objective front and to disruption
recourse with tail risk, on the MT corridors. That is the surviving claim.
**VERIFIED (absence of evidence)**: no Scopus/WoS, Brazilian theses under-indexed.

## 1. Correctness

| Check | Result | Tag |
|---|---|---|
| Pareto front = brute-force enumeration of all simple paths (6 month/scenario cases) | identical | VALIDATED |
| Min of 5 scalarizations over the front = Bellman-Ford optimum | equal to 10⁻⁵ | VALIDATED |
| Min-cost flow: capacities, conservation, and no negative cycle in the residual graph (3 cases, incl. unmet demand) | all hold | VALIDATED |
| Hand-solved toy flow (cost 140, marginal 20, max flow 15) | exact | VALIDATED |
| Monte Carlo mean (2¹⁴ trips) vs closed-form expected cost | within 0.1% | VALIDATED |
| Hash uniforms: mean, P(u < 0.1) | 0.498, 0.104 | VALIDATED |

## 2. Does the model reproduce reality? (`validation.csv`, `validation_fit.csv`, charts)

The test: give the model the volume Mato Grosso actually exported each month
(Comex Stat, soybean + corn, 2024 and 2025) and compare the port split it chooses
with the observed one, over the six modelled ports. Parameters are fitted on 2024
and then applied unchanged to 2025.

| variant | free parameters | 2024 (fitted) | 2025 (out of sample) |
|---|---|---|---|
| one origin (Sorriso), corridor cost only | none | 10.3 pp | 11.0 pp |
| one origin + a fitted friction on the northern hauls | 1 (R$30/t) | 7.3 pp | 7.7 pp |
| **three origin regions, no friction** | 1 (the origin split) | **6.9 pp** | **7.0 pp** |

(pp = mean absolute error of the six port shares, averaged over 12 months.)

- **A single-origin least-cost allocation is off by ~11 points of market share.**
  It over-uses the Arco Norte, because from Sorriso the northern corridors are
  genuinely cheaper. **MODEL, falsified.**
- **Geography explains more than a fudge factor.** Splitting the state's volume
  between North MT (Sorriso), Northeast MT (Canarana) and Southeast MT (Primavera
  do Leste) — USDA quotes tariffs for all three — and giving the eastern regions
  only the southern corridors they actually use, beats the fitted friction *and*
  needs no invented cost. Adding the friction on top makes it worse: the two were
  substitutes for the same missing geography. **MODEL.**
- **The fitted split is 60% North MT / 40% eastern MT**, which is the shape of the
  state's production geography; how the 40% divides between Northeast and
  Southeast does not matter here, because the model gives both the same options.
  The split is fitted, not sourced — IMEA regional production would test it. **MODEL.**
- **~7 pp of error survives.** The largest identifiable piece is **Itaqui**: 5–7%
  of MT grain leaves through it, the model sends none. Adding the Ferrovia
  Norte-Sul corridor (truck to Porto Nacional, then rail) **changed nothing** — the
  route is simply dearer than Santos for eastern MT:

  | from Northeast MT (Canarana), June, R$/t door to door | Santos | Itaqui (FNS) | Paranaguá |
  |---|---|---|---|
  | generalized cost | **677** | 728 | 734 |

  At Rumo-like tariffs the FNS would have to be **22% cheaper per t·km** to break
  even. So the observed Itaqui flow is not cost-driven in this model: it comes from
  contracts, Santos congestion the model does not represent, or a rail tariff below
  the one assumed. Full table in `results/corridor_costs.csv`. **MODEL**; the
  reading is **SPECULATIVE**, since no FNS tariff was found.

This is the main methodological result: a cost-minimizing allocation with one
origin — the shape most corridor studies use — misprices market share by about
eleven points, and most of that gap is origin geography, not corridor cost.

## 3. Pareto fronts (`results/fronts.csv`, `pareto_fronts_by_month.svg`)

- In the dry months the front has **two routes**, both via Santarém (truck + Tapajós
  barge, R$633/t in June; truck all the way, R$659/t but 2 days faster and less
  exposed). In the rainy months (Dec–Mar) the risk on BR-163 rises and the
  **southern routes enter the front** as the low-risk options (March: rail to
  Santos at R$679/t with 6.3% interruption probability against R$600/t and 10.2%
  via the barge). **MODEL.**
- **Ferrogrão**, single shipment: R$486/t vs R$555/t in January (−12%), R$491 vs
  R$600 in March (−18%). Break-even rail tariff, from the leg costs:
  **R$0.226/t·km**, essentially the road rate (R$0.229). The saving survives any
  plausible tariff because it removes ~1,000 km of trucking. **MODEL** (closed form).

## 4. Capacitated flow (`seasonal.csv`, `capacity.csv`, charts)

4,000 kt/month from Sorriso, min-cost allocation, by month and scenario (friction 0:
these runs isolate corridor cost).

| | base | + Ferrogrão | + both railways | ports ×1.5 |
|---|---|---|---|---|
| avg cost, March peak (R$/t) | 719.2 | 664.4 (−7.6%) | 660.3 (−8.2%) | 714.2 (−0.7%) |
| marginal cost at 4,000 kt | 741.2 | 741.2 | 738.1 | 738.1 |
| export ceiling (kt/month) | 6,800 | 6,800 | 6,800 | >7,000 |

- **Railways lower the average, not the marginal, and not the ceiling.** Confirmed
  after calibration: Ferrogrão carries its full 2,000 kt/month and cuts the average
  by R$35–55/t, while the last tonne still costs R$741/t, and the maximum
  exportable volume is unchanged. Only terminal capacity moves the ceiling. **MODEL.**
- **The drought no longer strands cargo, it re-routes it at a higher price.** With
  the observed (larger) terminal capacities, closing the Madeira and restricting the
  Tapajós in Sep–Nov still ships 4,000 kt, pushing 1,000–2,500 kt/month onto Santos
  and raising the cost by R$8–10/t. At volumes near the ceiling the shortfall
  returns. This **reverses the pre-calibration conclusion**, which had 5.8% of the
  volume stranded. **MODEL.**
- **Seasonality is now empirical**: the road-price factor comes from the USDA
  monthly truck index (Mar 1.12, Dec 0.86 of the annual mean), so the average cost
  swings R$651/t (Dec) to R$719/t (Mar), −9.5% to +4% around the year. **MODEL.**

## 5. Interruptions (`disruption_by_month.csv`, `front_risk_jan.csv`, charts)

2¹⁴ sampled trips per case, expected-cost route, calibrated costs.

| Month | fixed: mean | fixed: CVaR95 | adaptive: mean | adaptive: CVaR95 | CVaR change |
|---|---|---|---|---|---|
| Jan | 616.3 | 728.4 | 613.1 | 665.1 | −8.7% |
| Mar | 665.0 | 777.3 | 662.3 | 722.2 | −7.1% |
| Aug | 630.0 | 685.0 | 628.8 | 661.9 | −3.4% |
| Dec | 595.0 | 707.2 | 591.6 | 639.3 | −9.6% |

- **Re-planning at a failure still cuts the tail far more than the mean**: CVaR95
  −3% to −10%, mean −0.2% to −0.6%; worst trip R$1,346 → R$950 in March. The effect
  is smaller than before calibration (−6% to −13%) because freight is now more
  expensive, so a delay is a smaller share of the total. **MODEL.**
- **Flexibility beats route choice for tail risk**, as before: the lowest-CVaR route
  on the January front costs ~R$60/t more on average than the cheapest, while
  re-planning buys the tail reduction at no mean cost. **MODEL**; the interruption
  probabilities and delays are still unsourced, so the size is **SPECULATIVE**.

## 6. Parallel Monte Carlo in Bend 2 (`results/benchmark.csv`)

262,144 trips (a depth-18 tree of parallel calls), native build, Apple M2
(4 performance + 4 efficiency cores), best of 3 runs:

| threads | 1 | 2 | 4 | 8 |
|---|---|---|---|---|
| seconds | 3.12 | 1.61 | 0.86 | 0.61 |
| speed-up | 1.00 | 1.93 | 3.62 | 5.11 |

Identical results on every thread count (the random numbers depend only on the
trip index). The speed-up needed no code change: the recursion `a b = tree(k, ..)
tree(k, ..)` *is* the parallel schedule. **VALIDATED** (for this machine).

## 7. What is calibrated, and what is not

Calibrated (see `data-sources.md`): road, rail and barge tariffs and the monthly
road-price factor (USDA AgTransport 2024Q1–2025Q3); ocean freight per port to
Shanghai (Santos R$197/t … Barcarena R$218/t — the Arco Norte is *more* expensive
to China, the opposite of the neutral assumption used before); leg distances;
terminal capacities (highest month of MT grain ever cleared through each port);
the monthly volume to allocate; grain elevation R$55/t.

Still uncalibrated: interruption probabilities and delays (no published series),
stall costs, value of time, the R$25/t re-planning fee, rail capacity, and the
split of a terminal's capacity between MT and other states.

## 8. What would change the conclusions

- **A published FNS/VLI tariff**: the corridor is in the network now, but at an
  assumed rate that makes Itaqui uneconomic. This is the one number that would
  settle whether the missing 5–7% is price or contracts.
- **Sourced regional production weights** (IBGE/IMEA) in place of the fitted 60/40
  origin split.
- Take-or-pay rail and terminal-ownership constraints.
- Storage between months: the model must ship each month what that month produced.
- Real interruption statistics (frequency and duration per corridor).
- Correlated disruptions in the Monte Carlo (one blockade hits every truck).
- Storage between months (turns layer 2 into a multi-period flow).
