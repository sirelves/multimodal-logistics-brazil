# Stylized export network: soybean from the Sorriso (MT) cluster to Shanghai.
# Terminals are split into one node per mode, joined by transfer legs, so a
# change of mode is just another arc with its own cost, time and capacity.
import Base
import ./graph.bend as G
import ./params.bend as P
import ./season.bend as S

# ---- nodes ----
def SOR() -> U32:
  0
def SIN() -> U32:
  1
def LRV() -> U32:
  2
def RON() -> U32:
  3
def RON_RAIL() -> U32:
  4
def LRV_RAIL() -> U32:
  5
def SIN_RAIL() -> U32:
  6
def MIR() -> U32:
  7
def MIR_BARGE() -> U32:
  8
def PVH() -> U32:
  9
def PVH_BARGE() -> U32:
  10
def SSZ() -> U32:
  11
def PNG() -> U32:
  12
def STM() -> U32:
  13
def BAR() -> U32:
  14
def ITA() -> U32:
  15
def SSZ_SHIP() -> U32:
  16
def PNG_SHIP() -> U32:
  17
def STM_SHIP() -> U32:
  18
def BAR_SHIP() -> U32:
  19
def ITA_SHIP() -> U32:
  20
def CHN() -> U32:
  21
def MIR_RAIL() -> U32:
  22
# a super-source feeding the three origin regions, and the eastern corridors
def SRC() -> U32:
  23
def CAN() -> U32:
  24
def PRI() -> U32:
  25
def ITQ() -> U32:
  26
def ITQ_SHIP() -> U32:
  27
# the Ferrovia Norte-Sul loading terminal eastern MT trucks use (Porto Nacional
# / Aguiarnopolis, TO) and its rail side
def PNC() -> U32:
  28
def PNC_RAIL() -> U32:
  29

def n_nodes() -> Nat:
  30n

def node_name(+i: U32) -> String:
  +names : List<&2, String> = ["Sorriso", "Sinop", "Lucas do Rio Verde", "Rondonopolis", "Rondonopolis (rail)",
    "Lucas (rail)", "Sinop (rail)", "Miritituba", "Miritituba (barge)", "Porto Velho",
    "Porto Velho (barge)", "Santos", "Paranagua", "Santarem", "Barcarena", "Itacoatiara",
    "Santos (ship)", "Paranagua (ship)", "Santarem (ship)", "Barcarena (ship)", "Itacoatiara (ship)",
    "Shanghai", "Miritituba (rail)", "Mato Grosso", "Canarana", "Primavera do Leste",
    "Itaqui", "Itaqui (ship)", "Porto Nacional", "Porto Nacional (rail)"]
  Maybe.default(&2, String, List.get(&2, String, names, U32.to_nat(i)), "?")

# ---- infrastructure that may or may not exist ----
def EXISTING() -> U32:
  0
def FERROGRAO() -> U32:
  1
def RUMO_EXT() -> U32:
  2

# km: distance (0 for transfer / port legs)
# fc, fh: fixed R$/t and hours (handling, waiting); cap: kt/month
# fx: seasonal effect bits (season.bend); infra: which build it needs
type Leg is Data:
  Leg{id: U32, src: U32, dst: U32, mode: U32, km: F32, fc: F32, fh: F32, cap: F32, fx: U32, infra: U32}

# portx scales the capacity of the five export terminals (legs 19..23);
# friction is an extra R$/t on every leg that enters a northern corridor
# (legs 3, 4, 7: the BR-163 and BR-364 truck hauls), a stand-in for whatever
# keeps cargo out of the Arco Norte beyond corridor cost -- contracts, terminal
# ownership, origins further south. Fitted in simulations/validation.bend.
type Scenario is Data:
  Scenario{ferrograo: Bool, rumo_ext: Bool, drought: Bool, blocked: List<&2, U32>, portx: F32, friction: F32}

def base() -> Scenario:
  Scenario{False{}, False{}, False{}, [], 1.0, 0.0}

def drought() -> Scenario:
  Scenario{False{}, False{}, True{}, [], 1.0, 0.0}

def ferrograo() -> Scenario:
  Scenario{True{}, False{}, False{}, [], 1.0, 0.0}

def rumo() -> Scenario:
  Scenario{False{}, True{}, False{}, [], 1.0, 0.0}

def rails() -> Scenario:
  Scenario{True{}, True{}, False{}, [], 1.0, 0.0}

