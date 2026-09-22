# Parallel Monte Carlo benchmark: 2^depth sampled trips (Jan, base network).
# Build: bend simulations/bench.bend -o build/bench ; run: build/bench --threads T
import Base
import ../src/graph.bend as G
import ../src/sp.bend as SP
import ../src/risk.bend as K
import ../src/network.bend as N

def job(+m: U32) -> K.Job:
  +a = N.arcs(m, N.base())
  +r = G.pick_arcs(a, SP.Route.arcs(SP.route(N.n_nodes(), K.expected_arcs(a), K.cost_only(), N.SOR(), N.CHN())))
  K.Job{K.Plan{N.n_nodes(), a, N.CHN()}, r, r}

def run(+depth: Nat, +m: U32) -> String:
  +os = K.tree(depth, job(m), 1)
  "trips " ++ Nat.show(List.length(&2, K.Out, os)) ++ "  mean fixed " ++ F32.show(K.mean(K.firsts(os)))
    ++ "  mean adaptive " ++ F32.show(K.mean(K.seconds(os)))

def main() -> IO(Unit):
  do IO<Unit>:
    IO.print(run(18n, 0))
