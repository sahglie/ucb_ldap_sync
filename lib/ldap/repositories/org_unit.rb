module Ldap::Repositories
  class OrgUnit
    include(::Utils::LoggingHelper)

    Error = Class.new(StandardError)
    TimeoutError = Class.new(Error)

    def initialize(logger: Rails.logger, ldap_client: nil)
      @logger = logger
      @ldap_client = ldap_client || default_ldap_client
    end

    def find_by_code(code)
      org_entry = @ldap_client.find_org_by_code(code)
      return if org_entry.nil?

      attrs = attrs_for_entry(org_entry)
      if attrs[:code] == "UCBKL"
        attrs[:hierarchy] = "UCBKL"
      end

      org_unit = Ldap::Entities::OrgUnit.new(attrs)
      org_unit.ldap_entry = org_entry

      org_unit
    rescue Ldap::Client::Error => e
      log_error(e.message, method: __method__)
      raise(Error)
    end

    def find_all(limit: nil)
      orgs = []

      @ldap_client.each_org(limit: limit) do |entry|
        attrs = attrs_for_entry(entry)

        # one of the records is a header record, so skip it
        next if attrs[:code].match?(/org units/i)

        if attrs[:code].match?(/UCBKL/i)
          attrs[:hierarchy] = "UCBKL"
        end

        org =::Ldap::Entities::OrgUnit.new(attrs)
        org.ldap_entry = entry
        orgs << org
      end

      orgs
    end

    def self.find_all(limit: nil)
      new.find_all(limit: limit)
    end

    private

    def attrs_for_entry(entry)
      hierarchy = entry[:berkeleyEduOrgUnitHierarchyString][0].to_s.tr("-", ".")

      { code: entry.ou[0]&.to_s.upcase,
        name: entry.description[0]&.to_s,
        hierarchy: hierarchy.upcase,
        level: hierarchy.count(".") + 1,
        dn: entry.dn[0].to_s
      }
    end

    def default_ldap_client
      Ldap::Client.new(logger: @logger)
    end
  end
end