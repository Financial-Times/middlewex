# v0.4.0

* Now sets `%FT.Web.Authentication{}` struct as `private.authentication` value, rather than plain map.
    * possibly a breaking change, depending on if you used the previous `key` field, which is now in the struct's `priv.key`, or if you relied on the value being a plain map, e.g. relied on `Access` protocol.
    * Support methods for setting and getting authentication in `FT.Web.Authentication` module.
* Added `FT.Web.KeyStorage` behaviour for more flexible api-key lookup, and an implementation `FT.Web.ETSKeyStorage` that uses ETS to store keys for major speed-up.
* `FT.Web.TaggedApiKeyPlug` changes:
    * Support `FT.Web.KeyStorage` in `keys` option.
    * Add `forbid` boolean option to `FT.Web.TaggedApiKeyPlug` to allow unauthenticated requests to pass, rather than immediately generating the `403 Denied` status:
        * This allows multiple authentication methods to be tried, before enforcing with the `FT.Web.NeedsAuthentication` plug.
* Add `FT.Web.NeedsAuthenticationPlug` which enforces authentication, optionally with a given authentication method.
