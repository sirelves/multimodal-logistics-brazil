# Observed exports of grain (soybean NCM 12019000 + corn 10059010) originating
# in Mato Grosso, by exit customs unit and month, in kt. Source: Comex Stat
# (MDIC), https://api-comexstat.mdic.gov.br/general, filters state = 52 (MT),
# flow = export, detail = urf, pulled 2026-09-22.
#
# Caveats: the customs unit (URF) is not exactly the port -- Barcarena/Vila do
# Conde clears as ALF-BELEM and Itacoatiara as PORTO DE MANAUS; MT grain leaving
# through Itaqui, Santana, Vitoria and the southern ports (5-10% of the total)
# has no route in this model and is left out here, so the shares are over the
# five modelled ports only.
import Base

type Obs is Data:
  Obs{year: U32, month: U32, santos: F32, paranagua: F32, santarem: F32, barcarena: F32, itacoatiara: F32}

def table() -> List<&2, Obs>:
  [
   Obs{2024, 0, 1558.5, 36.3, 425.7, 839.6, 442.1},
   Obs{2024, 1, 1082.9, 110.5, 673.4, 1444.7, 533.9},
   Obs{2024, 2, 2295.4, 97.0, 541.0, 1286.2, 296.9},
   Obs{2024, 3, 1960.7, 47.4, 482.6, 1495.6, 236.0},
   Obs{2024, 4, 2067.6, 64.5, 476.3, 1310.4, 324.9},
   Obs{2024, 5, 2047.9, 90.9, 602.0, 1280.5, 511.3},
   Obs{2024, 6, 1830.8, 38.5, 889.2, 1495.9, 537.0},
   Obs{2024, 7, 1988.6, 13.7, 516.7, 1746.0, 231.3},
   Obs{2024, 8, 2080.1, 5.0, 696.8, 1434.7, 8.9},
   Obs{2024, 9, 2609.3, 28.8, 391.1, 928.6, 62.4},
   Obs{2024, 10, 2117.5, 9.8, 246.0, 397.5, 37.8},
   Obs{2024, 11, 1286.6, 3.3, 149.2, 764.0, 113.4},
   Obs{2025, 0, 912.1, 18.7, 65.5, 346.3, 340.0},
   Obs{2025, 1, 1273.7, 126.3, 359.5, 1017.0, 284.8},
   Obs{2025, 2, 1815.7, 158.9, 527.0, 1113.4, 495.5},
   Obs{2025, 3, 2010.0, 152.0, 575.6, 1172.3, 337.7},
   Obs{2025, 4, 2431.9, 78.1, 437.4, 1278.8, 490.2},
   Obs{2025, 5, 2294.6, 148.6, 520.7, 1139.0, 786.5},
   Obs{2025, 6, 2322.7, 126.3, 828.3, 1121.2, 496.6},
   Obs{2025, 7, 2193.1, 108.7, 814.5, 1544.1, 303.3},
   Obs{2025, 8, 1629.3, 96.4, 791.1, 1600.4, 337.7},
   Obs{2025, 9, 2697.5, 62.2, 472.9, 1036.3, 270.5},
   Obs{2025, 10, 2171.7, 36.6, 257.2, 907.1, 209.7},
   Obs{2025, 11, 2097.5, 36.8, 453.9, 1148.9, 416.9}]

def Obs.year(+o: Obs) -> U32:
  Obs{y, m, a, b, c, d, e} = o
  y

def Obs.month(+o: Obs) -> U32:
  Obs{y, m, a, b, c, d, e} = o
  m

# flow through port i (0 = Santos, 1 = Paranagua, 2 = Santarem, 3 = Barcarena,
# 4 = Itacoatiara), kt in that month
def Obs.port(+o: Obs, +i: U32) -> F32:
  Obs{y, m, a, b, c, d, e} = o
  Bool.pick(F32, U32.is_eq(i, 0), a,
    Bool.pick(F32, U32.is_eq(i, 1), b,
      Bool.pick(F32, U32.is_eq(i, 2), c,
        Bool.pick(F32, U32.is_eq(i, 3), d, e))))

def Obs.total(+o: Obs) -> F32:
  Obs{y, m, a, b, c, d, e} = o
  (a + b + c + d + e : F32)

def at(+os: List<&2, Obs>, +year: U32, +month: U32) -> Obs:
  match os:
    case []:
      Obs{0, 0, 0.0, 0.0, 0.0, 0.0, 0.0}
    case o <> rest:
      +hit = Bool.and(U32.is_eq(Obs.year(o), year), U32.is_eq(Obs.month(o), month))
      Bool.pick(Obs, hit, o, at(rest, year, month))

def month_of(+year: U32, +month: U32) -> Obs:
  at(table(), year, month)
