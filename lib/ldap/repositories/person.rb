module Ldap
  module Repositories
    class Person
      Error = Class.new(StandardError)
      TimeoutError = Class.new(Error)

      def initialize(logger: Rails.logger, ldap_client: nil)
        @logger = logger
        @ldap_client = ldap_client || default_ldap_client
      end

      def find_by_calnetid(calnetid)
        person_entry = @ldap_client.find_by_calnetid(calnetid)
        return if person_entry.nil?

        attrs = attrs_for_entry(person_entry)
        person = Ldap::Entities::Person.new(attrs)
        person.ldap_entry = person_entry

        person
      rescue Ldap::Client::Error => e
        log_error(__method__, e.message)
        raise(Error)
      end

      def find_by_uid(uid)
        person_entry = @ldap_client.find_by_uid(uid)
        return if person_entry.nil?

        attrs = attrs_for_entry(person_entry)
        person = Ldap::Entities::Person.new(attrs)
        person.ldap_entry = person_entry

        person
      rescue Ldap::Client::Error => e
        log_error(__method__, e.message)
        raise(Error)
      end

      def find_all(limit: nil)
        people = []
        @ldap_client.each_person(limit: limit) do |entry|
          attrs = attrs_for_entry(entry)
          people << ::Ldap::Entities::Person.new(attrs)
        end

        people
      end

      def self.find_by_uid(uid)
        new.find_by_uid(uid)
      end

      def self.find_by_calnetid(calnetid)
        new.find_by_calnetid(calnetid)
      end

      def self.find_all(limit: nil)
        new.find_all(limit: limit)
      end

      private

      def attrs_for_entry(entry)
        {uid: entry[:uid][0]&.to_i,
         kerberos_principal: entry[:berkeleyEduKerberosPrincipalString][0]&.to_s,
         given_name: entry[:givenName][0]&.to_s,
         sn: entry[:sn][0]&.to_s,
         display_name: entry[:displayName][0]&.to_s,
         email: entry[:mail][0]&.to_s,
         official_email: entry[:berkeleyEduOfficialEmail][0]&.to_s,
         primary_dept_unit: entry[:berkeleyEduPrimaryDeptUnit][0]&.to_s,
         affiliations: entry[:berkeleyEduAffiliations].map(&:to_s),
         ou: entry[:ou][0]&.to_s,
         dn: entry[:dn][0]&.to_s}
      end

      def default_ldap_client
        Ldap::Client.new(logger: @logger)
      end

      def service_name
        self.class.name
      end

      def log_error(method, message)
        @logger.error("#{service_name}: #{method} failed: #{message}")
      end

      def log_debug(message)
        @logger.debug("#{service_name}: #{message}")
      end
    end
  end
end
