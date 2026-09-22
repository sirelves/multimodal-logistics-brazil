# Assumptions and limitations

Read this before any number in `results.md`. Tariffs, distances, the monthly
road-price factor, ocean freight per port, terminal capacities and the volume to
allocate are **calibrated** (USDA AgTransport, Comex Stat; `data-sources.md` §7).
Everything about interruptions is not. The algorithms are exact for the model; the
model is not the world — and `results.md` §2 measures exactly how far off it is.

## Structure

1. **Three origin regions** (North MT / Sorriso, Northeast MT / Canarana,
   Southeast MT / Primavera do Leste), with USDA tariffs for each, fed by a
   super-source whose arc capacities carry the origin split. Only the northern
   region has northern corridors, which is what the USDA quotes imply. The split
   comes from IBGE municipal production over IMEA's macro-regions (49.7 / 25.1 /
   25.2), renormalized over the three: the western and central-southern regions,
   ~31% of MT production, have no node. Every result outside `results.md` §2 still
   uses the single Sorriso origin, to isolate corridor mechanisms.
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
6. **The friction parameter** (R$/t added to the northern truck hauls) is kept in
   the code and swept in `validation_friction.csv`, but the fitted model does not
   use it: with three origins its best value is zero.
6b. **The Ferrovia Norte-Sul corridor to Itaqui** (truck 950 km to the Porto
   Nacional / Colinas terminals, then 1,125 km of rail) uses approximate distances
   and ANTT's tariff **ceiling** for grain. Real contracts settle below a ceiling,
   so the corridor is modelled at its most expensive; even so the model never uses
   it, while 5–7% of MT grain does.
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
