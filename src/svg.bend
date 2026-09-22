# Minimal SVG line-chart / heatmap writer in pure Bend.
# Charts are static files (GitHub renders them as images), light theme.
import Base
import ./num.bend as N

type Frame is Data:
  Frame{x0: F32, x1: F32, y0: F32, y1: F32, logx: Bool, logy: Bool}

type XY is Data:
  XY{x: F32, y: F32}

type Series is Data:
  Series{pts: List<&2, XY>, color: String, dash: String, label: String}

# Canvas geometry (pixels).
def W() -> F32:
  760.0
def H() -> F32:
  540.0
def L() -> F32:
  84.0
def R() -> F32:
  24.0
def T() -> F32:
  56.0
def B() -> F32:
  134.0

def ink() -> String:
  "#0b0b0b"
def ink2() -> String:
  "#52514e"
def grid() -> String:
  "#e4e2dc"

# Categorical palette (fixed order).
def color(+i: Nat) -> String:
  match i:
    case 0n:
      "#2a78d6"
    case 1n:
      "#eb6834"
    case 2n:
      "#1baf7a"
    case 3n:
      "#eda100"
    case 4n:
      "#e87ba4"
    case 5n:
      "#008300"
    case 6n:
      "#4a3aa7"
    case _:
      "#e34948"

def Frame.lx(+f: Frame) -> Bool:
  Frame{x0, x1, y0, y1, lx, ly} = f
  lx

def Frame.x0(+f: Frame) -> F32:
  Frame{x0, x1, y0, y1, lx, ly} = f
  x0

def Frame.x1(+f: Frame) -> F32:
  Frame{x0, x1, y0, y1, lx, ly} = f
  x1

def Frame.y0(+f: Frame) -> F32:
  Frame{x0, x1, y0, y1, lx, ly} = f
  y0

def Frame.y1(+f: Frame) -> F32:
  Frame{x0, x1, y0, y1, lx, ly} = f
  y1

def Frame.ly(+f: Frame) -> Bool:
  Frame{x0, x1, y0, y1, lx, ly} = f
  ly

def tr(+log: Bool, +v: F32) -> F32:
  match log:
    case True{}:
      F32.log10(v)
    case False{}:
      v

# data -> pixel
def px(+f: Frame, +x: F32) -> F32:
  Frame{x0, x1, y0, y1, lx, ly} = f
  +a = tr(lx, x0)
  +b = tr(lx, x1)
  (L() + (tr(lx, x) - a) / (b - a) * (W() - L() - R()) : F32)

def py(+f: Frame, +y: F32) -> F32:
  Frame{x0, x1, y0, y1, lx, ly} = f
  +a = tr(ly, y0)
  +b = tr(ly, y1)
  (H() - B() - (tr(ly, y) - a) / (b - a) * (H() - T() - B()) : F32)

def ok_on(+log: Bool, +v: F32) -> Bool:
  match log:
    case True{}:
      Bool.and(N.is_finite(v), (v > 0.0 : F32))
    case False{}:
      N.is_finite(v)

# Pixel coordinate as text with one decimal, clamped far outside the canvas.
def pxs(+v: F32) -> String:
  +c = F32.clamp(v, (0.0 - 5000.0 : F32), 5000.0)
  F32.show((F32.round((c * 10.0 : F32)) / 10.0 : F32))

# SVG path data; a non-plottable point breaks the line.
def path(+f: Frame, +pts: List<&2, XY>, +pen: Bool) -> List<&2, String>:
  match pts:
    case []:
      []
    case XY{+x, +y} <> rest:
      +good = Bool.and(ok_on(Frame.lx(f), x), ok_on(Frame.ly(f), y))
      +cmd = Bool.pick(String, pen, "L", "M")
      +seg = Bool.pick(String, good, cmd ++ pxs(px(f, x)) ++ " " ++ pxs(py(f, y)) ++ " ", "")
      seg <> path(f, rest, good)

def esc(+s: String) -> String:
  s

def text(+x: F32, +y: F32, +anchor: String, +size: String, +fill: String,
  +body: String) -> String:
  "<text x=\"" ++ pxs(x) ++ "\" y=\"" ++ pxs(y) ++ "\" text-anchor=\"" ++ anchor
    ++ "\" font-size=\"" ++ size ++ "\" fill=\"" ++ fill ++ "\">" ++ body ++ "</text>\n"

def line(+x1: F32, +y1: F32, +x2: F32, +y2: F32, +stroke: String) -> String:
  "<line x1=\"" ++ pxs(x1) ++ "\" y1=\"" ++ pxs(y1) ++ "\" x2=\"" ++ pxs(x2)
    ++ "\" y2=\"" ++ pxs(y2) ++ "\" stroke=\"" ++ stroke ++ "\" stroke-width=\"1\"/>\n"

# ---- number formatting for tick labels ----

