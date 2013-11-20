# -*- coding: utf-8 -*-

Vnet::Endpoints::V10::VnetAPI.namespace '/tunneling_protocols' do
  put_post_shared_params = [
    "src_dc_segment_uuid",
    "dst_dc_segment_uuid",
    "protocol"
  ]

  fill_options = []

  post do
    accepted_params = put_post_shared_params + ["uuid"]
    required_params = ["src_dc_segment_uuid", "dst_dc_segment_uuid", "protocol"]

    post_new(:TunnelingProtocol, accepted_params, required_params, fill_options) { |params|

      if params["src_dc_segment_uuid"]
        dc_segment_uuid = params.delete("src_dc_segment_uuid")
        check_uuid_syntax(M::DcSegment, dc_segment_uuid)
        params["src_dc_segment_id"] = (M::DcSegment[dc_segment_uuid] || M::DcSegment.create(uuid: dc_segment_uuid)).id
      end

      if params["dst_dc_segment_uuid"]
        dc_segment_uuid = params.delete("dst_dc_segment_uuid")
        check_uuid_syntax(M::DcSegment, dc_segment_uuid)
        params["dst_dc_segment_id"] = (M::DcSegment[dc_segment_uuid] || M::DcSegment.create(uuid: dc_segment_uuid)).id
      end
    }
  end

  get do
    get_all(:TunnelingProtocol, fill_options)
  end

  get '/:uuid' do
    get_by_uuid(:TunnelingProtocol, fill_options)
  end

  delete '/:uuid' do
    delete_by_uuid(:TunnelingProtocol)
  end

  put '/:uuid' do
    update_by_uuid(:TunnelingProtocol, put_post_shared_params, fill_options) { |params|
      check_syntax_and_get_id(M::DcSegment, params, "src_dc_segment_uuid", "src_dc_segment_id") if params["src_dc_segment_uuid"]
      check_syntax_and_get_id(M::DcSegment, params, "dst_dc_segment_uuid", "dst_dc_segment_id") if params["dst_dc_segment_uuid"]
    }
  end
end
