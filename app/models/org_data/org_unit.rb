class OrgData::OrgUnit < ApplicationRecord
  self.table_name = "org_data.org_units"
  self.primary_key = "code"

  has_paper_trail(
    versions: {class_name: "OrgData::OrgUnitHistory"},
    meta: {
      whodunnit: ->(_) { PaperTrail.request.whodunnit || "app_sock" }
    }
  )
  scope(:in_hierarchy, ->(code) { where("ltree2text(hierarchy) ilike ?", "%#{code}%") })
  scope(:active, -> { where(expired_ts: nil) })
  scope(:expired, -> { where.not(expired_ts: nil) })
  scope(:for_code, -> (code) { where("lower(code) = ?", code&.downcase) })

  attribute(:code, :string)
  attribute(:name, :string)
  attribute(:hierarchy, :string)
  attribute(:level, :integer)
  attribute(:dn, :string)
  attribute(:expired_ts, :datetime)
  attribute(:created_at, :datetime)
  attribute(:created_at, :datetime)

  alias_attribute(:org_node, :code)
  alias_attribute(:department_name, :name)

  before_save { self.code = code.to_s.upcase }

  def expire
    update(expired_ts: Time.now)
  end

  def activate
    update(expired_ts: nil)
  end

  def root_node?
    code == "UCBKL"
  end

  def child_node?
    org_node != "UCBKL"
  end
end
