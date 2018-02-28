# Plug Middleware for FT Elixir Apps

* `__gtg` and `__about` with `GtgPlug` and `AboutPlug`.
* `FastlyClientIPPlug` which decodes the `Fastly-Client-IP` header into `Plug.Conn.remote_ip`.
* `NiceLoggerPlug` which logs useful request details in a Splunk-friendly manner.
* Authentication and Authorization support:
    * Extensible authentication via `Authentication` struct and `NeedsAuthenticationPlug`.
    * API Key header authentication with role assignment via `TaggedApiKeyPlug`.
    * Role-based authorisation via `NeedsRolePlug`.

> NB all plug modules above are prefixed with `FT.Web.`.

## See also
* For `__health` endpoint, see [Fettle](https://github.com/Financial-Times/fettle).
* For Kubernetes `__traffic` endpoint, see [`K8STrafficPlug`](https://github.com/Financial-Times/k8s_traffic_plug).

## Installation

FT Middlewex releases are available via tagged Github releases (not currently via Hex).

Add `middlewex` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:middlewex, github: "Financial-Times/middlewex", tag: "v0.4.0"}
  ]
end
```
> We use [SemVer](http://semver.org/) for releases, but since this library is still `0.x`, while we endevour not to introduce breaking changes for *minor* release versions (`0.x.0`), we do not guarantee that this will never happen. However we're more strict about *patch* versions not having breaking changes.

## Docs

To generate docs in HTML, do:

```
mix docs
```
