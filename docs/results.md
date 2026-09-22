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
| Pareto front = brute-force enumeration of all simple paths (6 month/scenario cases, 2–4 routes each) | identical | VALIDATED |
| Min of 5 scalarizations over the front = Bellman-Ford optimum | equal to 10⁻⁵ | VALIDATED |
| Min-cost flow: capacities, conservation, and no negative cycle in the residual graph (3 cases, incl. unmet demand) | all hold | VALIDATED |
| Hand-solved toy flow (cost 140, marginal 20, max flow 15) | exact | VALIDATED |
| Monte Carlo mean (2¹⁴ trips) vs closed-form expected cost | 0.08% (Jan), 0.04% (Oct drought) | VALIDATED |
| Hash uniforms: mean, P(u < 0.1) | 0.498, 0.104 | VALIDATED |

## 2. Pareto fronts (`results/fronts.csv`, `pareto_fronts_by_month.svg`)

- In the dry months (Jun–Aug) the front has **two routes**, both to Santarém
  (truck + Tapajós barge R$450.5/t, 44.7 d; or truck all the way, R$460/t, 42.3 d).
  In the rainy months (Dec–Mar) interruption risk on BR-163 rises and the
  **southern routes enter the front** as the low-risk options (road + Rumo rail to
  Santos: R$510.5/t, P(interruption) 5.4% vs 9.2%). **MODEL.**
- Arco Norte dominates single shipments in every month, *because the ocean leg is
  neutral* and the inland distance is shorter. Real flows still go mostly south
  because of capacity, which a single-shipment front ignores. This is the reason
  for layer 2. **MODEL** (and a warning about single-shipment routing).
- **Ferrogrão**, single shipment: R$396/t vs R$450.5/t (−12%). Break-even rail
  tariff, from the leg costs: 12 + 20 + 933·r + 15 = 160.5 + 25 gives
  **r = R$0.148/t·km**, practically the road rate. The saving survives any
  plausible tariff, because it removes ~990 km of trucking. **MODEL** (closed
  form, checkable by hand).

## 3. Capacitated flow (`seasonal.csv`, `capacity.csv`, charts)

4,000 kt/month from Sorriso, min-cost allocation, by month and scenario.

| | base | + Ferrogrão | + Rumo ext. | + both |
|---|---|---|---|---|
| avg cost Jan (R$/t) | 556.8 | 533.6 (−4.2%) | 553.9 (−0.5%) | 530.7 (−4.7%) |
| avg cost Feb–Apr peak | 589.7 | 552.6 (−6.3%) | 583.0 (−1.1%) | 546.0 (−7.4%) |
| marginal cost, peak | 696.3 | 696.3 | 696.3 | 696.3 |

- **Railways lower the average, not the marginal.** At 4,000 kt/month the last
  tonne goes by truck to Paranaguá in every scenario (R$696/t in the peak), because
  the export terminals are full. The marginal is what sets the freight component
  of the farm-gate basis in a competitive market. **MODEL**; the price reading is
  **SPECULATIVE**.
- **Ferrogrão's benefit is capped downstream.** It lowers the marginal cost
  only below ~1,750 kt/month (e.g. R$493 vs R$580/t at 1,000 kt): it feeds the same
  Tapajós barges and Arco Norte terminals (~1,670 kt/month here), and above that the
  marginal tonne is set elsewhere. **MODEL.**
- **Export ceiling.** In the March peak the network can export **4,890 kt/month**
  from Sorriso with or without either railway; with terminals ×1.5, **6,540**
  (+34%). In this model terminals bind before inland links. This depends directly
  on assumption 2 (terminal shares), so it is a hypothesis for calibration, not a
  finding about Brazil. **MODEL.**
- **Drought year** (Madeira closed, Tapajós at 40% in Sep–Nov): 3,768 of 4,000 kt
  shipped (−5.8%); **building both railways does not restore it** (3,768), terminal
  capacity would. **MODEL.**
- **BR-163 north blocked** (truck legs to Miritituba and Santarém): 3,220 kt
  shipped in Jan (−19.5%), 3,010 in Aug–Nov (−24.8%, low water on top); the cost of
  what is shipped rises R$31/t. **MODEL.**

## 4. Interruptions (`disruption_by_month.csv`, `front_risk_jan.csv`, charts)

2¹⁴ sampled trips per case, expected-cost route.

| Month | fixed: mean | fixed: CVaR95 | adaptive: mean | adaptive: CVaR95 | CVaR change |
|---|---|---|---|---|---|
| Jan | 512.0 | 624.0 | 508.1 | 546.0 | −12.5% |
| Feb–Mar | 547.7 | 660.0 | 544.2 | 589.7 | −10.7% |
| Jun–Aug | 506.9 | 561.9 | 505.4 | 530.7 | −5.6% |
| Sep–Nov | 509.7 | 576.2 | 507.8 | 539.4 | −6.4% |

- **Re-planning at a failure cuts the tail far more than the mean**: CVaR95
  −6% to −13%, mean −0.3% to −0.8%; worst trip R$1,193 → R$797 in January. **MODEL.**
- **Flexibility beats route choice for tail risk.** Across the January Pareto
  front (each route followed as a fixed plan), the lowest-CVaR route (road + rail to
  Santos, CVaR95 612.9) is only R$11/t better in the tail than the cheapest route and
  costs R$57/t more on average; the ability to re-plan buys R$78/t of tail at no
  mean cost. **MODEL**; the general statement is **SPECULATIVE** (it depends on the
  unsourced interruption probabilities, delays and the R$25/t re-planning fee).
- In a drought year the expected-cost route in Sep–Nov switches from barge to
  truck-only to Santarém (the barge got riskier), which is why the drought curve
  sits *below* the base curve in those months. **MODEL.**

## 5. Parallel Monte Carlo in Bend 2 (`results/benchmark.csv`)

262,144 trips (a depth-18 tree of parallel calls), native build, Apple M2
(4 performance + 4 efficiency cores), best of 3 runs:

| threads | 1 | 2 | 4 | 8 |
|---|---|---|---|---|
| seconds | 3.12 | 1.61 | 0.86 | 0.61 |
| speed-up | 1.00 | 1.93 | 3.62 | 5.11 |

Identical results on every thread count (the random numbers depend only on the
trip index). The speed-up needed no code change: the recursion `a b = tree(k, ..)
tree(k, ..)` *is* the parallel schedule. **VALIDATED** (for this machine).

## 6. What would change the conclusions

- Calibrated terminal capacities (who else uses Santos/Paranaguá, by month):
  decides whether "terminals bind first" survives.
- An ocean-freight differential by port (draft, distance via Panama vs Cape).
- Real interruption statistics (frequency and duration per corridor, e.g. from
  PRF road-closure records and ANTAQ/Navy navigation restrictions).
- Correlated disruptions in the Monte Carlo (one blockade hits every truck).
- Harvest-shaped monthly supply and storage between months (turns layer 2 into a
  multi-period flow).
