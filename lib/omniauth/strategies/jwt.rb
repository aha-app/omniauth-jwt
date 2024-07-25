require 'omniauth'
require 'jwt'

module OmniAuth
  module Strategies
    class JWT
      class ClaimInvalid < StandardError; end
      class BadJwt < StandardError; end

      include OmniAuth::Strategy

      args [:secret]

      option :secret, nil
      option :decode_options, {}
      option :uid_claim, 'email'
      option :required_claims, %w(name email)
      option :info_map, {"name" => "name", "email" => "email"}
      option :auth_url, nil
      option :valid_within, nil

      def request_phase
        redirect options.auth_url
      end

      def decoded
        begin
          @decoded ||= ::JWT.decode(request.params['jwt'], options.secret, true, options.decode_options).first
        rescue Exception => e
          raise BadJwt.new(e.message)
        end
        (options.required_claims || []).each do |field|
          raise ClaimInvalid.new("Missing required '#{field}' claim.") if !@decoded.key?(field.to_s)
        end
        raise ClaimInvalid.new("Missing required 'iat' claim.") if options.valid_within && !@decoded["iat"]
        raise ClaimInvalid.new("'iat' timestamp claim is too skewed from present.") if options.valid_within && (Time.now.to_i - @decoded["iat"]).abs > options.valid_within
        @decoded
      end

      def callback_phase
        raise ClaimInvalid.new("UID claim empty or missing") if uid.to_s.empty?

        super
      rescue BadJwt => e
        fail! 'bad_jwt', e
      rescue ClaimInvalid => e
        fail! :claim_invalid, e
      end

      uid do
        Array(options.uid_claim).map { |field| decoded[field.to_s].to_s.strip }.reject(&:empty?).first
      end

      extra do
        {:raw_info => decoded}
      end

      info do
        options.info_map.inject({}) do |h,(k,v)|
          h[k.to_s] = decoded[v.to_s]
          h
        end
      end
    end

    class Jwt < JWT; end
  end
end
