# Data sources for the stylized network

Compiled 2026-09-22 by a time-boxed web research pass (not exhaustive, and the
claims below were **not independently re-verified**). Confidence tags:
**[S]** source found · **[A]** approximate / inferred · **[N]** no source found.
Every value actually used by the model is in `src/params.bend` and
`src/network.bend`; section 8 maps each one to this file.

## 1. Distances

| Leg | Mode | Distance | Conf. | Source |
|---|---|---|---|---|
| Sorriso→Rondonópolis | road | ~610 km (calculators give 573–613) | [A] | [Rotamapas](https://www.rotamapas.com.br/distancia-entre-sorriso-e-rondonopolis) |
| Rondonópolis→Santos | rail (Rumo Malha Norte + Paulista) | ~1,655 km | [S] | [Diário do Litoral](https://www.diariodolitoral.com.br/santos/ferrovia-que-deve-unir-mato-grosso-ao-porto-de-santos-da-passo/176899/) |
| Sorriso→Santos | road | ~1,990–2,170 km | [S] | [Rotamapas](https://www.rotamapas.com.br/distancia-entre-sorriso-e-santos); [Brasilagro](https://www.brasilagro.com.br/conteudo/asfaltada-estrada-da-soja-impulsiona-exportacao-mas-permanece-precaria.html) |
| Sorriso→Paranaguá | road | ~2,150 km | [S] | [Rotamapas](https://www.rotamapas.com.br/distancia-entre-paranagua-e-sorriso) |
| Sorriso→Miritituba (BR-163) | road | ~1,070 km | [S] | [adistanciaentre.com](https://www.adistanciaentre.com/br/distancia-entre-miritituba-pa-e-sorriso-mt-brasil/DistanciaHistoria/1478256.aspx) |
| Miritituba→Santarém | barge (Tapajós) | ~300 km | [A] | origin unclear |
| Miritituba→Barcarena/Vila do Conde | barge | ~1,000 km, ~3 days | [S] | [ESALQ-LOG](https://esalqlog.esalq.usp.br/rios-viabilizam-corredor-logistico) |
| Sorriso→Porto Velho | road | — | [N] | model uses 1,350 km [A] |
| Sorriso→Santarém (BR-163) | road | — | [N] | model uses 1,400 km [A] |
| Porto Velho→Itacoatiara | barge (Madeira) | 1,060 km; convoys ~55 h | [S] | [DNIT](http://www.dnit.gov.br/modais-2/aquaviario/hidrovia-do-madeira), [Portogente](https://portogente.com.br/artigos/71184-a-hidrovia-do-rio-madeira) |
| Sinop→Miritituba (Ferrogrão, EF-170, planned) | rail | 933 km | [S] | [gov.br/transportes](https://www.gov.br/transportes/pt-br/assuntos/noticias/2025/12/aprovacao-dos-estudos-tecnicos-da-ferrograo-ef-170-marca-avanco-nas-concessoes-ferroviarias-do-ministerio-dos-transportes) |
| Rondonópolis→Lucas do Rio Verde (Rumo MT extension, under construction) | rail | ~743–750 km | [S] | [Revista Ferroviária](https://revistaferroviaria.com.br/2025/05/com-avanco-de-ferrovia-no-mt-rumo-prepara-fase-2-da-obra/) |
| Santos→Shanghai | ocean | ~11,300–13,300 nm, 33–37 days | [S] | [ports.com](http://ports.com/sea-route/port-of-shanghai,china/port-of-santos,brazil/) |
| Barcarena / Paranaguá / Itacoatiara→Shanghai | ocean | — | [N] | model sets every port equal to Santos |

## 2. Freight costs

- Road Sorriso→Miritituba: IMEA-tracked spot rates **R$171–345/t** over 2024–2026 (R$223/t in 2025; R$277–345/t in the Jan 2026 peak) [S] — [Notícias Agrícolas](https://www.noticiasagricolas.com.br/noticias/soja/414555-congestionamento-nos-portos-encarece-a-logistica-e-tira-ainda-mais-do-preco-da-soja-ao-produtor.html), [CNA](https://cnabrasil.org.br/noticias/preco-do-frete-para-transportar-soja-continua-subindo-em-mato-grosso-aponta-imea).
- Road Sorriso→Santos: ~R$300/t in one snapshot; R$150–300/t across dates [S/A] — [Brasilagro](https://www.brasilagro.com.br/conteudo/asfaltada-estrada-da-soja-impulsiona-exportacao-mas-permanece-precaria.html). SIFRECA reported y/y harvest increases of +65% (Sorriso→Rondonópolis) and +61% (Sorriso→Santos) in tight-truck periods [S] — [SIFRECA](https://sifreca.esalq.usp.br/mercado/soja).
- Rail and barge R$/t·km, transshipment and port handling R$/t: **no consolidated source found** [N]. Follow-up: ANTT tariff resolutions, EPL/Infra S.A. PNL, SIFRECA rail series.
- Ocean Santos→China: one estimate ≈ **US$18.5/t** (30 kt vessel, US$15k/day, 37 days) [A] — [Forbes Agro](https://forbes.com.br/forbes-agro/2024/07/faltam-navios-e-frete-maritimo-deve-subir-10-ate-a-virada-do-ano/). Santos vs Arco Norte differential: not found [N].

## 3. Times

- Madeira barge ~55 h; Tapajós/Amazonas barge ~3 days for 1,000 km; ocean 33–37 days [S] (sources above).
- Port line-ups in the harvest peak: Santos ~21 days on average (7–46), Paranaguá ~20 days, above 30 in bad years; demurrage US$25–30k/day per vessel [S] — [Agrolink](https://www.agrolink.com.br/noticias/fila-ultrapassa-os-100-navios-em-paranagua_151360.html), [Exame](https://exame.com/agro/fila-de-navio-e-frete-mais-caro-os-gargalos-que-pressionam-a-safra-recorde-do-brasil-em-2024-25/).
- Road transit days: not found [N].

## 4. Capacities (Mt/year)

| Asset | Capacity | Conf. | Source |
|---|---|---|---|
| Rumo Malha Norte (traffic) | 24.3 Mt in 2023 | [S] | [ANTT](https://www.gov.br/antt/pt-br/assuntos/ferrovias/concessoes-ferroviarias/rumo-malha-norte-s-a) |
| Miritituba ETCs combined | ~18 Mt nameplate; 12.9 Mt moved in 2022 | [S] | [FENATAC](https://www.fenatac.org.br/post/implanta%C3%A7%C3%A3o-de-seis-terminais-deve-elevar-em-80-o-escoamento-em-miritituba) |
| Vila do Conde / Barcarena | ~14 Mt/yr planned | [S] | [LCA / Logcluster](https://lca.logcluster.org/214-brazil-port-barcarena-vila-do-conde) |
| Itacoatiara + Santarém + Vila do Conde (2015) | ~15 Mt/yr | [S] | [Página Rural](https://www.paginarural.com.br/noticia/116102/porto-de-itacoatiara-e-2ordf-rota-do-mt-para-escoar-produtos-a-exportacao) |
| Porto Velho transshipment | ~5 Mt/yr | [A] | same |
| Santos, one grain terminal (Cargill) | 5 Mt/yr | [S] | [Agrolink](https://www.agrolink.com.br/noticias/cargill-vai-ampliar-terminal-em-santos_25062.html) |

## 5. Seasonality and disruption

- MT soybean harvest peak **Feb–Mar** [S] — CONAB crop bulletins.
- Madeira: high water Feb–May (20-barge convoys), low water Jul–Oct (9-barge convoys) [S] — [Portogente](https://portogente.com.br/artigos/71184-a-hidrovia-do-rio-madeira). 2023 and 2024 droughts interrupted barge navigation; 67–71 cm depth near Porto Velho in 2024, night navigation banned [S] — [Agência Brasil](https://agenciabrasil.ebc.com.br/geral/noticia/2024-09/seca-do-rio-madeira-pode-se-agravar-ainda-mais-aponta-sgb), [CNN Brasil](https://www.cnnbrasil.com.br/economia/macroeconomia/seca-historica-na-regiao-amazonica-interrompe-navegacao-de-barcacas-de-graos/).
- BR-163: trucker blockades (Aug 2017); rainy-season mud and queues on the Pará stretch [S] — [Estado de Minas](https://www.em.com.br/app/noticia/economia/2017/08/03/internas_economia,889176/caminhoneiros-bloqueiam-dois-pontos-da-br-163-em-mt.shtml), [Amazonas Atual](https://amazonasatual.com.br/br-163-no-para-estrada-da-soja-e-o-cenario-do-caos-logistico-brasileiro/). Rainy-season months (Nov–Apr) are inference [A].
- 2018 national truckers' strike, ~10 days [S, secondary].
- Frequency/duration statistics of interruptions: **not found** [N]. Every probability in the model is an assumption.

## 6. Infrastructure status (as reported, Sep 2026; not re-verified)

- **Ferrogrão (EF-170)**: studies approved by ANTT (Dec 2025), with TCU; environmental licensing pending; auction expected 2H2026.
- **FICO (EF-354)**: ~36% complete (Apr 2025).
- **Rumo MT extension**: phase 1 (Rondonópolis→Campo Verde, 162 km) 2026; full line to Lucas do Rio Verde targeted 2031.

## 7. What the model uses, and why

| Parameter (file) | Value | Basis |
|---|---|---|
| road rate (`params.bend`) | R$0.15/t·km | reproduces R$160/t Sorriso→Miritituba and R$300/t Sorriso→Santos, inside the sourced ranges |
| rail rate | R$0.09/t·km | [N]; set so rail is ~40% cheaper per t·km than road (common rule of thumb, unsourced) |
| barge rate | R$0.05/t·km | [N]; order of magnitude |
| ocean | R$0.01/t·km × 22,000 km = R$220/t ≈ US$40/t, 38 days, **same for every port** | [A]; above the US$18.5/t charter estimate; neutral across ports on purpose |
| speeds | road 28, rail 18, barge 9, ship 24 km/h (effective) | [A]; barge 1,000 km ≈ 4.6 days vs 3 sourced |
| transfer / port handling | R$15–30/t, 12–72 h | [N] |
| harvest road premium | ×1.20 in Feb–Apr | [A]; far below the +60% y/y spikes |
| port peak line-ups | +120 h south, +72 h north, Feb–May | [A]; cargo dwell, not the 20-day vessel queue |
| low water | Madeira Aug–Nov cap ×0.5, cost ×1.25; Tapajós Sep–Nov cap ×0.7, cost ×1.1; drought: Madeira closed Sep–Nov, Tapajós cap ×0.4, cost ×1.3 | [A] shaped on the sourced 2023–24 events |
| capacities (kt/month) | rail 2,000; Miritituba ETC 1,500; Porto Velho 420; Barcarena 1,170; Santarém 500–600; Itacoatiara 420; Santos 1,800 and Paranaguá 1,000 *available to this cluster* | annual [S] figures / 12; the Santos and Paranaguá shares are pure assumptions |
| interruption probability per trip | road 2%, rail 1%, barge 1%, ship 0.5%, terminal 1%; ×3 rainy road, ×2–4 low water, ×2 port peak | [N] |
| mean delay if interrupted | road 72 h, rail 96 h, barge 240 h, ship/terminal 120 h (exponential) | [N] |
| stall cost | road R$1.2/t/h (truck ~R$1,100/day, 37 t), rail/barge 0.3, ship 0.15, terminal 0.1 | [A] |
| value of time | R$0.05/t/h (soy ~R$2,200/t at ~12%/yr ≈ R$0.03, plus storage) | [A] |
| re-planning fee | R$25/t | [N] |
