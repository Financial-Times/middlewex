# Plug Middleware for FT Elixir Apps

* API Key header validation and role assignment with `TaggedApiKeyPlug`.
* Role-based authorisation with `NeedsRolePlug`.
* `__gtg` and `__about` with `GtgPlug` and `AboutPlug`.
* `NiceLoggerPlug` which logs useful request details in a Splunk-friendly manner.
* `FastlyClientIPPlug` which decodes the `Fastly-Client-IP` header.

> NB all plug modules above are prefixed with `FT.Web.`.

## See also
* For `__health` endpoint, see [Fettle](https://github.com/Financial-Times/fettle).
* For Kubernetes `__traffic` endpoint, see [`K8STrafficPlug`](https://github.com/Financial-Times/k8s_traffic_plug).

## Installation

Add `middlewex` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:middlewex, github: "Financial-Times/middlewex", tag: "v0.4.0"}
  ]
end
```

To generate docs in HTML, do:

```
mix docs
```
