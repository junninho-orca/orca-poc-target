# Inbound notification delivery endpoint.
#
# The Ruby side of the demo service: it accepts notification payloads posted by upstream
# systems and decides whether to accept them, which means inspecting a caller-supplied
# `Content-Type` header. That header is untrusted input from the network, and it is parsed with
# Rack's own media-type parser rather than a hand-rolled regex — so the safety of this endpoint
# depends on that parser behaving on hostile input.
require "rack"

module RBNotify
  ACCEPTED_TYPES = ["application/json", "application/notification+json"].freeze
  DEFAULT_CHARSET = "utf-8"

  # Raised for a payload this endpoint will not accept.
  class UnsupportedType < StandardError; end

  module Delivery
    # The media type of a request, ignoring parameters. A missing or empty header is answered
    # here rather than handed to Rack: an absent Content-Type is a normal thing for a caller
    # to send, not an exceptional one, and the parser's behaviour on it has varied between
    # Rack releases.
    def self.media_type(content_type)
      return nil if content_type.nil? || content_type.strip.empty?

      Rack::MediaType.type(content_type)
    end

    # The charset a caller asked for, defaulting rather than guessing.
    def self.charset(content_type)
      return DEFAULT_CHARSET if content_type.nil? || content_type.strip.empty?

      Rack::MediaType.params(content_type)["charset"] || DEFAULT_CHARSET
    end

    def self.acceptable?(content_type)
      ACCEPTED_TYPES.include?(media_type(content_type))
    end

    # Returns a Rack response triple for a posted notification.
    def self.call(content_type, body)
      raise UnsupportedType, "unsupported content type: #{content_type.inspect}" unless
        acceptable?(content_type)

      [202, { "content-type" => "application/json" },
       ["{\"accepted\":true,\"bytes\":#{body.to_s.bytesize}}"]]
    end
  end
end
