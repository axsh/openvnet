package openvnet

import (
	"io"
	"log"
	"net"
	"net/http"
	"net/http/httptest"
	"os"
	"reflect"
	"testing"

	"github.com/dghubble/sling"
)

var testClient = &Client{sling: sling.New().Base("http://localhost:9090/api/1.0/").Client(nil)}

type testService struct {
	*BaseService
}

type testData struct {
	ItemBase
}

var ts = &testService{
	BaseService: &BaseService{
		namespace:    "test",
		client:       testClient,
		resource:     &testData{},
		resourceList: &testData{},
	},
}

func checkType(t *testing.T, expected interface{}, recieved interface{}) {
	typeOfRecieved := reflect.TypeOf(recieved)
	typeOfExpected := reflect.TypeOf(expected)

	if typeOfExpected != typeOfRecieved {
		t.Errorf("Resource %s should be %s", typeOfRecieved.String(), typeOfExpected.String())
	}

}

func checkBody(t *testing.T, body io.ReadCloser) {
	b := make([]byte, 0)
	if _, e := body.Read(b); e != nil && e != io.EOF {
		log.Fatalf("failed to read response body: %v", e)
	}
	defer body.Close()

	if len(b) != 0 {
		t.Errorf("Body should be empty was: %d", len(b))
	}
}

func TestCreate(t *testing.T) {
	_, resp, e := ts.Create(&testData{})

	if e != nil {
		t.Errorf("Create() error should be nil: %v", e)
	}

	if resp.StatusCode != 204 {
		t.Errorf("Status code should be 200")
	}

	checkBody(t, resp.Body)
}

func TestGet(t *testing.T) {
	_, resp, e := ts.Get()

	if e != nil {
		t.Errorf("Get() error should be nil: %v", e)
	}

	if resp.StatusCode != 204 {
		t.Errorf("Status code should be 200")
	}
}

func TestDelete(t *testing.T) {
	resp, e := ts.Delete("test_id")

	if e != nil {
		t.Errorf("Delete() error should be nil: %v", e)
	}

	if resp.StatusCode != 204 {
		t.Errorf("Status code should be 200")
	}

	checkBody(t, resp.Body)
}

func TestGetByUUID(t *testing.T) {
	_, resp, e := ts.GetByUUID("test_id")

	if e != nil {
		t.Errorf("GetByUUID() error should be nil: %v", e)
	}

	if resp.StatusCode != 204 {
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
			Handler: http.HandlerFunc(func(rw http.ResponseWriter, req *http.Request) {
				rw.Header().Set("Content-Type", "application/json")
				rw.WriteHeader(204) // no-content
			}),
		},
	}
	server.Start()
	defer server.Close()

	os.Exit(m.Run())
}
