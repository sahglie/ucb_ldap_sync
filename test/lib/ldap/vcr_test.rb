require "test_helper"

class Ldap::VcrTest < ActiveSupport::TestCase

  def setup
    @ldap_vcr = Ldap::Vcr.new
  end

  test "load_by_uid" do
    entry = @ldap_vcr.load_by_uid(61065)
    assert_equal("61065", entry["uid"].first)
    assert_equal("runner@berkeley.edu", entry["mail"].first)
  end

  test "load_by_calnetid" do
    entry = @ldap_vcr.load_by_calnetid("runner")
    assert_equal("runner", entry["berkeleyedukerberosprincipalstring"].first)
    assert_equal("runner@berkeley.edu", entry["mail"].first)
  end

  test "load_by_code" do
    entry = @ldap_vcr.load_by_code("VRSEC")
    assert_equal("VRSEC", entry["ou"].first)
  end
end
