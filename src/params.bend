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

# freight rate, R$ per t per km
def rate(+m: U32) -> F32:
  Bool.pick(F32, U32.is_eq(m, 0), 0.15,
    Bool.pick(F32, U32.is_eq(m, 1), 0.09,
      Bool.pick(F32, U32.is_eq(m, 2), 0.05,
        Bool.pick(F32, U32.is_eq(m, 3), 0.01, 0.0))))

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
