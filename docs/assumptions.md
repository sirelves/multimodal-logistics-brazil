# Assumptions and limitations

Read this before any number in `results.md`. The network is **stylized**: its
parameters are order-of-magnitude values (see `data-sources.md`, section 7), not a
calibration. The algorithms are exact for the model; the model is not the world.

## Structure

1. **One origin.** Sorriso stands for the north-central MT cluster. Real exports
   come from many origins competing for the same corridors.
2. **Capacity shares are assumptions.** Santos (1,800 kt/month) and Paranaguá
   (1,000) are the share *available to this cluster*, not port nameplate. The
   headline finding "terminals bind before inland links" depends on them, hence
   the `ports x1.5` sensitivity in `capacity.svg`.
3. **Ocean leg is neutral**: same price, distance and time from every port,
   because no source for the Arco Norte vs Santos differential was found. Port
   choice is therefore driven only by the inland legs and terminals. Deeper drafts
   (larger ships) at some ports are ignored.
4. **Linear costs.** No economies of scale, no congestion pricing except through
   capacity steps and seasonal multipliers. Truck supply is unlimited at the
   seasonal rate; in reality freight spikes (+60% y/y) come from truck scarcity.
5. **Monthly time.** A shipment sees one month's parameters from farm to ship;
   no departure-time dependence inside the month, no inventory carried between
   months, constant supply of 4,000 kt/month in the seasonal runs (harvest-shaped
   supply is future work).
6. **Two railways as what-ifs.** Ferrogrão (planned) and the Rumo extension to
   Lucas do Rio Verde (under construction, 2031) use the same rail rate, speed and
   risk as the existing Rumo line. Their real tariffs are unknown; the Ferrogrão
   break-even tariff is computed in `results.md`.

## Interruptions

7. **Independent legs.** One trip's legs fail independently. A BR-163 blockade or
   a low-water closure actually hits every shipment at once; the flow model
   handles those as scenarios (`br163_blocked`, `drought`), the Monte Carlo does
   not correlate them.
8. **Probabilities and delays are not sourced** (`data-sources.md` [N]). Results
   are about mechanisms and relative sizes, not about the level of risk.
9. **Adaptive policy is myopic**: it re-plans once, at the first failure, with the
   failure's duration revealed; it cannot pre-position or split cargo.

## Numerics and tooling

10. **F32 only** (the only float in Bend 2). Costs are ~10²–10³ with a relative
    tolerance of 10⁻⁵ in dominance tests; totals are sums of < 10³ terms.
11. **Bend 2 checker normalizes closed terms without sharing.** A
    `Bool.pick(c, x <> rest, rest)` whose `rest` is a recursive call made the
    checker exponential on a closed input (the runtime was fine). All such
    patterns are written as a `match` in a helper (`G.cons_if`, `P.keep_if`, ...).
12. The native build (`make bench`) needs clang ≥ 14; the interpreter
    (`bend file.bend`) does not.
