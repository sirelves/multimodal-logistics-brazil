# Numeric helpers over F32 (the only float type Bend 2 has).
import Base

def pick(c: Bool, a: F32, b: F32) -> F32:
  match c:
    case True{}:
      a
    case False{}:
      b

def neg(x: F32) -> F32:
  (0.0 - x : F32)

def sq(+x: F32) -> F32:
  (x * x : F32)

def pow4(+x: F32) -> F32:
  +y = (x * x : F32)
  (y * y : F32)

def pi() -> F32:
  F32.pi()

# Stefan-Boltzmann constant in Planck units, sigma = pi^2 / 60.
def sigma_sb() -> F32:
  +p = F32.pi()
  (p * p / 60.0 : F32)

def is_nan(+x: F32) -> Bool:
  F32.is_ne(x, x)

def is_finite(+x: F32) -> Bool:
  Bool.and(Bool.not(is_nan(x)), (F32.abs(x) < 3.0e38 : F32))

def sign_changed(+a: F32, +b: F32) -> Bool:
  Bool.or(Bool.and((a > 0.0 : F32), (b <= 0.0 : F32)),
    Bool.and((a < 0.0 : F32), (b >= 0.0 : F32)))

# Geometric grid point i of n between lo and hi (inclusive), lo, hi > 0.
def geom(+lo: F32, +hi: F32, +i: U32, +n: U32) -> F32:
  +f = (U32.to_f32(i) / U32.to_f32((n - 1 : U32)) : F32)
  F32.exp((F32.log(lo) + f * (F32.log(hi) - F32.log(lo)) : F32))

# Linear grid point i of n between lo and hi (inclusive).
def lin(+lo: F32, +hi: F32, +i: U32, +n: U32) -> F32:
  +f = (U32.to_f32(i) / U32.to_f32((n - 1 : U32)) : F32)
  (lo + f * (hi - lo) : F32)

def rel_err(+a: F32, +b: F32) -> F32:
  (F32.abs((a - b : F32)) / F32.max(F32.abs(b), 1.0e-30) : F32)
