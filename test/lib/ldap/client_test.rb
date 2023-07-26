require "test_helper"

class Ldap::ClientTest < ActiveSupport::TestCase
  def setup
    @client = Ldap::Client.new(play_cassettes: true)
  end

  test "find_by_uid(uid)" do
    entry = @client.find_by_uid(61065)
    assert_equal("uid=61065,ou=people,dc=berkeley,dc=edu", entry.dn.to_s)
    assert_kind_of(Net::LDAP::Entry, entry)
  end

  test "find_by_calnetid(calnetid)" do
    entry = @client.find_by_calnetid("runner")
    assert_equal("uid=61065,ou=people,dc=berkeley,dc=edu", entry.dn.to_s)
    assert_kind_of(Net::LDAP::Entry, entry)
  end

  test "find_by_org_code" do
    entry = @client.find_org_by_code("VRSEC")
    assert_equal("ou=VRSEC,ou=VRIST,ou=VCBAS,ou=CAMSU,ou=UCBKL,ou=Org Units,dc=berkeley,dc=edu", entry.dn.to_s)
    assert_kind_of(Net::LDAP::Entry, entry)
  end
end
