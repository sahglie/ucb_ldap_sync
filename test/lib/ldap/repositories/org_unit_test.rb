require "test_helper"

class Ldap::Repositories::OrgUnitTest < ActiveSupport::TestCase
  def setup
    ldap_client = Ldap::Client.new(play_cassettes: true)
    @repo = Ldap::Repositories::OrgUnit.new(ldap_client: ldap_client)
  end

  test "find_by_code" do
    org_unit = @repo.find_by_code("VRSEC")

    assert_equal("VRSEC", org_unit.code)
    assert_equal("Information Security Office", org_unit.name)
    assert_equal(5, org_unit.level)
    assert_equal("UCBKL.CAMSU.VCBAS.VRIST.VRSEC", org_unit.hierarchy)
    assert_kind_of(Ldap::Entities::OrgUnit, org_unit)
  end
end