def with_drought(+sc: Scenario) -> Scenario:
  Scenario{f, r, d, b, x, fr} = sc
  Scenario{f, r, True{}, b, x, fr}

def with_ports(+sc: Scenario, +k: F32) -> Scenario:
  Scenario{f, r, d, b, x, fr} = sc
  Scenario{f, r, d, b, (x * k : F32), fr}

def with_blocked(+sc: Scenario, +ids: List<&2, U32>) -> Scenario:
  Scenario{f, r, d, b, x, fr} = sc
  Scenario{f, r, d, List.append(&2, U32, ids, b), x, fr}

def with_friction(+sc: Scenario, +k: F32) -> Scenario:
  Scenario{f, r, d, b, x, fr} = sc
  Scenario{f, r, d, b, x, k}

# BR-163 north of Sorriso (truck legs to Miritituba and Santarem) blocked
def br163_blocked() -> Scenario:
  with_blocked(base(), [3, 7])

def big() -> F32:
  99999.0

# every road leg carries the monthly price factor; the northern ones also the rains
def rp() -> U32:
  S.ROAD_PRICE()

def rd() -> U32:
  (S.RAINY_ROAD() .|. S.ROAD_PRICE() : U32)

def legs() -> List<&2, Leg>:
  +R = P.ROAD()
  +T = P.RAIL()
  +B = P.BARGE()
  +H = P.SHIP()
  +X = P.XFER()
  # road from the farm cluster (distances: USDA AgTransport legs; Sinop and
  # Lucas are short hops off the BR-163)
  [Leg{0, SOR(), SIN(), R, 80.0, 0.0, 0.0, big(), rp(), EXISTING()},
   Leg{1, SOR(), LRV(), R, 60.0, 0.0, 0.0, big(), rp(), EXISTING()},
   Leg{2, SOR(), RON(), R, 615.0, 0.0, 0.0, big(), rp(), EXISTING()},
   Leg{3, SOR(), MIR(), R, 1081.0, 0.0, 0.0, big(), rd(), EXISTING()},
   Leg{4, SOR(), PVH(), R, 1017.0, 0.0, 0.0, big(), rd(), EXISTING()},
   Leg{5, SOR(), SSZ(), R, 1915.0, 0.0, 0.0, big(), rp(), EXISTING()},
   Leg{6, SOR(), PNG(), R, 2031.0, 0.0, 0.0, big(), rp(), EXISTING()},
   Leg{7, SOR(), STM(), R, 1410.0, 0.0, 0.0, big(), rd(), EXISTING()},
   # truck -> other mode at the inland terminals: the transshipment is already
   # inside the rail and barge quotes, so only time and capacity are charged
   Leg{8, RON(), RON_RAIL(), X, 0.0, 0.0, 24.0, 2000.0, 0, EXISTING()},
   Leg{9, LRV(), LRV_RAIL(), X, 0.0, 0.0, 24.0, 830.0, 0, RUMO_EXT()},
   Leg{10, SIN(), SIN_RAIL(), X, 0.0, 0.0, 24.0, 2000.0, 0, FERROGRAO()},
   Leg{11, MIR(), MIR_BARGE(), X, 0.0, 0.0, 36.0, 3040.0, 0, EXISTING()},
   Leg{12, PVH(), PVH_BARGE(), X, 0.0, 0.0, 36.0, 790.0, 0, EXISTING()},
   # rail
   Leg{13, RON_RAIL(), SSZ(), T, 1640.0, 0.0, 0.0, 2000.0, 0, EXISTING()},
   Leg{14, LRV_RAIL(), RON_RAIL(), T, 750.0, 0.0, 0.0, 830.0, 0, RUMO_EXT()},
   Leg{15, SIN_RAIL(), MIR_RAIL(), T, 933.0, 0.0, 0.0, 2000.0, 0, FERROGRAO()},
   # barge
   Leg{16, MIR_BARGE(), STM(), B, 246.0, 0.0, 0.0, 890.0, S.TAPAJOS_LOW(), EXISTING()},
   Leg{17, MIR_BARGE(), BAR(), B, 966.0, 0.0, 0.0, 2150.0, S.TAPAJOS_LOW(), EXISTING()},
   Leg{18, PVH_BARGE(), ITA(), B, 1060.0, 0.0, 0.0, 790.0, S.MADEIRA_LOW(), EXISTING()},
   # export terminals: elevation onto the ship, base line-up, peak line-ups are
   # seasonal; capacity = the highest month of MT grain ever shipped through the
   # port (Comex Stat 2023-2026), i.e. a revealed lower bound
   Leg{19, SSZ(), SSZ_SHIP(), X, 0.0, P.elevation(), 72.0, 2700.0, S.PORT_PEAK_SOUTH(), EXISTING()},
   Leg{20, PNG(), PNG_SHIP(), X, 0.0, P.elevation(), 72.0, 270.0, S.PORT_PEAK_SOUTH(), EXISTING()},
   Leg{21, STM(), STM_SHIP(), X, 0.0, P.elevation(), 48.0, 890.0, S.PORT_PEAK_NORTH(), EXISTING()},
   Leg{22, BAR(), BAR_SHIP(), X, 0.0, P.elevation(), 48.0, 2150.0, S.PORT_PEAK_NORTH(), EXISTING()},
   Leg{23, ITA(), ITA_SHIP(), X, 0.0, P.elevation(), 48.0, 790.0, S.PORT_PEAK_NORTH(), EXISTING()},
   # ocean to Shanghai: a per-port price (USDA), same 38-day voyage
   Leg{24, SSZ_SHIP(), CHN(), H, 22000.0, P.ocean_santos(), 0.0, big(), 0, EXISTING()},
   Leg{25, PNG_SHIP(), CHN(), H, 22000.0, P.ocean_paranagua(), 0.0, big(), 0, EXISTING()},
   Leg{26, STM_SHIP(), CHN(), H, 22000.0, P.ocean_santarem(), 0.0, big(), 0, EXISTING()},
   Leg{27, BAR_SHIP(), CHN(), H, 22000.0, P.ocean_barcarena(), 0.0, big(), 0, EXISTING()},
   Leg{28, ITA_SHIP(), CHN(), H, 22000.0, P.ocean_itacoatiara(), 0.0, big(), 0, EXISTING()},
   # rail -> barge at Miritituba (Ferrograo terminus)
   Leg{29, MIR_RAIL(), MIR_BARGE(), X, 0.0, 0.0, 12.0, 2000.0, 0, FERROGRAO()},
   # --- three origin regions fed by a super-source; the caps of legs 30..32 are
   # the region's share of the month's volume, set by set_supply() ---
   Leg{30, SRC(), SOR(), X, 0.0, 0.0, 0.0, big(), 0, EXISTING()},
   Leg{31, SRC(), CAN(), X, 0.0, 0.0, 0.0, big(), 0, EXISTING()},
   Leg{32, SRC(), PRI(), X, 0.0, 0.0, 0.0, big(), 0, EXISTING()},
   # Northeast MT (Canarana) and Southeast MT (Primavera do Leste): USDA quotes
   # them only to the southern ports and to Itaqui, which is what they use
   Leg{33, CAN(), SSZ(), R, 1529.0, 0.0, 0.0, big(), rp(), EXISTING()},
   Leg{34, CAN(), PNG(), R, 1730.0, 0.0, 0.0, big(), rp(), EXISTING()},
   Leg{35, CAN(), ITQ(), R, 1894.0, 0.0, 0.0, big(), rp(), EXISTING()},
   Leg{36, PRI(), SSZ(), R, 1450.0, 0.0, 0.0, big(), rp(), EXISTING()},
   Leg{37, PRI(), PNG(), R, 1569.0, 0.0, 0.0, big(), rp(), EXISTING()},
   # road to the Rondonopolis rail terminal (distances approximate)
   Leg{38, PRI(), RON(), R, 215.0, 0.0, 0.0, big(), rp(), EXISTING()},
   Leg{39, CAN(), RON(), R, 600.0, 0.0, 0.0, big(), rp(), EXISTING()},
   # Itaqui: elevation and ocean (USDA Sao Luis), capacity = observed peak
   Leg{40, ITQ(), ITQ_SHIP(), X, 0.0, P.elevation(), 48.0, 460.0, S.PORT_PEAK_NORTH(), EXISTING()},
   Leg{41, ITQ_SHIP(), CHN(), H, 22000.0, P.ocean_itaqui(), 0.0, big(), 0, EXISTING()},
   # Ferrovia Norte-Sul: truck from eastern MT to the Porto Nacional terminal,
   # then rail to Itaqui (distances approximate; no published intermodal tariff
   # was found, so the rail rate is the same as Rumo's)
   Leg{42, CAN(), PNC(), R, 700.0, 0.0, 0.0, big(), rp(), EXISTING()},
   Leg{43, PNC(), PNC_RAIL(), X, 0.0, 0.0, 24.0, 1000.0, 0, EXISTING()},
   Leg{44, PNC_RAIL(), ITQ(), T, 1430.0, 0.0, 0.0, 1000.0, 0, EXISTING()}]

