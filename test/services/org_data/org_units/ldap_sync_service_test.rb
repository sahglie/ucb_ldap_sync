require "test_helper"

class OrgData::OrgUnits::LdapSyncServiceTest < ActiveSupport::TestCase

  def setup
    @service = OrgData::OrgUnits::LdapSyncService.new

    ldap_client = Ldap::Client.new(play_cassettes: true)
    repo = Ldap::Repositories::OrgUnit.new(ldap_client: ldap_client)

    @ucbkl = repo.find_by_code("UCBKL")
    @vrsec = repo.find_by_code("VRSEC")
    @coeng = repo.find_by_code("COENG")

    OrgData::OrgUnit.where.not(code: codes(@ucbkl, @vrsec, @coeng)).delete_all
  end

  def codes(*units)
    units.map(&:code)
  end

  test "adds org units" do
    assert_equal(3, OrgData::OrgUnit.count)

    new_org = Ldap::Entities::OrgUnit.new(
      code: "CAMSU",
      name: "Campus Support",
      level: 2,
      hierarchy: "UCBKL.CAMSU"
    )

    assert_difference(
      -> { OrgData::OrgUnit.active.count } => 1,
      -> { OrgData::OrgUnitHistory.count } => 1
    ) do
      @service.sync(ldap_orgs: [new_org, @ucbkl, @vrsec, @coeng])
    end
  end

  test "updates org units" do
    @ucbkl.name = "UC Berkeley"
    assert_difference(
      -> { OrgData::OrgUnit.active.count } => 0,
      -> { OrgData::OrgUnit.expired.count } => 0,
      -> { OrgData::OrgUnitHistory.count } => 1,
    )do
      @service.sync(ldap_orgs: [@ucbkl, @vrsec, @coeng])
    end
  end

  test "expires org units" do
    assert_difference(
      -> { OrgData::OrgUnit.expired.count } => 3,
      -> { OrgData::OrgUnit.active.count } => -3,
      -> { OrgData::OrgUnitHistory.count } => 3
    ) do
      @service.sync(ldap_orgs: [])
    end
  end

  test "activates org units" do
    org_data_org_units(:vrsec).expire

    assert_difference(
      -> { OrgData::OrgUnit.active.count } => 1,
      -> { OrgData::OrgUnitHistory.count } => 1
    ) do
      @service.sync(ldap_orgs: [@ucbkl, @vrsec, @coeng])
    end
  end
end
