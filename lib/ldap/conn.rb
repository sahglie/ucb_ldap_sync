module Ldap
  class Conn

    class BindError < StandardError
      def initialize(username, host)
        super("Failed to bind username '#{username}' to '#{host}'")
      end
    end

    def net_ldap
      @net_ldap = Net::LDAP.new(params)
      @net_ldap.bind || raise(BindError.new(username, host))
      @net_ldap
    rescue Net::LDAP::Error
      raise(BindError.new(username, host))
    end

    def self.fetch
      self.new.net_ldap
    end

    private

    def username
      config(:username)
    end

    def host
      config(:host)
    end

    def config(sym)
      Ldap.config.fetch(sym)
    end

    def params
      {
          host: config(:host),
          auth: {
              method: :simple,
              username: config(:username),
              password: config(:password)
          },
          port: config(:port),
          encryption: {
              method: :simple_tls,
              tls_options: OpenSSL::SSL::SSLContext::DEFAULT_PARAMS
          }
      }
    end
  end
end
