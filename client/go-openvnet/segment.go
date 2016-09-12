package openvnet

import (
	"net/http"
)

const SegmentNamespace = "segments"

type Segment struct {
	ItemBase
	Mode string `json:"mode"`
}

type SegmentList struct {
	ListBase
	Items []Segment
}

type SegmentService struct {
	client *Client
}

type SegmentCreateParams struct {
	UUID string `url:"uuid,omitempty"`
	Mode string `url:"mode"`
}

func (s *SegmentService) Create(params *SegmentCreateParams) (*Segment, *http.Response, error) {
	seg := new(Segment)
	resp, err := s.client.post(SegmentNamespace, seg, params)
	return seg, resp, err
}

func (s *SegmentService) Delete(id string) (*http.Response, error) {
	return s.client.del(SegmentNamespace + "/" + id)
}

func (s *SegmentService) Get() (*SegmentList, *http.Response, error) {
	list := new(SegmentList)
	resp, err := s.client.get(SegmentNamespace, list)
	return list, resp, err
}

func (s *SegmentService) GetByUUID(id string) (*Segment, *http.Response, error) {
	seg := new(Segment)
	resp, err := s.client.get(SegmentNamespace+"/"+id, seg)
	return seg, resp, err
}
