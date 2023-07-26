class OrgData::OrgUnitHistory < PaperTrail::Version
  self.table_name = "org_data.org_units_history"

  scope(:for_item, ->(item) { where(item_id: item) })
  scope(:for_code, ->(code) { where(item_id: code) })
end
