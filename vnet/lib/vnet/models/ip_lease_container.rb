module Vnet::Models
  class IpLeaseContainer < Base
    taggable 'ilc'

    one_to_many :ip_lease_container_ip_leases
    many_to_many :ip_leases, join_table: :ip_lease_container_ip_leases

    one_to_many :lease_policy_ip_lease_container
    many_to_many :lease_policies, join_table: :lease_policy_ip_lease_container
  end
end
