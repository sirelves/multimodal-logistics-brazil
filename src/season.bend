# Seasonal effects. A leg carries a bitmask of effects; each effect is active
# in some months and multiplies cost / capacity / interruption probability or
# adds waiting hours. Effects compose, so a leg needs no special case.
import Base

type SF is Data:
  SF{cmul: F32, tadd: F32, capmul: F32, pmul: F32, open: Bool}

def SF.id() -> SF:
  SF{1.0, 0.0, 1.0, 1.0, True{}}

def SF.cmul(+f: SF) -> F32:
  SF{c, t, k, p, o} = f
  c

def SF.tadd(+f: SF) -> F32:
  SF{c, t, k, p, o} = f
  t

def compose(+a: SF, +b: SF) -> SF:
  SF{c1, t1, k1, p1, o1} = a
  SF{c2, t2, k2, p2, o2} = b
  SF{(c1 * c2 : F32), (t1 + t2 : F32), (k1 * k2 : F32), (p1 * p2 : F32), Bool.and(o1, o2)}

# effect bits
def RAINY_ROAD() -> U32:
  1
def ROAD_PRICE() -> U32:
  2
def MADEIRA_LOW() -> U32:
  4
def TAPAJOS_LOW() -> U32:
  8
def PORT_PEAK_SOUTH() -> U32:
  16
def PORT_PEAK_NORTH() -> U32:
  32

# month m (0 = Jan) in the inclusive range a..b, wrapping past December
def within(+m: U32, +a: U32, +b: U32) -> Bool:
  Bool.pick(Bool, (a <= b : U32), Bool.and((m >= a : U32), (m <= b : U32)),
    Bool.or((m >= a : U32), (m <= b : U32)))

def has(+mask: U32, +bit: U32) -> Bool:
  Bool.not(U32.is_zero((mask .&. bit : U32)))

def when(+on: Bool, +f: SF) -> SF:
  Bool.pick(SF, on, f, SF.id())

# Dec-Mar rains: slower trucks, more interruptions (unpaved access, landslides, blockades)
def rainy_road(+m: U32) -> SF:
  when(within(m, 11, 2), SF{1.0, 24.0, 1.0, 3.0, True{}})

# Monthly road-freight factor, from the USDA Brazil truck-rate index
# (US$/t per 100 miles, monthly, 2018-2025): each month's mean divided by its
# year's mean. The harvest peak is Feb-Apr; the trough is Nov-Dec.
def road_price(+m: U32) -> SF:
  +f : List<&2, F32> = [0.944, 1.075, 1.120, 1.076, 1.028, 1.041, 1.052, 1.017, 0.986, 0.918, 0.883, 0.861]
  SF{Maybe.default(&2, F32, List.get(&2, F32, f, U32.to_nat(m)), 1.0), 0.0, 1.0, 1.0, True{}}

# Aug-Nov low water on the Madeira: partial loads; a drought year closes Sep-Nov
def madeira_low(+m: U32, +drought: Bool) -> SF:
  +low = when(within(m, 7, 10), SF{1.25, 24.0, 0.5, 3.0, True{}})
  +shut = when(Bool.and(drought, within(m, 8, 10)), SF{1.0, 0.0, 0.0, 1.0, False{}})
  compose(low, shut)

# Sep-Nov low water on the Tapajos/Amazon: lighter drafts; worse in a drought
def tapajos_low(+m: U32, +drought: Bool) -> SF:
  +on = within(m, 8, 10)
  +f = Bool.pick(SF, drought, SF{1.30, 48.0, 0.4, 4.0, True{}}, SF{1.10, 12.0, 0.7, 2.0, True{}})
  when(on, f)

# Feb-May ship line-ups at the export terminals
def port_peak_south(+m: U32) -> SF:
  when(within(m, 1, 4), SF{1.0, 120.0, 1.0, 2.0, True{}})

def port_peak_north(+m: U32) -> SF:
  when(within(m, 1, 4), SF{1.0, 72.0, 1.0, 2.0, True{}})

def pick(+mask: U32, +bit: U32, +f: SF) -> SF:
  when(has(mask, bit), f)

def factor(+mask: U32, +m: U32, +drought: Bool) -> SF:
  compose(pick(mask, RAINY_ROAD(), rainy_road(m)),
  compose(pick(mask, ROAD_PRICE(), road_price(m)),
  compose(pick(mask, MADEIRA_LOW(), madeira_low(m, drought)),
  compose(pick(mask, TAPAJOS_LOW(), tapajos_low(m, drought)),
  compose(pick(mask, PORT_PEAK_SOUTH(), port_peak_south(m)),
    pick(mask, PORT_PEAK_NORTH(), port_peak_north(m)))))))

def month_name(+m: U32) -> String:
  String.take(String.drop("JanFebMarAprMayJunJulAugSepOctNovDec", U32.to_nat((m * 3 : U32))), 3n)
