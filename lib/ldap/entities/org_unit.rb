module Ldap::Entities
  class OrgUnit
    include ActiveAttr::Model

    attr_accessor(:ldap_entry)

    attribute(:code)
    attribute(:hierarchy)
    attribute(:level)
    attribute(:name)
    attribute(:dn)

    def to_s
      {code: code, name: name, hierarchy: hierarchy, level: level}.to_s
    end
  end
end
