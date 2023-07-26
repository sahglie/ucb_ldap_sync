class OrgData::UcbPersonHistory < PaperTrail::Version
  self.table_name = "org_data.ucb_people_history"

  scope(:for_item, ->(item) { where(item_id: item) })
  scope(:for_person_id, ->(person_id) { where(item_id: person_id) })
end
