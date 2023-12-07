# OmniAuth::JWT

<div id="badges">

[![Current][🚎ciwfi]][🚎ciwf] [![Coverage][🖐cowfi]][🖐cowf] [![Style][🧮swfi]][🧮swf]

[![Legacy][🧮lwfi]][🧮lwf] [![Ancient][🧮awfi]][🧮awf]

---

[![Liberapay Patrons][⛳liberapay-img]][⛳liberapay]
<span class="badge-buymeacoffee">
[![Sponsor Me][🖇sponsor-img]][🖇sponsor]
<a href="https://ko-fi.com/O5O86SNP4" target='_blank' title="Donate to my FLOSS or refugee efforts at ko-fi.com"><img src="https://img.shields.io/badge/buy%20me%20coffee-donate-yellow.svg" alt="Buy Me Coffee donation button" /></a>
</span>
<span class="badge-patreon">
<a href="https://patreon.com/galtzo" title="Donate to my FLOSS or refugee efforts using Patreon"><img src="https://img.shields.io/badge/patreon-donate-yellow.svg" alt="Patreon donate button" /></a>
</span>

</div>

[🚎ciwf]: https://github.com/pboling/omniauth-jwt2/actions/workflows/ci.yml
[🚎ciwfi]: https://github.com/pboling/omniauth-jwt2/actions/workflows/ci.yml/badge.svg
[🖐cowf]: https://github.com/pboling/omniauth-jwt2/actions/workflows/coverage.yml
[🖐cowfi]: https://github.com/pboling/omniauth-jwt2/actions/workflows/coverage.yml/badge.svg
[🧮swf]: https://github.com/pboling/omniauth-jwt2/actions/workflows/style.yml
[🧮swfi]: https://github.com/pboling/omniauth-jwt2/actions/workflows/style.yml/badge.svg
[🧮lwf]: https://github.com/pboling/omniauth-jwt2/actions/workflows/legacy.yml
[🧮lwfi]: https://github.com/pboling/omniauth-jwt2/actions/workflows/legacy.yml/badge.svg
[🧮awf]: https://github.com/pboling/omniauth-jwt2/actions/workflows/ancient.yml
[🧮awfi]: https://github.com/pboling/omniauth-jwt2/actions/workflows/ancient.yml/badge.svg

[⛳liberapay-img]: https://img.shields.io/liberapay/patrons/pboling.svg?logo=liberapay
[⛳liberapay]: https://liberapay.com/pboling/donate
[🖇sponsor-img]: https://img.shields.io/badge/Sponsor_Me!-pboling.svg?style=social&logo=github
[🖇sponsor]: https://github.com/sponsors/pboling

[JSON Web Token](http://self-issued.info/docs/draft-ietf-oauth-json-web-token.html) (JWT) is a simple
way to send verified information between two parties online. This can be useful as a mechanism for
providing Single Sign-On (SSO) to an application by allowing an authentication server to send a validated
claim and log the user in. This is how [Zendesk does SSO](https://support.zendesk.com/hc/en-us/articles/4408845838874-Enabling-JWT-JSON-Web-Token-single-sign-on),
for example.

OmniAuth::JWT provides a clean, simple wrapper on top of JWT so that you can easily implement this kind
of SSO either between your own applications or allow third parties to delegate authentication.

## History

This library is a fork of the [original](https://github.com/mbleigh/omniauth-jwt)
by Michael Bleigh which stopped development in 2013.
It incorporates *all* of the fixes and features from the main forks by Aha, Discourse,
and GitLab (which has been vendored inside GitLab, and isn't even in the fork network).

## Installation

Add this line to your application's Gemfile:

    gem 'omniauth-jwt2'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install omniauth-jwt2

## Usage

You use OmniAuth::JWT just like you do any other OmniAuth strategy:

```ruby
use OmniAuth::JWT, "SHAREDSECRET", auth_url: "http://example.com/login"
```

The first parameter is the shared secret that will be used by the external authenticator to verify
that. You must also specify the `auth_url` option to tell the strategy where to redirect to log
in. Other available options are:

* **algorithm:** the algorithm to use to decode the JWT token. This is `HS256` by default but can
  be set to anything supported by [ruby-jwt](https://github.com/progrium/ruby-jwt)
* **uid_claim:** this determines which claim will be used to uniquely identify the user. Defaults
  to `email`
* **required_claims:** array of claims that are required to make this a valid authentication call.
  Defaults to `['name', 'email']`
* **info_map:** array mapping claim values to info hash values. Defaults to mapping `name` and `email`
  to the same in the info hash.
* **valid_within:** integer of how many seconds of time skew you will allow. Defaults to `nil`. If this
  is set, the `iat` claim becomes required and must be within the specified number of seconds of the
  current time. This helps to prevent replay attacks.

### Authentication Process

When you authenticate through `omniauth-jwt` you can send users to `/auth/jwt` and it will redirect
them to the URL specified in the `auth_url` option. From there, the provider must generate a JWT
and send it to the `/auth/jwt/callback` URL as a "jwt" parameter:

    /auth/jwt/callback?jwt=ENCODEDJWTGOESHERE

An example of how to do that in Sinatra:

```ruby
require "jwt"

get "/login/sso/other-app" do
  # assuming the user is already logged in and this is available as current_user
  claims = {
    id: current_user.id,
    name: current_user.name,
    email: current_user.email,
    iat: Time.now.to_i,
  }

  payload = JWT.encode(claims, ENV["SSO_SECRET"])
  redirect "http://other-app.com/auth/jwt/callback?jwt=#{payload}"
end
```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
