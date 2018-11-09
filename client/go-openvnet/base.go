package openvnet

import (
	"log"
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

	relations        []string
	namespace        string
	resource         interface{}
	resourceList     interface{}
	relationServices map[string]*RelationService
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

func (s *BaseService) NewRelationService(resource interface{}, resourceList interface{}, rType string) {
	s.relationServices[rType] = &RelationService{
		relationType: rType,
		resource:     resource,
		resourceList: resourceList,
	}
}

func (s *BaseService) CreateRelation(service string, params interface{}, uuid ...string) (interface{}, *http.Response, error) {
	if len(s.relationServices) < 1 {
		return nil, nil, nil
	}

	return s.relationServices[service].create(s, params, uuid...)
}

func (s *BaseService) DeleteRelation(service string, uuid ...string) (*http.Response, error) {
	if len(s.relationServices) < 1 {
		return nil, nil
	}

	return s.relationServices[service].del(s, uuid...)
}

func (s *BaseService) GetRelations(service string, uuid ...string) (interface{}, *http.Response, error) {
	if len(s.relationServices) < 1 {
		return nil, nil, nil
	}

	return s.relationServices[service].get(s, uuid...)
}

type RelationService struct {
	relationType string
	resource     interface{}
	resourceList interface{}
}

func (s RelationService) joinUUID(namespace string, uuid ...string) string {
	tokens := []string{namespace, uuid[0], s.relationType}
	if len(uuid) == 2 {
		tokens = append(tokens, uuid[1])
	}

	return strings.Join(tokens, "/")
}

func (s *RelationService) create(baseService *BaseService, params interface{}, uuid ...string) (interface{}, *http.Response, error) {
	if s.resource == nil {
		log.Printf("%s create: not implemented", s.relationType)
		return nil, nil, nil
	}

	r := newResource(s.resource)
	resp, err := baseService.client.post(s.joinUUID(baseService.namespace, uuid...), r, params)
	return r, resp, err
}

func (s *RelationService) del(baseService *BaseService, uuid ...string) (*http.Response, error) {
	if s.resource == nil {
		log.Printf("%s delete: not implemented", s.relationType)
		log.Println("warning: not implemented")
		return nil, nil
	}

	return baseService.client.del(s.joinUUID(baseService.namespace, uuid...))
}

func (s *RelationService) get(baseService *BaseService, uuid ...string) (interface{}, *http.Response, error) {
	if s.resourceList == nil {
		log.Printf("%s get: not implemented", s.relationType)
		return nil, nil, nil
	}

	r := newResource(s.resourceList)
	resp, err := baseService.client.post(s.joinUUID(baseService.namespace, uuid...), r, nil)
	return r, resp, err
}
