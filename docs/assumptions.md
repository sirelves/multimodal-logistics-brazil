# Assumptions and limitations

Read this before any number in `results.md`. Tariffs, distances, the monthly
road-price factor, ocean freight per port, terminal capacities and the volume to
allocate are **calibrated** (USDA AgTransport, Comex Stat; `data-sources.md` §7).
Everything about interruptions is not. The algorithms are exact for the model; the
model is not the world — and `results.md` §2 measures exactly how far off it is.

## Structure

1. **One origin.** Sorriso stands for the whole of MT, which is wrong by ~1,000 km
   for the southeastern part of the state, and is the main reason the model cannot
   reproduce the observed port split (`results.md` §2). USDA publishes separate
   tariffs for North, Northeast and Southeast MT; using them is the next step.
2. **Terminal capacity = revealed floor.** Each port's capacity is the highest
   month of MT grain ever cleared through it (Comex Stat 2023–2026). That is a
   lower bound on what is available to MT, not nameplate capacity, and it is
   endogenous: Paranaguá looks small (270 kt/month) because MT ships little through
   it. The `ports ×1.5` sensitivity is still run for this reason.
3. **Ocean freight is now per port** (USDA), and the ranking matters: the Arco
   Norte is ~R$20/t *dearer* to Shanghai than Santos and cheaper to Hamburg. Only
   the China leg is modelled, so the model understates the north's advantage for
   European buyers. Draft limits are still ignored.
4. **Linear costs.** No economies of scale, no congestion pricing except through
   capacity steps and the monthly road-price factor. Truck supply is unlimited at
   that price; in reality harvest spikes come from truck scarcity. The factor is an
   average over 2018–2025, so a single extreme year is not represented.
5. **Monthly time.** A shipment sees one month's parameters from farm to ship; no
   departure-time dependence inside the month and no inventory carried between
   months. The seasonal runs use a flat 4,000 kt/month to isolate network effects;
   the validation runs use the observed monthly volume.
6. **The fitted friction (R$30/t)** on the northern truck legs is a free parameter
   with no direct source: it absorbs contracts, terminal ownership and origin
   heterogeneity. It is used only in the validation run; every other result uses
   friction 0.
7. **Two railways as what-ifs.** Ferrogrão (planned) and the Rumo extension to
   Lucas do Rio Verde (under construction, 2031) use the same rail rate, speed and
   risk as the existing Rumo line. Their real tariffs are unknown; the Ferrogrão
   break-even tariff is computed in `results.md`.

## Interruptions

8. **Independent legs.** One trip's legs fail independently. A BR-163 blockade or
   a low-water closure actually hits every shipment at once; the flow model
   handles those as scenarios (`br163_blocked`, `drought`), the Monte Carlo does
   not correlate them.
9. **Probabilities and delays are not sourced** (`data-sources.md` [N]). Results
   are about mechanisms and relative sizes, not about the level of risk.
10. **Adaptive policy is myopic**: it re-plans once, at the first failure, with the
   failure's duration revealed; it cannot pre-position or split cargo.

## Numerics and tooling

11. **F32 only** (the only float in Bend 2). Costs are ~10²–10³ with a relative
    tolerance of 10⁻⁵ in dominance tests; totals are sums of < 10³ terms.
12. **Bend 2 checker normalizes closed terms without sharing.** A
    `Bool.pick(c, x <> rest, rest)` whose `rest` is a recursive call made the
    checker exponential on a closed input (the runtime was fine). All such
    patterns are written as a `match` in a helper (`G.cons_if`, `P.keep_if`, ...).
13. The native build (`make bench`) needs clang ≥ 14; the interpreter
    (`bend file.bend`) does not.