def n_legs() -> Nat:
  45n

# Supply of each origin region for this month, kt: North MT (Sorriso),
# Northeast MT (Canarana), Southeast MT (Primavera do Leste).
def set_supply(+as: List<&2, G.Arc>, +north: F32, +ne: F32, +se: F32) -> List<&2, G.Arc>:
  G.set_cap(G.set_cap(G.set_cap(as, 30, north), 31, ne), 32, se)

def built(+sc: Scenario, +infra: U32) -> Bool:
  Scenario{f, r, d, b, x, fr} = sc
  Bool.or(U32.is_eq(infra, EXISTING()),
    Bool.or(Bool.and(f, U32.is_eq(infra, FERROGRAO())), Bool.and(r, U32.is_eq(infra, RUMO_EXT()))))

def is_blocked(+sc: Scenario, +id: U32) -> Bool:
  Scenario{f, r, d, b, x, fr} = sc
  G.mem(b, id)

def risk_of(+p: F32) -> F32:
  (0.0 - F32.log((1.0 - F32.min(p, 0.95) : F32)) : F32)

def Scenario.portx(+sc: Scenario) -> F32:
  Scenario{f, r, d, b, x, fr} = sc
  x

def Scenario.friction(+sc: Scenario) -> F32:
  Scenario{f, r, d, b, x, fr} = sc
  fr

