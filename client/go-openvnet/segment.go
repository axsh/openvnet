package openvnet

import (
	"net/http"
)

const SegmentNamespace = "segments"

type Segment struct {
	ID        int    `json:"id"`
	UUID      string `json:"uuid"`
	Mode      string `json:"mode"`
	CreatedAt string `json:"created_at"`
	DeletedAt string `json:"deleted_ad"`
	IsDeleted int    `json:"is_deleted"`
}

type SegmentService struct {
	client *Client

	Namespace string
}

type SegmentCreateParams struct {
	UUID string `url:"uuid,omitempty"`
	Mode string `url:"mode"`
}

func (s *SegmentService) Create (params *SegmentCreateParams) (*Segment, *http.Response, error) {
	seg := new(Segment)
	resp, err := s.client.post(SegmentNamespace, seg, params)
	return seg, resp, err
}

func (s *SegmentService) Delete (id string) (*http.Response, error) {
	return s.client.del(SegmentNamespace +"/"+ id)
}
