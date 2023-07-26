require "test_helper"

class Ldap::Repositories::PersonTest < ActiveSupport::TestCase
  def setup
    ldap_client = Ldap::Client.new(play_cassettes: true)
    @repo = Ldap::Repositories::Person.new(ldap_client: ldap_client)
  end

  test "find_by_calnetid(calnetid)" do
    entity = @repo.find_by_calnetid("runner")
    assert_equal("runner", entity.kerberos_principal)
    assert_equal("uid=61065,ou=people,dc=berkeley,dc=edu", entity.dn)
    assert_kind_of(Ldap::Entities::Person, entity)
  end

  test "find_by_uid(uid)" do
    entity = @repo.find_by_uid(61065)
    assert_equal("runner", entity.kerberos_principal)
    assert_equal("uid=61065,ou=people,dc=berkeley,dc=edu", entity.dn)
    assert_kind_of(Ldap::Entities::Person, entity)
  end
end
