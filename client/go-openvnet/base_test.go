package openvnet

import (
	"log"
	"net"
	"net/http"
	"net/http/httptest"
	"os"
	"testing"
)

type testService struct {
	*BaseService
}

type testData struct {
	ItemBase
}

var ts = &testService{
	BaseService: &BaseService{
		namespace:    "test",
		client:       testClient(),
		resource:     &testData{},
		resourceList: &testData{},
	},
}

func TestCreate(t *testing.T) {
	_, resp, e := ts.Create(&testData{})

	if e != nil {
		t.Errorf("Create() error should be nil: %v", e)
	}

	if resp.StatusCode != 200 {
		t.Errorf("Status code should be 200")
	}

	checkBody(t, resp.Body)
}

func TestGet(t *testing.T) {
	_, resp, e := ts.Get()

	if e != nil {
		t.Errorf("Get() error should be nil: %v", e)
	}

	if resp.StatusCode != 200 {
		t.Errorf("Status code should be 200")
	}
}

func TestDelete(t *testing.T) {
	resp, e := ts.Delete("test_id")

	if e != nil {
		t.Errorf("Delete() error should be nil: %v", e)
	}

	if resp.StatusCode != 200 {
		t.Errorf("Status code should be 200")
	}

	checkBody(t, resp.Body)
}

func TestGetByUUID(t *testing.T) {
	_, resp, e := ts.GetByUUID("test_id")

	if e != nil {
		t.Errorf("GetByUUID() error should be nil: %v", e)
	}

	if resp.StatusCode != 200 {
		t.Errorf("Status code should be 200")
	}

	checkBody(t, resp.Body)
}

func TestMain(m *testing.M) {
	l, err := net.Listen("tcp", net.JoinHostPort("localhost", "9090"))
	if err != nil {
		log.Fatal("failed to create listener")
	}
	server := &httptest.Server{
		Listener: l,
		Config: &http.Server{
			Handler: http.HandlerFunc(func(rw http.ResponseWriter, req *http.Request) {}),
		},
	}
	server.Start()
	defer server.Close()

	os.Exit(m.Run())
}
