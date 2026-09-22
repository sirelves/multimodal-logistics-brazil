# Every numeric assumption of the stylized network lives here.
# Values are order-of-magnitude, not calibrated; docs/data-sources.md gives the
# source or the reason for each one. Units: R$/t, hours, kt/month, km.
import Base

# modes
def ROAD() -> U32:
  0
def RAIL() -> U32:
  1
def BARGE() -> U32:
  2
def SHIP() -> U32:
  3
def XFER() -> U32:
  4

def mode_name(+m: U32) -> String:
  Bool.pick(String, U32.is_eq(m, 0), "road",
    Bool.pick(String, U32.is_eq(m, 1), "rail",
      Bool.pick(String, U32.is_eq(m, 2), "barge",
        Bool.pick(String, U32.is_eq(m, 3), "ship", "transfer"))))

# Freight = fixed(mode) + rate(mode) * km, in R$/t, fitted to USDA AgTransport
# "Brazil soybean transportation" quarterly tables, 2024Q1-2025Q3, at R$5.5/US$:
#   road  least squares over the six North MT (Sorriso) legs: US$1.41 + 0.0417/km
#   rail  Rondonopolis-Santos, 1,640 km: US$0.0289/t.km
#   barge Itaituba-Santarem (246 km) and Itaituba-Barcarena (966 km)
# The barge quote includes transshipment at the Itaituba (Miritituba) terminal
# and the rail quote its yard, so the inland transfer legs carry no extra cost.
# Ocean is a per-port price, not a rate (see network.bend).
def rate(+m: U32) -> F32:
  Bool.pick(F32, U32.is_eq(m, 0), 0.2294,
    Bool.pick(F32, U32.is_eq(m, 1), 0.1587,
      Bool.pick(F32, U32.is_eq(m, 2), 0.0992,
        Bool.pick(F32, U32.is_eq(m, 3), 0.0, 0.0))))

def fixed(+m: U32) -> F32:
  Bool.pick(F32, U32.is_eq(m, 0), 7.8,
    Bool.pick(F32, U32.is_eq(m, 2), 20.9, 0.0))

# ocean freight to Shanghai, R$/t, USDA 2024Q1-2025Q3 means at R$5.5/US$
# (Santos 35.8, Paranagua 37.3, Santarem 38.8, Barcarena 39.6 US$/t;
#  Itacoatiara is not quoted and is assumed equal to Barcarena)
def ocean_santos() -> F32:
  196.9
def ocean_paranagua() -> F32:
  205.2
def ocean_santarem() -> F32:
  213.4
def ocean_barcarena() -> F32:
  217.8
def ocean_itacoatiara() -> F32:
  217.8

# grain elevation onto the ship, R$/t (ANTAQ tariff table, Terminal XXXIX Santos)
def elevation() -> F32:
  55.0

# effective speed including stops, km/h
def speed(+m: U32) -> F32:
  Bool.pick(F32, U32.is_eq(m, 0), 28.0,
    Bool.pick(F32, U32.is_eq(m, 1), 18.0,
      Bool.pick(F32, U32.is_eq(m, 2), 9.0,
        Bool.pick(F32, U32.is_eq(m, 3), 24.0, 1.0))))

# baseline probability that one leg is interrupted during one trip
def p_base(+m: U32) -> F32:
  Bool.pick(F32, U32.is_eq(m, 0), 0.020,
    Bool.pick(F32, U32.is_eq(m, 1), 0.010,
      Bool.pick(F32, U32.is_eq(m, 2), 0.010,
        Bool.pick(F32, U32.is_eq(m, 3), 0.005, 0.010))))

# mean delay when a leg of that mode is interrupted, hours
def delay(+m: U32) -> F32:
  Bool.pick(F32, U32.is_eq(m, 0), 72.0,
    Bool.pick(F32, U32.is_eq(m, 1), 96.0,
      Bool.pick(F32, U32.is_eq(m, 2), 240.0,
        Bool.pick(F32, U32.is_eq(m, 3), 120.0, 120.0))))

# cost of one tonne standing still for one hour while a leg is interrupted,
# R$/t/h: the idle vehicle (truck ~R$1,100/day for 37 t; barge, train and
# ship charter shares) plus the cargo's own holding cost vot()
def stall(+m: U32) -> F32:
  Bool.pick(F32, U32.is_eq(m, 0), 1.2,
    Bool.pick(F32, U32.is_eq(m, 1), 0.3,
      Bool.pick(F32, U32.is_eq(m, 2), 0.3,
        Bool.pick(F32, U32.is_eq(m, 3), 0.15, 0.1))))

# cost of holding one tonne one hour (capital + storage + demurrage share), R$/t/h
def vot() -> F32:
  0.05

# extra cost of re-planning a shipment mid-route (re-contracting, re-handling), R$/t
def reroute_fee() -> F32:
  25.0

# BRL per USD, only to read ocean freight quoted in USD
def brl_usd() -> F32:
  5.5
