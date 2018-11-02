package openvnet

import (
	"github.com/dghubble/sling"
)

func testClient() *Client {
	return &Client{sling: sling.New().Base("http://192.168.21.100:9090/api/1.0/").Client(nil)}
}

// crud template

// func testCreate(t *testing.T, i interface{}, s interface{}) {
// 	resource, _, e := s.Create(i)

// 	if e != nil {
// 		t.Error("error should be nil")
// 	}

// 	if resource == nil {
// 		t.Error("resource should not be nil")
// 	}
// }

// func testGet(t *testing.T, s interface{}) {
// 	resources, _, e := s.Get()

// 	if e != nil {
// 		t.Error("error should be nil")
// 	}

// 	if resources == nil {
// 		t.Error("resources should not be nil")
// 	}

// 	if len(resources.Items) != 2 {
// 		t.Error("resources.Items should be length 2")
// 	}
// }

// func testDelete(t *testing.T, i interface{}, s interface{}) {
// 	_, e := s.Delete(i)

// 	if e != nil {
// 		t.Error("error should be nil")
// 	}
// }

// func testGetByUUID(t *testing.T, i interface{}, s interface{}) {
// 	resource, _, e := s.GetByUUID(i)

// 	if e != nil {
// 		t.Error("error should be nil")
// 	}

// 	if resource != nil {
// 		t.Error("resource should not nil")
// 	}
// }
