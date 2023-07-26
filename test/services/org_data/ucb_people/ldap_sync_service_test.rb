require "test_helper"

class OrgData::UcbPeople::LdapSyncServiceTest < ActiveSupport::TestCase

  def setup
    @service = OrgData::UcbPeople::LdapSyncService.new

    ldap_client = Ldap::Client.new(play_cassettes: true)
    repo = Ldap::Repositories::Person.new(ldap_client: ldap_client)

    @runner = repo.find_by_calnetid("runner")
    @jake = repo.find_by_calnetid("jakef")
    @akhenry = repo.find_by_calnetid("akhenry")

    OrgData::UcbPerson.where.not(kerberos_principal: calnetids(@runner, @jake, @akhenry)).delete_all
  end

  def calnetids(*records)
    records.map(&:kerberos_principal)
  end

  test "adds people" do
    new_record = Ldap::Entities::Person.new(
      uid: 1,
      kerberos_principal: "a",
      given_name: "gn",
      sn: "sn",
      display_name: "gn sn",
      email: "email@b.e",
      official_email: "email@b.e",
      primary_dept_unit: "xxx",
      ou: "people",
      affiliations: ["a", "b"],
      dn: "x"
    )

    ldap_records = [new_record, @runner, @jake, @akhenry]
    assert_difference(
      -> { OrgData::UcbPerson.active.count } => 1,
      -> { OrgData::UcbPersonHistory.count } => 1
    ) do
      @service.sync(ldap_records: ldap_records)
    end
  end

  test "updates people" do
    modified_record = Ldap::Entities::Person.new(
      uid: 61065,
      kerberos_principal: "runner",
      given_name: "Steven",
      sn: "Hansen",
      display_name: "Steven Hansen",
      email: "runner@berkeley.edu",
      official_email: "runner@berkeley.edu",
      primary_dept_unit: "JFAVC",
      ou: "people",
      affiliations: ["FORMER-EMPLOYEE"], # change the affiliations
      dn: "uid=61065,ou=people,dc=berkeley,dc=edu"
    )

    ldap_records = [modified_record, @jake, @akhenry]
    assert_difference(-> { OrgData::UcbPersonHistory.count } => 1) do
      @service.sync(ldap_records: ldap_records)
    end
  end

  test "expires people" do
    assert_difference(
      -> { OrgData::UcbPerson.expired.count } => 3,
      -> { OrgData::UcbPerson.active.count } => -3,
      -> { OrgData::UcbPersonHistory.count } => 3
    ) do
      @service.sync(ldap_records: [])
    end
  end

  test "activates people" do
    ucb_people(:runner).expire

    assert_difference(
      -> { OrgData::UcbPerson.active.count } => 1,
      -> { OrgData::UcbPersonHistory.count } => 1
    ) do
      @service.sync(ldap_records: [@runner, @jake, @akhenry])
    end
  end
end
