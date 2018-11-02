package openvnet

import (
	"net/http"
	"reflect"
	"strings"
)

type ListBase struct {
	TotalCount int `json:"total_count"`
	Offset     int `json:"offset"`
	Limit      int `json:"limit"`
}

type ItemBase struct {
	ID        int    `json:"id,omitempty"`
	UUID      string `json:"uuid,omitempty"`
	CreatedAt string `json:"created_at,omitempty"`
	UpdatedAt string `json:"updated_at,omitempty"`
	DeletedAt string `json:"deleted_at,omitempty"`
	IsDeleted int    `json:"is_deleted,omitempty"`
}

type Relation struct {
	BaseID           string
	Type             string
	RelationTypeUUID string
}

type BaseService struct {
	client *Client

	namespace    string
	resource     interface{}
	resourceList interface{}
}

func newResource(i interface{}) interface{} {
	t := reflect.TypeOf(i)
	v := reflect.New(t.Elem())
	return v.Interface()
}

func (s *BaseService) Create(i interface{}) (interface{}, *http.Response, error) {
	r := newResource(s.resource)
	resp, err := s.client.post(s.namespace, r, i)
	return r, resp, err
}

func (s *BaseService) Delete(uuid string) (*http.Response, error) {
	return s.client.del(strings.Join([]string{s.namespace, uuid}, "/"))
}

func (s *BaseService) Get() (interface{}, *http.Response, error) {
	r := newResource(s.resourceList)
	resp, err := s.client.get(s.namespace, r)
	return r, resp, err
}

func (s *BaseService) GetByUUID(uuid string) (interface{}, *http.Response, error) {
	r := newResource(s.resource)
	resp, err := s.client.get(strings.Join([]string{s.namespace, uuid}, "/"), r)
	return r, resp, err
}