# the truck hauls that enter a northern corridor
def is_north(+id: U32) -> Bool:
  Bool.or(U32.is_eq(id, 3), Bool.or(U32.is_eq(id, 4), U32.is_eq(id, 7)))

def is_port(+id: U32) -> Bool:
  Bool.and(U32.is_ge(id, 19), U32.is_le(id, 23))

def to_arc(+sc: Scenario, +l: Leg, +f: S.SF) -> G.Arc:
  Leg{id, s, d, m, km, fc, fh, cap0, fx, inf} = l
  S.SF{cmul, tadd, capmul, pmul, open} = f
  +cap = (cap0 * Bool.pick(F32, is_port(id), Scenario.portx(sc), 1.0) : F32)
  +cost = ((P.fixed(m) + fc + km * P.rate(m)) * cmul
    + Bool.pick(F32, is_north(id), Scenario.friction(sc), 0.0) : F32)
  +hours = (fh + km / P.speed(m) + tadd : F32)
  G.Arc{id, s, d, m, cost, hours, risk_of((P.p_base(m) * pmul : F32)), (cap * capmul : F32)}

def usable(+sc: Scenario, +l: Leg, +f: S.SF) -> Bool:
  Leg{id, s, d, m, km, fc, fh, cap, fx, inf} = l
  S.SF{cmul, tadd, capmul, pmul, open} = f
  Bool.and(Bool.and(open, (cap * capmul > 0.0 : F32)),
    Bool.and(built(sc, inf), Bool.not(is_blocked(sc, id))))

def Leg.fx(+l: Leg) -> U32:
  Leg{id, s, d, m, km, fc, fh, cap, fx, inf} = l
  fx

def Scenario.drought(+sc: Scenario) -> Bool:
  Scenario{f, r, d, b, x, fr} = sc
  d

def eval_legs(+ls: List<&2, Leg>, +month: U32, +sc: Scenario) -> List<&2, G.Arc>:
  match ls:
    case []:
      []
    case l <> rest:
      +f = S.factor(Leg.fx(l), month, Scenario.drought(sc))
      G.cons_if(usable(sc, l, f), to_arc(sc, l, f), eval_legs(rest, month, sc))

# The evaluated graph for one month (0 = Jan) and scenario.
def arcs(+month: U32, +sc: Scenario) -> List<&2, G.Arc>:
  eval_legs(legs(), month, sc)

def port_step(+here: Bool, +i: U32, +rest: String) -> String:
  match here:
    case True{}:
      node_name((i - 24 + 11 : U32))
    case False{}:
      rest

# Export port a route uses (the node before its ship leg), for labels.
def port_of(+all: List<&2, G.Arc>, +ids: List<&2, U32>) -> String:
  match ids:
    case []:
      "-"
    case i <> rest:
      port_step(Bool.and(U32.is_ge(i, 24), U32.is_le(i, 28)), i, port_of(all, rest))
