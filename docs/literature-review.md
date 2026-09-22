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

## Brazil-specific work (found)

- "Análise de modelo intermodal para escoamento da produção da soja no centro oeste brasileiro", *Journal of Transport Literature*, [SciELO](https://www.scielo.br/j/jtl/a/NgnGcNh6tJVV9rrx9KZm73h/) — intermodal soy-flow model for the Centre-West.
- "Otimização da logística de transporte da soja do MATOPIBA destinada à exportação", *Revista de Economia e Agronegócio*, [UFV](https://periodicos.ufv.br/rea/article/view/13250) — LP/MIP allocation of MATOPIBA soy flows.
- "Método de otimização de rotas intermodais" (2022) and "Optimization of soybean outflow routes from Mato Grosso, Brazil" (*IJIER*) — MT route optimization with a MILP solver (GUSEK), [PDF](https://downloads.editoracientifica.com.br/articles/221010614.pdf), [IJIER](https://scholarsjournal.net/ijier/article/view/2502).
- ESALQ-LOG (USP) runs a research line on optimization of agro-logistics systems and publishes SIFRECA freight data, [ESALQ-LOG](https://esalqlog.esalq.usp.br/optimizacao).

## Where a contribution could sit (absence of evidence, not a confirmed gap)

The Brazil papers found are **static, single-objective LP/MIP allocations**
(least-cost corridor choice under fixed capacities). None found combines, for the
MT → Arco Norte / Santos corridors:

1. a **multi-objective** (cost, time, interruption risk) front per month;
2. **seasonal capacity** (low water, harvest peaks) inside a min-cost flow;
3. **stochastic interruptions** with a **recourse** policy (re-plan at a failure) and tail statistics.

Each piece is textbook. The combination, applied to this corridor with open
code, is the plausible contribution; the search covered a handful of queries, so
this must be checked against a proper systematic search (Scopus / Web of
Science: "soybean" AND "intermodal" AND ("stochastic" OR "robust" OR "multi-objective") AND "Brazil")
before any novelty claim.
