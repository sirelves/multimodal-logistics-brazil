# Model and algorithms

## Network

A directed graph *G = (V, A)* evaluated for one **month** *m* and one **scenario**
*s* (which railways exist, drought or not, blocked legs, terminal-capacity scale).

- A terminal is split into **one node per mode** (e.g. `Rondonopolis` and
  `Rondonopolis (rail)`), joined by a **transfer leg** carrying its own handling
  cost, time and capacity. A change of mode is then just an arc, and no algorithm
  needs a transfer special case. A test checks that every route in every front
  changes mode only through a transfer leg (it caught a real bug: the Ferrogrão
  first ended directly on the barge node, skipping the rail→barge transshipment).
- A leg that does not exist in *(m, s)* — closed river, unbuilt railway, blocked
  road — is **absent from the arc list**. Again no special case.
- Seasonal effects are a bitmask per leg (`src/season.bend`); each active effect
  multiplies cost / capacity / interruption probability or adds hours, and they
  compose.

28 nodes, 42 legs (37 in the base network). Three origin regions behind a
super-source, destination `Shanghai`, six export ports.

Each arc *a* carries

| symbol | meaning | unit |
|---|---|---|
| c(a) | freight + handling | R$/t |
| h(a) | transit + waiting | hours |
| r(a) = −ln(1 − p(a)) | interruption "risk", additive | — |
| u(a) | capacity | kt/month |

so along a path *P*: cost Σc, time Σh, and P(at least one interruption) =
1 − exp(−Σr) under independence.

## 1. Pareto front (`src/pareto.bend`)

Labels *(c, h, r, path)* at every node; *x* dominates *y* iff
*x ≤ y* in all three criteria (relative tolerance 10⁻⁵). Each round relaxes every
arc: extend the labels at its tail, merge them into the head's front, dropping
dominated ones. Because all three criteria are non-negative and additive, every
Pareto-optimal path is simple, has at most |V|−1 arcs, and |V| rounds reach the
exact front (Hansen 1980; Martins 1984 is the label-setting variant). Worst-case
front size is exponential; here fronts have 2–5 routes and a month takes a few ms.

**Validated** against exhaustive enumeration of all simple paths
(`src/brute.bend`) in six month/scenario cases, plus: no label of a front
dominates another, and the minimum of five different scalarizations over the
front equals a Bellman-Ford optimum (the front contains every supported point).

## 2. Capacitated allocation (`src/flow.bend`)

Ship *S* kt/month from origin to destination minimizing Σ f(a)·g(a), with the
generalized cost g = c + VOT·h, subject to 0 ≤ f ≤ u and conservation.
Successive shortest paths on the residual graph (Bellman-Ford, since backward
arcs have negative cost). Costs are linear, so this is the exact min-cost flow;
if demand exceeds the max flow the model ships the max flow and reports an
infinite marginal cost.

**Validated** by a hand-solved toy case and, on the real network, by the
optimality certificate "no negative cycle in the residual graph" (Ahuja et al.
1993, thm 9.1) plus capacity and conservation checks.

The **marginal cost** reported is the generalized cost of the last augmenting
path, i.e. what the last tonne pays: the logistics supply curve.

## 3. Interruptions (`src/risk.bend`)

Each leg of a trip fails independently with probability p(a); a failure costs an
exponential delay (mean by mode) valued at a mode-specific **stall cost**
(idle truck, barge, train, ship + cargo holding).

- **fixed**: follow the planned route and wait out every failure.
- **adaptive**: follow the expected-cost route; at the *first* failure, knowing
  its duration, compare waiting against paying a re-planning fee and taking the
  expected-cost route from the failed leg's origin on the graph without that
  leg; choose the cheaper in expectation. Later failures are waited out.

The **expected-cost route** is exact for the fixed policy: replace each arc's
cost by c + VOT·h + p·stall·delay and run a shortest path (linearity of
expectation). The Monte Carlo mean of the fixed policy is tested against this
closed form (agreement within 0.1% at 2¹⁴ trips).

Random numbers are a stateless hash of (trip, leg, salt) (lowbias32), so trips are
independent pure calls: the 2^d trips form a binary tree of **parallel calls**
(`a b = f(x) g(y)` in Bend), and every month uses the same seeds (common random
numbers, so month-to-month differences are not sampling noise).

Statistics: mean, P95, CVaR95 (mean of the worst 5%; Rockafellar & Uryasev 2000), max.

## 4. Validation (`simulations/validation.bend`)

The monthly volume MT actually exported (Comex Stat, `src/observed.bend`) is fed
to layer 2 and the resulting port split is compared with the observed one; the
error metric is the mean absolute difference of the six port shares, in percentage
points. Supply enters through a super-source whose three arcs carry the origin
split between North, Northeast and Southeast MT; their capacities are set per
month by `N.set_supply`.

Two free parameters are swept on a grid — the origin split (0.1 steps on the
simplex) and a friction on the northern truck hauls (R$0–100/t) — fitted on 2024
and then applied unchanged to 2025. Both whole grids are published
(`results/validation_fit.csv`, `results/validation_friction.csv`), not only their
minima.

## What is *not* modelled

See `assumptions.md`: monthly (not hourly) time, no correlated disruptions, no
truck-fleet or rolling-stock limits, linear costs, one origin, calibration-free
parameters.
