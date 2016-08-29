package openvnet

import (
	"fmt"
	"net/http"

)

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

type SegmentCreateParms struct {
	UUID string `url:"uuid,omitempty"`
	Mode string `url:"mode"`
}

func (s *SegmentService) Create (params *SegmentCreateParms) (*Segment, *http.Response, error) {
}

func (s *SegmentService) Delete (id string) (*http.Response, error) {

}
