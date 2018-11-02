package openvnet

import "net/http"

type Translation struct {
	ItemBase
	Mode        string `json:"mode"`
	InterfaceID int    `json:"interface_id"`
	Passthrough bool   `json:"passthrough"`
}

type TranslationList struct {
	ListBase
	Items []Translation
}

type TranslationService struct {
	*BaseService
}

type TranslationCreateParams struct {
	UUID          string `url:"uuid,omitempty"`
	InterfaceUUID string `url:"interface_uuid"`
	Mode          string `url:"mode"`
	Passthrough   bool   `url:"passthrough,omitempty"`
}

func NewTranslationService(client *Client) *TranslationService {
	return &TranslationService{
		BaseService: &BaseService{
			client:       client,
			namespace:    "translations",
			resource:     &Translation{},
			resourceList: &TranslationList{},
		},
	}
}

func (s *TranslationService) Create(params *TranslationCreateParams) (*Translation, *http.Response, error) {
	item, resp, err := s.BaseService.Create(params)
	return item.(*Translation), resp, err
}

func (s *TranslationService) Get() (*TranslationList, *http.Response, error) {
	item, resp, err := s.BaseService.Get()
	return item.(*TranslationList), resp, err
}

func (s *TranslationService) GetByUUID(uuid string) (*TranslationList, *http.Response, error) {
	item, resp, err := s.BaseService.GetByUUID(uuid)
	return item.(*TranslationList), resp, err
}
