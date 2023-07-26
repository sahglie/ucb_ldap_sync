module Ldap
  class Vcr
    def initialize(cassette_dir: Rails.root.join("test", "ldap_cassettes"))
      @cassette_dir = cassette_dir
    end

    def load_by_uid(uid)
      ldif_path = File.join(@cassette_dir, "people", "#{uid}.ldif")
      ldif = File.read(ldif_path)
      Net::LDAP::Entry._load(ldif)
    end

    def load_by_calnetid(calnetid)
      ldif_path = File.join(@cassette_dir, "people", "#{calnetid}.ldif")
      ldif = File.read(ldif_path)
      Net::LDAP::Entry._load(ldif)
    end

    def load_by_code(code)
      ldif_path = File.join(@cassette_dir, "org_units", "#{code}.ldif")
      ldif = File.read(ldif_path)
      Net::LDAP::Entry._load(ldif)
    end

    def record_by_uid(uid, ldap_entry)
      ldif_path = File.join(@cassette_dir, "people", "#{uid}.ldif")
      File.write(ldif_path, ldap_entry.to_ldif)
    end

    def record_by_calnetid(calnetid, ldap_entry)
      ldif_path = File.join(@cassette_dir, "people", "#{calnetid}.ldif")
      File.write(ldif_path, ldap_entry.to_ldif)
    end

    def record_by_code(code, ldap_entry)
      ldif_path = File.join(@cassette_dir, "org_units", "#{code}.ldif")
      File.write(ldif_path, ldap_entry.to_ldif)
    end
  end
end
