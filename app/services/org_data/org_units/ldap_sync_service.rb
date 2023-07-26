module OrgData::OrgUnits
  class LdapSyncService
    include(Utils::LoggingHelper)

    def initialize(logger: nil, limit: nil)
      @logger = logger || Rails.logger
      @limit = limit
    end

    def sync(db_orgs: nil, ldap_orgs: nil)
      log_debug("preparing to sync db org_units table with ldap org_units ou", method: __method__)

      db_orgs ||= default_db_orgs
      ldap_orgs ||= default_ldap_orgs

      log_debug("db org_units has #{db_orgs.length} records", method: __method__)
      log_debug("ldap org_units has #{ldap_orgs.length} records", method: __method__)

      db_org_map = db_orgs.each_with_object({}) { |org, hash| hash[org.code] = org }
      ldap_org_map = ldap_orgs.each_with_object({}) { |org, hash| hash[org.code] = org }

      new_orgs = new_orgs_change_set(db_org_map, ldap_org_map)
      modified_orgs = modified_orgs_change_set(db_org_map, ldap_org_map)
      expired_orgs = expired_orgs_change_set(db_org_map, ldap_org_map)

      log_debug("found #{new_orgs.length} new orgs in ldap", method: __method__)
      save_new_orgs(new_orgs)
      log_debug("created #{new_orgs.length} new orgs", method: __method__)

      log_debug("found #{modified_orgs.length} modified orgs in ldap", method: __method__)
      update_modified_orgs(modified_orgs)
      log_debug("updated #{modified_orgs.length} existing orgs", method: __method__)

      log_debug("found #{expired_orgs.length} expired orgs in db", method: __method__)
      expire_expired_orgs(expired_orgs)
      log_debug("expired #{expired_orgs.length} existing orgs", method: __method__)

      log_debug("finished syncing ucb_orgs table with ldap orgs ou", method: __method__)
    end

    def self.sync = new.sync

    private

    def default_ldap_orgs
      repo = Ldap::Repositories::OrgUnit.new(logger: @logger)
      repo.find_all(limit: @limit)
    end

    def default_db_orgs
      ::OrgData::OrgUnit.all
    end

    def new_orgs_change_set(db_org_map, ldap_org_map)
      new_org_codes = Set.new(ldap_org_map.keys - db_org_map.keys)
      ldap_org_map.values.keep_if { |e| new_org_codes.include?(e.code) }
    end

    def modified_orgs_change_set(db_org_map, ldap_org_map)
      org_codes = Set.new(ldap_org_map.keys & db_org_map.keys)
      db_orgs = db_org_map.values.keep_if { |r| org_codes.include?(r.code) }

      db_orgs.keep_if do |db_org|
        ldap_org = ldap_org_map[db_org.code]
        changed_attributes = db_org_attrs(ldap_org)
        db_org.attributes = changed_attributes

        log_debug(db_org.changes, method: __method__)
        db_org.changed?
      end
    end

    def expired_orgs_change_set(db_org_map, ldap_org_map)
      expired_orgs = Set.new(db_org_map.keys - ldap_org_map.keys)
      db_org_map.values.keep_if { |e| expired_orgs.include?(e.code) }
    end

    def db_org_attrs(ldap_org)
      {
        code: ldap_org.code,
        name: ldap_org.name,
        hierarchy: ldap_org.hierarchy,
        level: ldap_org.level,
        expired_ts: nil
      }
    end

    def save_new_orgs(ldap_orgs)
      ldap_orgs.each_slice(5_000).each do |slice|
        ApplicationRecord.transaction do
          slice.each do |ldap_org|
            attrs = db_org_attrs(ldap_org)
            db_org = OrgData::OrgUnit.new(attrs)
            db_org.save!
          end
        end
      end
    end

    def update_modified_orgs(db_orgs)
      db_orgs.each_slice(500).each do |slice|
        ApplicationRecord.transaction do
          slice.each do |db_org|
            db_org.save!
          end
        end
      end
    end

    def expire_expired_orgs(db_orgs)
      ApplicationRecord.transaction do
        db_orgs.each do |db_org|
          db_org.expire
        end
      end
    end
  end
end