# Integer n with d decimals inserted, e.g. fmt_dec(125, 2) = "1.25".
def pad0(+n: Nat, +s: String) -> String:
  match n:
    case 0n:
      s
    case 1n+k:
      pad0(k, "0" ++ s)

def fmt_dec(+n: Nat, +d: Nat) -> String:
  match d:
    case 0n:
      Nat.show(n)
    case _:
      +s = pad0(Nat.sub(1n+d, String.length(Nat.show(n))), Nat.show(n))
      +k = Nat.sub(String.length(s), d)
      String.take(s, k) ++ "." ++ String.drop(s, k)

# value v on a tick grid whose step is 10^e (e may be negative)
def fmt_tick(+v: F32, +e: F32) -> String:
  +neg = (v < 0.0 : F32)
  +a = F32.abs(v)
  +digits = F32.max(0.0, N.neg(e))
  +n = F32.to_nat(F32.round((a * F32.pow(10.0, digits) : F32)))
  +body = fmt_dec(n, F32.to_nat(digits))
  Bool.pick(String, Bool.and(neg, Bool.not(Nat.is_eq(n, 0n))), "&#8722;" ++ body, body)

# ---- ticks ----

def nice_step(+span: F32) -> F32 & F32:
  +raw = (span / 5.0 : F32)
  +e = F32.floor(F32.log10(raw))
  +base = F32.pow(10.0, e)
  +r = (raw / base : F32)
  +mult = N.pick((r < 1.5 : F32), 1.0, N.pick((r < 3.5 : F32), 2.0, N.pick((r < 7.5 : F32), 5.0, 10.0)))
  +e2 = N.pick((mult > 5.0 : F32), (e + 1.0 : F32), e)
  ((mult * base : F32), e2)

def tick(+f: Frame, +v: F32, +label: String, +horiz: Bool) -> String:
  match horiz:
    case True{}:
      +x = px(f, v)
      line(x, T(), x, (H() - B() : F32), grid())
        ++ text(x, (H() - B() + 18.0 : F32), "middle", "12", ink2(), label)
    case False{}:
      +y = py(f, v)
      line(L(), y, (W() - R() : F32), y, grid())
        ++ text((L() - 8.0 : F32), (y + 4.0 : F32), "end", "12", ink2(), label)

# One tick per step from v while v <= stop; n is the fuel.
def lin_ticks(+n: Nat, +f: Frame, +v: F32, +stop: F32, +step: F32, +e: F32, +horiz: Bool) -> List<&2, String>:
  match n:
    case 0n:
      []
    case 1n+k:
      +keep = (v <= stop + step * 0.001 : F32)
      +here = Bool.pick(String, keep, tick(f, v, fmt_tick(v, e), horiz), "")
      here <> lin_ticks(k, f, (v + step : F32), stop, step, e, horiz)

def pow10_label(+e: F32) -> String:
  +k = F32.abs(e)
  +s = Nat.show(F32.to_nat(k))
  Bool.pick(String, (e < 0.0 : F32), "10<tspan dy=\"-6\" font-size=\"9\">&#8722;" ++ s ++ "</tspan>",
    "10<tspan dy=\"-6\" font-size=\"9\">" ++ s ++ "</tspan>")

def log_ticks(+n: Nat, +f: Frame, +e: F32, +stop: F32, +every: F32, +horiz: Bool) -> List<&2, String>:
  match n:
    case 0n:
      []
    case 1n+k:
      +keep = (e <= stop : F32)
      +here = Bool.pick(String, keep, tick(f, F32.pow(10.0, e), pow10_label(e), horiz), "")
      here <> log_ticks(k, f, (e + every : F32), stop, every, horiz)

def lin_axis(+f: Frame, +lo: F32, +hi: F32, se: F32 & F32, +horiz: Bool) -> List<&2, String>:
  (step, e) = se
  +s = step
  +first = (F32.ceil((lo / s - 0.0001 : F32)) * s : F32)
  lin_ticks(40n, f, first, hi, s, e, horiz)

def axis_ticks(+log: Bool, +f: Frame, +lo: F32, +hi: F32, +horiz: Bool) -> List<&2, String>:
  match log:
    case True{}:
      +a = F32.ceil((F32.log10(lo) - 0.0001 : F32))
      +b = F32.floor((F32.log10(hi) + 0.0001 : F32))
      +every = F32.max(1.0, F32.ceil(((b - a) / 7.0 : F32)))
      log_ticks(40n, f, a, b, every, horiz)
    case False{}:
      lin_axis(f, lo, hi, nice_step((hi - lo : F32)), horiz)

# ---- series ----

def series_svg(+f: Frame, +ss: List<&2, Series>) -> List<&2, String>:
  match ss:
    case []:
      []
    case Series{pts, col, dash, lab} <> rest:
      ("<path d=\"" ++ String.concat(path(f, pts, False{})) ++ "\" fill=\"none\" stroke=\""
        ++ col ++ "\" stroke-width=\"2\" stroke-linejoin=\"round\" stroke-linecap=\"round\" stroke-dasharray=\""
        ++ dash ++ "\"/>\n") <> series_svg(f, rest)

