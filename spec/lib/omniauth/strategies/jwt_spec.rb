require 'spec_helper'

describe OmniAuth::Strategies::JWT do
  let(:response_json){ JSON.parse(last_response.body) }
  let(:args){ ['imasecret', {auth_url: 'http://example.com/login'}] }

  let(:app){
    the_args = args
    Rack::Builder.new do |b|
      b.use Rack::Session::Cookie, secret: 'sekrit' * 11
      b.use OmniAuth::Strategies::JWT, *the_args
      b.run lambda{|env| [200, {}, [(env['omniauth.auth'] || {}).to_json]]}
    end
  }

  context 'request phase' do
    it 'should redirect to the configured login url' do
      get '/auth/jwt'
      expect(last_response.status).to eq(302)
      expect(last_response.headers['Location']).to eq('http://example.com/login')
    end
  end

  context 'callback phase' do
    it 'should decode the response' do
      encoded = JWT.encode({name: 'Bob', email: 'steve@example.com'}, 'imasecret')
      get '/auth/jwt/callback?jwt=' + encoded
      expect(response_json["info"]["email"]).to eq("steve@example.com")
    end

    it 'should not work without required fields' do
      encoded = JWT.encode({name: 'Steve'}, 'imasecret')
      get '/auth/jwt/callback?jwt=' + encoded
      expect(last_response.status).to eq(302)
    end

    it 'should assign the uid' do
      encoded = JWT.encode({name: 'Steve', email: 'dude@awesome.com'}, 'imasecret')
      get '/auth/jwt/callback?jwt=' + encoded
      expect(response_json["uid"]).to eq('dude@awesome.com')
    end

    context 'with multiple uid_claim options' do
      let(:args){ ['imasecret', {auth_url: 'http://example.com/login', uid_claim: ['sub', 'email']}] }

      it "should assign the first uid_claim that's present" do
        encoded = JWT.encode({name: 'Bob', sub: 'with-sub', email: 'steve@example.com'}, 'imasecret')
        get '/auth/jwt/callback?jwt=' + encoded
        expect(JSON.parse(last_response.body)["uid"]).to eq("with-sub")

        encoded = JWT.encode({name: 'Bob', email: 'steve@example.com'}, 'imasecret')
        get '/auth/jwt/callback?jwt=' + encoded
        expect(JSON.parse(last_response.body)["uid"]).to eq("steve@example.com")
      end

      it "fails if no valid claim is present" do
        encoded = JWT.encode({name: 'Bob', last_name: 'steve@example.com'}, 'imasecret')
        get '/auth/jwt/callback?jwt=' + encoded
        expect(last_response.status).to eq(302)
        expect(last_response.headers['Location']).to match('auth/failure')
      end
    end

    context 'with a non-default encoding algorithm' do
      let(:args){ ['imasecret', {auth_url: 'http://example.com/login', decode_options: { algorithms: ['HS512', 'HS256'] }}] }

      it 'should decode the response with an allowed algorithm' do
        encoded = JWT.encode({name: 'Bob', email: 'steve@example.com'}, 'imasecret', 'HS512')
        get '/auth/jwt/callback?jwt=' + encoded
        expect(JSON.parse(last_response.body)["info"]["email"]).to eq("steve@example.com")

        encoded = JWT.encode({name: 'Bob', email: 'steve@example.com'}, 'imasecret', 'HS256')
        get '/auth/jwt/callback?jwt=' + encoded
        expect(JSON.parse(last_response.body)["info"]["email"]).to eq("steve@example.com")
      end

      it 'should fail decoding the response with a different algorithm' do
        encoded = JWT.encode({name: 'Bob', email: 'steve@example.com'}, 'imasecret', 'HS384')
        get '/auth/jwt/callback?jwt=' + encoded
        expect(last_response.headers["Location"]).to include("/auth/failure")
      end
    end

    context 'with a :valid_within option set' do
      let(:args){ ['imasecret', {auth_url: 'http://example.com/login', valid_within: 300}] }

      it 'should work if the iat key is within the time window' do
        encoded = JWT.encode({name: 'Ted', email: 'ted@example.com', iat: Time.now.to_i}, 'imasecret')
        get '/auth/jwt/callback?jwt=' + encoded
        expect(last_response.status).to eq(200)
      end

      it 'should not work if the iat key is outside the time window' do
        encoded = JWT.encode({name: 'Ted', email: 'ted@example.com', iat: Time.now.to_i + 500}, 'imasecret')
        get '/auth/jwt/callback?jwt=' + encoded
        expect(last_response.status).to eq(302)
      end

      it 'should not work if the iat key is missing' do
        encoded = JWT.encode({name: 'Ted', email: 'ted@example.com'}, 'imasecret')
        get '/auth/jwt/callback?jwt=' + encoded
        expect(last_response.status).to eq(302)
      end
    end
  end
end
