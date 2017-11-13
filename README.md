# Plug Middleware for FT Elixir Apps

* API Key header validation and role assignment with `FT.Web.TaggedApiKeyPlug`.
* Role-based authorisation with `FT.Web.NeedsRolePlug`.
* `__gtg` and `__about` with `FT.Web.GtgPlug` and `FT.Web.AboutPlug`.

## See also
* For `__health` endpoint, see [Fettle](https://github.com/Financial-Times/fettle).
* For Kubernetes `__traffic` endpoint, see [`K8STrafficPlug`](https://github.com/Financial-Times/k8s_traffic_plug).

## Installation

Add `middlewex` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:middlewex, github: "Financial-Times/middlewex"}
  ]
end
```