# Horizontal legend under the x-axis label; wraps to a second row.
def legend(+ss: List<&2, Series>, +x: F32, +y: F32) -> List<&2, String>:
  match ss:
    case []:
      []
    case Series{pts, col, dash, lab} <> rest:
      +w = (34.0 + 6.6 * F32.from_nat(String.length(lab)) + 18.0 : F32)
      +wrap = (x + w > W() - R() : F32)
      +x1 = N.pick(wrap, L(), x)
      +y1 = N.pick(wrap, (y + 18.0 : F32), y)
      ("<line x1=\"" ++ pxs(x1) ++ "\" y1=\"" ++ pxs(y1) ++ "\" x2=\"" ++ pxs((x1 + 22.0 : F32))
        ++ "\" y2=\"" ++ pxs(y1) ++ "\" stroke=\"" ++ col ++ "\" stroke-width=\"" ++ Bool.pick(String, List.is_empty(&2, XY, pts), "8", "2")
        ++ "\" stroke-dasharray=\"" ++ dash ++ "\"/>\n" ++ text((x1 + 30.0 : F32), (y1 + 4.0 : F32), "start", "12", ink(), lab))
        <> legend(rest, (x1 + w : F32), y1)

def count(+ss: List<&2, Series>) -> Nat:
  List.length(&2, Series, ss)

def legend_box(+ss: List<&2, Series>) -> String:
  Bool.pick(String, Nat.is_lt(count(ss), 2n), "", String.concat(legend(ss, L(), (H() - B() + 66.0 : F32))))

def header(+title: String, +sub: String) -> String:
  "<svg xmlns=\"http://www.w3.org/2000/svg\" viewBox=\"0 0 760 540\" width=\"760\" height=\"540\" font-family=\"-apple-system, Segoe UI, Helvetica, Arial, sans-serif\">\n"
    ++ "<rect width=\"760\" height=\"540\" fill=\"#fcfcfb\"/>\n"
    ++ text(L(), 24.0, "start", "16", ink(), "<tspan font-weight=\"600\">" ++ title ++ "</tspan>")
    ++ text(L(), 42.0, "start", "12", ink2(), sub)

# Full chart: grid, ticks, `extra` raw SVG (heatmap cells, markers) and the
# series, all clipped to the plot area, then axis labels and the legend.
def chart(+title: String, +sub: String, +xl: String, +yl: String, +f: Frame,
  +ss: List<&2, Series>, +extra: String) -> String:
  header(title, sub)
    ++ "<defs><clipPath id=\"plot\"><rect x=\"84\" y=\"56\" width=\"652\" height=\"350\"/></clipPath></defs>\n"
    ++ String.concat(axis_ticks(Frame.lx(f), f, Frame.x0(f), Frame.x1(f), True{}))
    ++ String.concat(axis_ticks(Frame.ly(f), f, Frame.y0(f), Frame.y1(f), False{}))
    ++ "<g clip-path=\"url(#plot)\">\n" ++ extra ++ String.concat(series_svg(f, ss)) ++ "</g>\n"
    ++ line(L(), (H() - B() : F32), (W() - R() : F32), (H() - B() : F32), "#8d8b85")
    ++ line(L(), T(), L(), (H() - B() : F32), "#8d8b85")
    ++ text(((L() + W() - R()) / 2.0 : F32), (H() - B() + 40.0 : F32), "middle", "13", ink(), xl)
    ++ "<text transform=\"translate(22 " ++ pxs(((T() + H() - B()) / 2.0 : F32)) ++ ") rotate(-90)\" text-anchor=\"middle\" font-size=\"13\" fill=\"" ++ ink() ++ "\">" ++ yl ++ "</text>\n"
    ++ legend_box(ss)
    ++ "</svg>\n"

# Vertical marker line with a label (drawn inside the clip region).
def vmark(+f: Frame, +x: F32, +label: String) -> String:
  +p = px(f, x)
  "<line x1=\"" ++ pxs(p) ++ "\" y1=\"56\" x2=\"" ++ pxs(p) ++ "\" y2=\"406\" stroke=\"#8d8b85\" stroke-width=\"1\"/>\n"
    ++ text((p + 4.0 : F32), 70.0, "start", "11", ink2(), label)

def hmark(+f: Frame, +y: F32, +label: String) -> String:
  +p = py(f, y)
  "<line x1=\"84\" y1=\"" ++ pxs(p) ++ "\" x2=\"736\" y2=\"" ++ pxs(p) ++ "\" stroke=\"#8d8b85\" stroke-width=\"1\"/>\n"
    ++ text(730.0, (p - 5.0 : F32), "end", "11", ink2(), label)
