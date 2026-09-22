# Evaluated multimodal graph: one list of arcs for a fixed month and scenario.
# Unavailable arcs (closed, blocked, infrastructure not built) are simply not
# in the list, so no algorithm needs a special case for them.
import Base

# cost  R$/t for the whole leg (freight + handling)
# hours transit + waiting time for the leg
# risk  -ln(1 - p), p = probability the leg is interrupted during the trip;
#       additive along a path, P(any interruption) = 1 - exp(-sum risk)
# cap   kt/month the leg can carry (flow model only)
type Arc is Data:
  Arc{id: U32, src: U32, dst: U32, mode: U32, cost: F32, hours: F32, risk: F32, cap: F32}

def Arc.id(+a: Arc) -> U32:
  Arc{id, s, d, m, c, h, r, k} = a
  id

def Arc.src(+a: Arc) -> U32:
  Arc{id, s, d, m, c, h, r, k} = a
  s

def Arc.dst(+a: Arc) -> U32:
  Arc{id, s, d, m, c, h, r, k} = a
  d

def Arc.mode(+a: Arc) -> U32:
  Arc{id, s, d, m, c, h, r, k} = a
  m

def Arc.cost(+a: Arc) -> F32:
  Arc{id, s, d, m, c, h, r, k} = a
  c

def Arc.hours(+a: Arc) -> F32:
  Arc{id, s, d, m, c, h, r, k} = a
  h

def Arc.risk(+a: Arc) -> F32:
  Arc{id, s, d, m, c, h, r, k} = a
  r

def Arc.cap(+a: Arc) -> F32:
  Arc{id, s, d, m, c, h, r, k} = a
  k

def inf() -> F32:
  1.0e30

def none() -> U32:
  4294967295

# ---- small list helpers (Nat-indexed, reusable elements) ----

def nth_f(+xs: List<&2, F32>, +i: Nat) -> F32:
  match xs:
    case []:
      inf()
    case h <> t:
      match i:
        case 0n:
          h
        case 1n+k:
          nth_f(t, k)

def nth_u(+xs: List<&2, U32>, +i: Nat) -> U32:
  match xs:
    case []:
      none()
    case h <> t:
      match i:
        case 0n:
          h
        case 1n+k:
          nth_u(t, k)

def set_f(+xs: List<&2, F32>, +i: Nat, +v: F32) -> List<&2, F32>:
  match xs:
    case []:
      []
    case h <> t:
      match i:
        case 0n:
          v <> t
        case 1n+k:
          h <> set_f(t, k, v)

def set_u(+xs: List<&2, U32>, +i: Nat, +v: U32) -> List<&2, U32>:
  match xs:
    case []:
      []
    case h <> t:
      match i:
        case 0n:
          v <> t
        case 1n+k:
          h <> set_u(t, k, v)

def found(+hit: Bool, +a: Arc, +rest: Maybe<&2, Arc>) -> Maybe<&2, Arc>:
  match hit:
    case True{}:
      Some{a}
    case False{}:
      rest

def arc_at(+xs: List<&2, Arc>, +id: U32) -> Maybe<&2, Arc>:
  match xs:
    case []:
      None{}
    case a <> t:
      found(U32.is_eq(Arc.id(a), id), a, arc_at(t, id))

def fill_f(+n: Nat, +v: F32) -> List<&2, F32>:
  List.replicate(F32, n, v)

def fill_u(+n: Nat, +v: U32) -> List<&2, U32>:
  List.replicate(U32, n, v)

def sum_f(+xs: List<&2, F32>) -> F32:
  match xs:
    case []:
      0.0
    case h <> t:
      (h + sum_f(t) : F32)

def cons_maybe(+m: Maybe<&2, Arc>, +rest: List<&2, Arc>) -> List<&2, Arc>:
  match m:
    case None{}:
      rest
    case Some{a}:
      a <> rest

# Arcs whose id is in the list (path reconstruction).
def pick_arcs(+all: List<&2, Arc>, +ids: List<&2, U32>) -> List<&2, Arc>:
  match ids:
    case []:
      []
    case i <> rest:
      cons_maybe(arc_at(all, i), pick_arcs(all, rest))

# x <> rest when keep, else rest; a match so rest is never duplicated
def cons_if(+keep: Bool, +x: Arc, +rest: List<&2, Arc>) -> List<&2, Arc>:
  match keep:
    case True{}:
      x <> rest
    case False{}:
      rest

def without(+xs: List<&2, Arc>, +id: U32) -> List<&2, Arc>:
  match xs:
    case []:
      []
    case a <> t:
      cons_if(Bool.not(U32.is_eq(Arc.id(a), id)), a, without(t, id))

def mem(+xs: List<&2, U32>, +x: U32) -> Bool:
  match xs:
    case []:
      False{}
    case h <> t:
      Bool.or(U32.is_eq(h, x), mem(t, x))
