class OrgData::UcbPerson < ApplicationRecord
  self.table_name = "org_data.ucb_people"
  self.primary_key = "id"

  has_paper_trail(
    versions: {class_name: "OrgData::UcbPersonHistory"},
    meta: {
      whodunnit: ->(_) { PaperTrail.request.whodunnit || "app_sock" }
    }
  )

  belongs_to(:ucb_org, class_name: "OrgData::OrgUnit", primary_key: "code", foreign_key: "org", optional: true)

  scope(:for_identifier, ->(identifier) {
    for_calnet_uid(identifier)
      .or(for_kerberos_principal(identifier))
  })
  scope(:for_calnet_uid, ->(uid) { where(calnet_uid: uid) })
  scope(:for_kerberos_principal, ->(kp) { where(kerberos_principal: kp) })
  scope(:ilike_kerberos_principal, ->(kp) { where("ucb_people.kerberos_principal ilike ?", "%#{kp}%") })
  scope(:ilike_first_name, ->(name) { where("ucb_people.first_name ilike ?", "%#{name}%") })
  scope(:ilike_last_name, ->(name) { where("ucb_people.last_name ilike ?", "%#{name}%") })
  scope(:ilike_display_name, ->(name) { where("ucb_people.display_name ilike ?", "%#{name}%") })
  scope(:expired, -> { where.not(expired_ts: nil) })
  scope(:active, -> { where(expired_ts: nil) })
  scope(:people_ou, -> { where(ou: "people").where.not(last_name: ["SP_Account", "Guest", "Test"]) })
  scope(:guests_ou, -> { where(ou: "guest") })
  scope(:spa_account, -> { where(last_name: "SP_Account") })

  delegate(:department_name, to: :ucb_org, allow_nil: true)

  attribute(:id, :uuid)
  attribute(:calnet_uid, :integer)
  attribute(:kerberos_principal, :string)
  attribute(:first_name, :string)
  attribute(:last_name, :string)
  attribute(:display_name, :string)
  attribute(:email, :string)
  attribute(:official_email, :string)
  attribute(:ou, :string)
  attribute(:org, :string)
  attribute(:affiliations, :string, array: true)
  attribute(:affiliations_summary, :json, default: -> { {} })
  attribute(:dn, :string)
  attribute(:expired_ts, :datetime)
  attribute(:created_at, :datetime)
  attribute(:updated_at, :datetime)

  alias_attribute(:full_name, :display_name)
  alias_attribute(:calnetid, :kerberos_principal)
  alias_attribute(:username, :kerberos_principal)

  store_accessor(:affiliations_summary, :employee?, :student?, :affiliate?)

  def expire
    update(expired_ts: Time.now)
  end

  def activate
    update(expired_ts: nil)
  end

  def expired?
    expired_ts.present?
  end

  def status
    active? ? "Active" : "Expired"
  end

  def active?
    !expired?
  end

  def update_affiliations_summary
    summary = Ldap::Utils::AffiliationsSummarizer.summary(affiliations)
    update_column(:affiliations_summary, summary)
  end
end
