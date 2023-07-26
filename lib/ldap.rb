module Ldap
  def self.config
    {host: ENV.fetch("LDAP_HOST"),
     port: ENV.fetch("LDAP_PORT"),
     username: ENV.fetch("LDAP_USERNAME"),
     password: ENV.fetch("LDAP_PASSWORD")}
  end
end