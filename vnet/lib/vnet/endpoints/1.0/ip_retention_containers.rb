Vnet::Endpoints::V10::VnetAPI.namespace '/ip_retention_containers' do
  get do
    get_all(:IpRetentionContainer)
  end

  get '/:uuid' do
    get_by_uuid(:IpRetentionContainer)
  end

  get '/:uuid/ip_retentions' do
    show_relations(:IpRetentionContainer, :ip_retentions)
  end
end
