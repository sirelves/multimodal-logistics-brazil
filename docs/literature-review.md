# Literature review

A time-boxed search (September 2026), not a systematic review. What matters for
this study is which parts are **already known** (so they are reproduced, not
claimed) and where a contribution could plausibly sit.

## Algorithms used here (all known)

| Topic | Reference | Used for |
|---|---|---|
| Multi-objective shortest path (MOSP) | P. Hansen (1980), "Bicriterion path problems", *Multiple Criteria Decision Making: Theory and Application*, LNEMS 177, 109–127 | label-correcting Pareto search, and the fact that the front can grow exponentially in the worst case |
| MOSP, label setting | E. Q. V. Martins (1984), "On a multicriteria shortest path problem", *EJOR* 16(2), 236–245 | the label/dominance scheme in `src/pareto.bend` (here run as Bellman-Ford rounds) |
| Resource-constrained shortest path | G. Y. Handler, I. Zang (1980), "A dual algorithm for the constrained shortest path problem", *Networks* 10(4), 293–309 | not implemented; the natural next step if hard time windows are added |
| Min-cost flow | R. K. Ahuja, T. L. Magnanti, J. B. Orlin (1993), *Network Flows*, Prentice Hall, ch. 9 | successive shortest paths and the negative-cycle optimality certificate in `src/flow.bend` |
| Tail risk | R. T. Rockafellar, S. Uryasev (2000), "Optimization of conditional value-at-risk", *Journal of Risk* 2(3), 21–41 | CVaR95 as the tail statistic |
| Multimodal freight planning (review) | M. SteadieSeifi, N. P. Dellaert, W. Nuijten, T. Van Woensel, R. Raoufi (2014), "Multimodal freight transportation planning: A literature review", *EJOR* 233(1), 1–15 | framing: this study is *operational/tactical* routing with seasonal capacity |
| Update of that review | "Optimization in multimodal freight transportation problems: A survey", *EJOR* (2021/2023), [ScienceDirect](https://www.sciencedirect.com/science/article/pii/S0377221721006263) | — |
| Stochastic routing (review) | two-part review of the stochastic vehicle routing problem, *EURO J. Transp. Logist.*, [Springer](https://link.springer.com/article/10.1007/s13676-016-0100-5) | background; VRP-centric, not corridor-centric |

Time-dependent shortest paths (Cooke & Halsey 1966; Orda & Rom 1990) are the
standard tool for departure-time dependence; they were **not** used, because
this model is monthly (see `assumptions.md`), and the citations were not
re-verified in this pass.

## Systematic-ish search (September 2026)

30 OpenAlex queries + 11 Semantic Scholar queries (7 rate-limited) + 14 web
searches (Google Scholar, SciELO, BDTD, university repositories), in English and
Portuguese; ~2,450 records screened, 35 papers kept, 36/36 DOIs resolved through
Crossref. Query log and coverage matrix: [`litsearch/queries.csv`](litsearch/queries.csv),
[`litsearch/papers.csv`](litsearch/papers.csv). No Scopus/WoS access, and Brazilian
theses are poorly indexed in OpenAlex: this is absence of evidence, not proof of
absence, and ESALQ/USP and COPPE theses are the likeliest gap.

The three elements screened for:

1. **multi-objective** routing (cost, time, risk);
2. **seasonal / time-varying capacity** inside a capacitated flow;
3. **stochastic disruptions with recourse** (re-routing) and tail risk (CVaR).

### The four papers that must be cited and compared against

- **M. Marto, V. Chkoniya, E. B. Couto, T. M. P. Pinto, A. Agra, M. S. Reis (2026),
  "A biobjective stochastic model for intermodal supply chains: application to the
  corn and soybean flows", *Ind. Eng. Chem. Res.* 65(8), 4451–4470,
  [doi:10.1021/acs.iecr.5c02623](https://doi.org/10.1021/acs.iecr.5c02623)** — the
  closest on method: two-stage stochastic MILP, **expected cost vs CVaR**, corn and
  soybean, with Itaqui as a supply node. No seasonal capacity; uncertainty is
  demand/cost, not link failure; the network is European/North-African
  distribution, not the MT inland corridors. **Pairing multi-objective with CVaR on
  soybean flows is therefore not new.**
- **S. A. dos Reis, J. E. Leal, A. M. T. Thomé (2023), "A two-stage stochastic
  linear programming model for tactical planning in the soybean supply chain",
  *Logistics* 7(3), 49, [doi:10.3390/logistics7030049](https://doi.org/10.3390/logistics7030049)**
  — Brazilian, **stochastic with fixed recourse** (243 scenarios, take-or-pay
  rail/road contracts). Uncertainty is prices, crop failure and demand; recourse
  adjusts contracted volumes, not the route; no CVaR, no Pareto front.
- **G. F. L'Her, A. Schweikert, X. Espinet, L. de Melo, M. R. Deinert (2024),
  "Transport resilience and adaptation to climate impacts — a case study on
  agricultural transport in Brazil", *Studies in Computational Intelligence*,
  243–250, [doi:10.1007/978-3-031-53503-1_20](https://doi.org/10.1007/978-3-031-53503-1_20)**
  — Brazilian soybean export network **under link disruption with re-routing**
  (>10% cost impact on most main routes). Deterministic link removals, no
  probabilities, no recourse policy, no tail metric.
- **B. T. G. Garcia, A. S. de Medeiros, F. A. C. do Nascimento, M. A. V. da Silva
  (2022), "Impact of drought on the life cycle of barge transport", *Civil
  Engineering Journal* 8(12), 2693–2705,
  [doi:10.28991/cej-2022-08-12-02](https://doi.org/10.28991/cej-2022-08-12-02)** —
  models **convoy size on the Madeira as a function of river level** (9 barges in
  the dry season vs a full convoy). The best published Brazilian source to
  calibrate this model's low-water capacity factors; it is an LCA, not an
  optimization.

### Method analogues outside Brazil

- Wang & Liu (2022), *Transport* 37(4), 291–309,
  [doi:10.3846/transport.2022.17067](https://doi.org/10.3846/transport.2022.17067) —
  two-stage stochastic programme with probabilistic **terminal disruptions**,
  flow reassignment as recourse, and **CVaR**: the closest analogue of layer 3.
- Gbadegoye, Camur & Li (2025), *IJTST*, [doi:10.1016/j.ijtst.2025.07.004](https://doi.org/10.1016/j.ijtst.2025.07.004) — road–rail, capacity uncertainty, CVaR.
- Sharifi, Fang & Amin (2023), *Sust. Prod. Consum.* 40, 297–317, [doi:10.1016/j.spc.2023.07.006](https://doi.org/10.1016/j.spc.2023.07.006) — multi-objective + stochastic soybean **network design** (not corridor routing).
- Vinke, van Koningsveld, van Dorsser & Baart (2022), *Climate Risk Management* 35, 100400, [doi:10.1016/j.crm.2022.100400](https://doi.org/10.1016/j.crm.2022.100400) — water level → draft → transport capacity on the Rhine: the rigour benchmark for element 2.
- Aliano Filho, Rocco & Morábito (2024), *IJSS: O&L* 11(1), 2337442, [doi:10.1080/23302674.2024.2337442](https://doi.org/10.1080/23302674.2024.2337442) — the one Brazilian grain-chain Pareto front (cost × CO₂, corn).

## Brazil-specific work (found)

Static / single-objective Brazilian corridor models (element 0 of 3), including
work on the very same corridor (Morales et al., JTL 2013, Sorriso→Santarém),
Ferrogrão (Rocha & Caixeta-Filho, PODes 2018), transshipment terminals in MT
(de Morais et al., *Sustainability* 2023) and multi-period harvest/off-season
planning (Vieira et al., *Logistics* 2026) — full list in `litsearch/papers.csv`:

- "Análise de modelo intermodal para escoamento da produção da soja no centro oeste brasileiro", *Journal of Transport Literature*, [SciELO](https://www.scielo.br/j/jtl/a/NgnGcNh6tJVV9rrx9KZm73h/) — intermodal soy-flow model for the Centre-West.
- "Otimização da logística de transporte da soja do MATOPIBA destinada à exportação", *Revista de Economia e Agronegócio*, [UFV](https://periodicos.ufv.br/rea/article/view/13250) — LP/MIP allocation of MATOPIBA soy flows.
- "Método de otimização de rotas intermodais" (2022) and "Optimization of soybean outflow routes from Mato Grosso, Brazil" (*IJIER*) — MT route optimization with a MILP solver (GUSEK), [PDF](https://downloads.editoracientifica.com.br/articles/221010614.pdf), [IJIER](https://scholarsjournal.net/ijier/article/view/2502).
- ESALQ-LOG (USP) runs a research line on optimization of agro-logistics systems and publishes SIFRECA freight data, [ESALQ-LOG](https://esalqlog.esalq.usp.br/optimizacao).

## Where a contribution could sit (result of the search)

**No paper found combines the three elements** — for Brazil or anywhere else in
agricultural/bulk multimodal freight. Three papers combine two of the three, none
of them on the MT corridors.

What is **not** new: multi-objective + CVaR on soybean flows (Marto et al. 2026);
stochastic recourse in a Brazilian soybean chain (Reis et al. 2023); re-routing
after disruption in the Brazilian export network (L'Her et al. 2024); seasonal
river capacity as a physical mechanism (Garcia et al. 2022; Vinke et al. 2022).

What no screened paper has: **element 2 inside the optimization** — seasonal,
low-water- and peak-driven capacity in a capacitated flow, coupled to a
multi-objective front and to disruption recourse with tail risk, on the MT →
Arco Norte / Santos corridors. That is the narrow claim this study can make, and
it must be checked against Scopus/WoS and Brazilian theses before publication.
