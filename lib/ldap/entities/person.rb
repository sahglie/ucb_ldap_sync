module Ldap
  module Entities
    class Person
      include ActiveAttr::Model

      attr_accessor(:ldap_entry)

      attribute(:uid)
      attribute(:kerberos_principal)
      # attribute(:employee_number)
      # attribute(:employee_id)
      attribute(:given_name)
      attribute(:sn)
      attribute(:display_name)
      attribute(:email)
      attribute(:official_email)
      attribute(:primary_dept_unit)
      attribute(:ou)
      attribute(:affiliations, default: -> { [] })
      attribute(:dn)
      # attribute(:testid)

      def to_s
        {uid: uid, kerberos_principal: kerberos_principal, sn: sn, given_name: given_name, dn: dn}.to_s
      end

    end
  end
end
