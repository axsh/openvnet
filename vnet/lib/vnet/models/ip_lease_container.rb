module Vnet::Models

  # TODO: Refactor.
  class IpLeaseContainer < Base
    taggable 'ilc'

    one_to_many :ip_lease_container_ip_leases
    many_to_many :ip_leases, join_table: :ip_lease_container_ip_leases, :conditions => "ip_lease_container_ip_leases.deleted_at is null"

    one_to_many :lease_policy_ip_lease_containers
    many_to_many :lease_policies, join_table: :lease_policy_ip_lease_containers, :conditions => "lease_policy_ip_lease_containers.deleted_at is null"

    plugin :association_dependencies,
    # 0001_origin
    ip_lease_container_ip_leases: :destroy,
    # 0002_services
    lease_policy_ip_lease_containers: :destroy

  end
end
