# Formatting helpers shared by the simulations: numbers, routes, CSV, markers.
import Base
import ./graph.bend as G
import ./network.bend as N
import ./params.bend as Q
import ./svg.bend as V

# x rounded to d decimals (d = 0, 1 or 2)
def fmt(+x: F32, +d: Nat) -> String:
  +k = F32.pow(10.0, F32.from_nat(d))
  F32.show((F32.round((x * k : F32)) / k : F32))

def month(+m: U32) -> String:
  String.take(String.drop("JanFebMarAprMayJunJulAugSepOctNovDec", U32.to_nat((m * 3 : U32))), 3n)

def stops(+all: List<&2, G.Arc>, +ids: List<&2, U32>) -> String:
  match ids:
    case []:
      ""
    case i <> rest:
      +a = Maybe.default(&2, G.Arc, G.arc_at(all, i), G.Arc{0, 0, 0, 0, 0.0, 0.0, 0.0, 0.0})
      " > " ++ N.node_name(G.Arc.dst(a)) ++ stops(all, rest)

# "Sorriso > Miritituba > ... > Shanghai"
def route(+all: List<&2, G.Arc>, +ids: List<&2, U32>) -> String:
  N.node_name(N.SOR()) ++ stops(all, ids)

def csv(+cells: List<&2, String>) -> String:
  String.join(cells, ",") ++ "\n"

def lines(+rows: List<&2, String>) -> String:
  String.concat(rows)

# filled circle markers at data points
def dots(+f: V.Frame, +pts: List<&2, V.XY>, +color: String, +r: String) -> String:
  match pts:
    case []:
      ""
    case V.XY{x, y} <> rest:
      "<circle cx=\"" ++ V.pxs(V.px(f, x)) ++ "\" cy=\"" ++ V.pxs(V.py(f, y)) ++ "\" r=\"" ++ r
        ++ "\" fill=\"" ++ color ++ "\" stroke=\"#fcfcfb\" stroke-width=\"1.5\"/>\n" ++ dots(f, rest, color, r)

# small text label next to a data point
def tag(+f: V.Frame, +x: F32, +y: F32, +s: String) -> String:
  V.text((V.px(f, x) + 7.0 : F32), (V.py(f, y) - 6.0 : F32), "start", "11", V.ink2(), s)

def months() -> List<&2, U32>:
  [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11]

def mode_seq(+all: List<&2, G.Arc>, +ids: List<&2, U32>, +last: U32) -> String:
  match ids:
    case []:
      ""
    case i <> rest:
      +m = G.Arc.mode(Maybe.default(&2, G.Arc, G.arc_at(all, i), G.Arc{0, 0, 0, 4, 0.0, 0.0, 0.0, 0.0}))
      +skip = Bool.or(U32.is_eq(m, Q.XFER()), Bool.or(U32.is_eq(m, Q.SHIP()), U32.is_eq(m, last)))
      +here = Bool.pick(String, skip, "", Bool.pick(String, U32.is_eq(last, 99), "", "+") ++ Q.mode_name(m))
      here ++ mode_seq(all, rest, Bool.pick(U32, skip, last, m))

# "road+barge via Santarem"
def short(+all: List<&2, G.Arc>, +ids: List<&2, U32>) -> String:
  mode_seq(all, ids, 99) ++ " via " ++ N.port_of(all, ids)
