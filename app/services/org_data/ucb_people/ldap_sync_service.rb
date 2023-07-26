module OrgData::UcbPeople
  class LdapSyncService
    include(Utils::LoggingHelper)

    def initialize(logger: nil, limit: nil)
      @logger = logger || Rails.logger
      @limit = limit
    end

    def sync(db_records: nil, ldap_records: nil)
      log_debug("preparing to sync ucb_people table with ldap people ou", method: __method__)

      db_records ||= default_db_records
      ldap_records ||= default_ldap_records

      log_debug("ucb_people db table has #{db_records.length} records", method: __method__)
      log_debug("ldap people ou has #{ldap_records.length} records", method: __method__)

      db_uid_map = create_db_uid_map(db_records)
      ldap_uid_map = create_ldap_uid_map(ldap_records)

      new_records = new_records_change_set(db_uid_map, ldap_uid_map)
      modified_records = modified_records_change_set(db_uid_map, ldap_uid_map)
      expired_records = expired_records_change_set(db_uid_map, ldap_uid_map)

      log_debug("found #{new_records.length} new records in ldap", method: __method__)
      save_new_records(new_records)
      log_debug("created #{new_records.length} new records", method: __method__)

      log_debug("found #{modified_records.length} modified records in ldap", method: __method__)
      update_modified_records(modified_records)
      log_debug("updated #{modified_records.length} existing records", method: __method__)

      log_debug("found #{expired_records.length} expired records in db", method: __method__)
      expire_expired_records(expired_records)
      log_debug("expired #{expired_records.length} existing records", method: __method__)

      log_debug("finished syncing ucb_people table with ldap people ou", method: __method__)
    end

    def self.sync = new.sync
    
    private

    def default_ldap_records
      repo = Ldap::Repositories::Person.new(logger: @logger)
      repo.find_all(limit: @limit)
    end

    def default_db_records
      ::OrgData::UcbPerson.all
    end

    def create_db_uid_map(db_records)
      db_records.each_with_object({}) do |record, hash|
        hash[record.calnet_uid] = record
      end
    end

    def create_ldap_uid_map(ldap_records)
      ldap_records.each_with_object({}) do |record, hash|
        hash[record.uid] = record
      end
    end

    def new_records_change_set(db_uid_map, ldap_uid_map)
      new_uids = Set.new(ldap_uid_map.keys - db_uid_map.keys)
      ldap_uid_map.values.keep_if { |e| new_uids.include?(e.uid) }
    end

    def modified_records_change_set(db_uid_map, ldap_uid_map)
      uids = Set.new(ldap_uid_map.keys & db_uid_map.keys)
      db_records = db_uid_map.values.keep_if { |r| uids.include?(r.calnet_uid) }

      db_records.keep_if do |db_record|
        ldap_record = ldap_uid_map[db_record.calnet_uid]
        changed_attributes = db_record_attrs(ldap_record)

        db_record.attributes = if db_record.affiliations.sort == changed_attributes[:affiliations].sort
          changed_attributes.except(:affiliations_summary)
        else
          changed_attributes
        end

        # log_debug(db_record.inspect)
        log_debug(db_record.changes)
        db_record.changed?
      end
    end

    def expired_records_change_set(db_uid_map, ldap_uid_map)
      expired_uids = Set.new(db_uid_map.keys - ldap_uid_map.keys)
      db_uid_map.values.keep_if { |e| expired_uids.include?(e.calnet_uid) }
    end

    def db_record_attrs(ldap_record)
      summary = Ldap::Utils::AffiliationsSummarizer.summary(ldap_record.affiliations)
      
      {
        calnet_uid: ldap_record.uid,
        kerberos_principal: ldap_record.kerberos_principal,
        first_name: ldap_record.given_name,
        last_name: ldap_record.sn,
        display_name: ldap_record.display_name,
        email: ldap_record.email,
        official_email: ldap_record.official_email,
        org: ldap_record.primary_dept_unit,
        ou: ldap_record.ou,
        affiliations: ldap_record.affiliations.sort,
        dn: ldap_record.dn,
        affiliations_summary: summary,
        expired_ts: nil
      }
    end

    def save_new_records(new_records)
      new_records.each_slice(5_000).each do |slice|
        ApplicationRecord.transaction do
          slice.each do |ldap_record|
            attrs = db_record_attrs(ldap_record)
            db_record = OrgData::UcbPerson.new(attrs)
            db_record.save!
          end
        end
      end
    end

    def update_modified_records(modified_records)
      modified_records.each_slice(500).each do |slice|
        ApplicationRecord.transaction do
          slice.each do |db_record|
            db_record.save!
          end
        end
      end
    end

    def expire_expired_records(expired_records)
      ApplicationRecord.transaction do
        expired_records.each do |record|
          record.expire
        end
      end
    end
  end
end
