module Ldap
  class Client
    include(Enumerable)

    Error = Class.new(StandardError)

    def initialize(logger: nil, play_cassettes: false, record_cassettes: false)
      @logger = logger || Rails.logger
      @play_cassettes = play_cassettes
      @record_cassettes = record_cassettes
      @ldap_vcr = Ldap::Vcr.new
    end

    ################################################################################
    # PEOPLE
    ################################################################################

    def find_by_uid(uid)
      uid = uid.to_s.strip
      return [] if uid.blank?
      return @ldap_vcr.load_by_uid(uid) if @play_cassettes

      entry = ldap_conn.search(
        base: "ou=people,dc=berkeley,dc=edu",
        filter: Net::LDAP::Filter.eq("uid", uid).to_s
      ).first

      if @record_cassettes
        @ldap_vcr.record_by_uid(uid, entry)
      end

      entry
    rescue Net::LDAP::FilterSyntaxInvalidError => e
      log_error(__callee__, e.message)
      nil
    end

    def find_by_calnetid(calnetid)
      calnetid = calnetid.to_s.strip
      return [] if calnetid.blank?
      return @ldap_vcr.load_by_calnetid(calnetid) if @play_cassettes

      entry = ldap_conn.search(
        base: "ou=people,dc=berkeley,dc=edu",
        filter: Net::LDAP::Filter.eq("berkeleyEduKerberosPrincipalString", calnetid).to_s
      ).first

      if @record_cassettes
        @ldap_vcr.record_by_calnetid(calnetid, entry)
      end

      entry
    rescue Net::LDAP::FilterSyntaxInvalidError => e
      log_error(__method__, e.message)
      nil
    end

    def each_person(limit: nil)
      args = {
        base: "ou=people,dc=berkeley,dc=edu",
        sort_control: ["sn"],
        filter: Net::LDAP::Filter.eq("uid", "*"),
        paged_searches_supported: true
      }

      count = 0
      ldap_conn.search(args) do |entry|
        yield(entry)

        count += 1
        if count % 5_000 == 0
          log_debug("loaded #{count} person entries")
        end

        if limit && (count >= limit)
          break
        end
      end

      log_debug("loaded #{count} person entries")
    rescue Net::LDAP::FilterSyntaxInvalidError => e
      log_error(__method__, e.message)
      []
    end

    ################################################################################
    # ORGS
    ################################################################################

    def find_org_by_code(code)
      code = code.to_s.strip
      return [] if code.blank?
      return @ldap_vcr.load_by_code(code) if @play_cassettes

      entry = ldap_conn.search(
        base: "ou=org units,dc=berkeley,dc=edu",
        filter: Net::LDAP::Filter.eq("ou", code).to_s
      ).first

      if @record_cassettes
        @ldap_vcr.record_by_code(code, entry)
      end

      entry
    rescue Net::LDAP::FilterSyntaxInvalidError => e
      log_error(__method__, e.message)
      nil
    end

    def each_org(limit: nil)
      args = {
        base: "ou=org units,dc=berkeley,dc=edu",
        # sort_control: ["sn"],
        filter: Net::LDAP::Filter.eq("ou", "*"),
        paged_searches_supported: true
      }

      count = 0
      ldap_conn.search(args) do |entry|
        yield(entry)

        count += 1
        if count % 5_000 == 0
          log_debug("loaded #{count} org entries")
        end

        if limit && (count >= limit)
          break
        end
      end

      log_debug("loaded #{count} total org entries")
    rescue Net::LDAP::FilterSyntaxInvalidError => e
      log_error(__method__, e.message)
      []
    end
    def self.find_by_uid(uid)
      new.find_by_uid(uid)
    end

    def self.find_by_calnetid(calnetid)
      new.find_by_calnetid(calnetid)
    end

    def self.each_person(limit: nil)
      new.each(limit: limit)
    end

    private

    def config
      Ldap.config
    end

    def ldap_conn
      @ldap_conn ||= Ldap::Conn.fetch
    rescue Ldap::Conn::BindError => e
      raise(Error, e.message)
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
