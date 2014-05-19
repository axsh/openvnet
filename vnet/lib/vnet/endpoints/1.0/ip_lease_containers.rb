Vnet::Endpoints::V10::VnetAPI.namespace '/ip_lease_containers' do
  def self.put_post_shared_params
  end

  put_post_shared_params
  param_uuid M::IpLeaseContainer
  post do
    post_new(:IpLeaseContainer)
  end

  get do
    get_all(:IpLeaseContainer)
  end

  get '/:uuid' do
    get_by_uuid(:IpLeaseContainer)
  end

  delete '/:uuid' do
    delete_by_uuid(:IpLeaseContainer)
  end

  put_post_shared_params
  put '/:uuid' do
    update_by_uuid(:IpLeaseContainer)
  end

  get '/:uuid/ip_leases' do
    show_relations(:IpLeaseContainer, :ip_leases)
  end
end
