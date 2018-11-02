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
	*BaseService
}

type SegmentCreateParams struct {
	UUID string `url:"uuid,omitempty"`
	Mode string `url:"mode"`
}

func NewSegmentService(client *Client) *SegmentService {
	return &SegmentService{
		BaseService: &BaseService{
			client:       client,
			namespace:    SegmentNamespace,
			resource:     &Segment{},
			resourceList: &SegmentList{},
		},
	}
}

func (s *SegmentService) Create(params *SegmentCreateParams) (*Segment, *http.Response, error) {
	item, resp, err := s.BaseService.Create(params)
	return item.(*Segment), resp, err
}

func (s *SegmentService) Get() (*SegmentList, *http.Response, error) {
	item, resp, err := s.BaseService.Get()
	return item.(*SegmentList), resp, err
}

func (s *SegmentService) GetByUUID(id string) (*Segment, *http.Response, error) {
	item, resp, err := s.BaseService.GetByUUID(id)
	return item.(*Segment), resp, err
}
