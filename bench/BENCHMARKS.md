# Benchmarks

```
Operating System: macOS
CPU Information: Intel(R) Core(TM) i7-5557U CPU @ 3.10GHz
Number of Available Cores: 4
Available memory: 16 GB
Elixir 1.6.0
Erlang 20.2.2
```

## FT.Web.TaggedApiKeyPlug v0.3.1/v0.4.0

In v0.3.1 keys (and tags/roles) were parsed from strings for every request, which is dumb; for v0.4.0, a new option to use a module with a `lookup/1` function was introduced, with an implementation using an ETS table with pre-parsed keys, here's how they stacked up (20s test, see `api_key_bench_v0.4.0.exs`):

```
warmup: 2 s
time: 20 s
parallel: 1

Name                     ips        average  deviation         median         99th %
ets_storage         517.40 K        1.93 μs  ±6337.40%           2 μs           3 μs
string_parsing       31.86 K       31.39 μs    ±98.52%          28 μs          60 μs

Comparison:
ets_storage         517.40 K
string_parsing       31.86 K - 16.24x slower
```

So ETS storage gives us a x16 speed-up, knocking key checking down from 28μs to 2μs (median), and 60μs to 3μs (p99).

In v1.0.0 this will be the only option.
