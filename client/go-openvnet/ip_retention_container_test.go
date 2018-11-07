package openvnet

import "testing"

var ircService = NewIpRetentionContainerService(testClient)
var testIpRetentionContainer = &IpRetentionContainerCreateParams{
	UUID: "irc-test",
}

func TestIpRetentionContainer(t *testing.T) {
	c := NewClient(nil, nil)

	if c.IpRetentionContainer == nil {
		t.Errorf("Interface should not be nil")
	}
}

func TestIpRetentionContainerCreate(t *testing.T) {
	r, _, e := ircService.Create(testIpRetentionContainer)
	if e != nil {
		t.Errorf("Error should be nil")
	}

	checkType(t, new(IpRetentionContainer), r)
}

func TestIpRetentionContainerGet(t *testing.T) {
	r, _, e := ircService.Get()
	if e != nil {
		t.Errorf("Error should be nil")
	}

	checkType(t, new(IpRetentionContainerList), r)
}

func TestIpRetentionContainerGetByUUID(t *testing.T) {
	r, _, e := ircService.GetByUUID(testIpRetentionContainer.UUID)
	if e != nil {
		t.Errorf("Error should be nil")
	}

	checkType(t, new(IpRetentionContainer), r)
}

func TestIpRetentionContainerDelete(t *testing.T) {
	_, e := ircService.Delete(testIpRetentionContainer.UUID)
	if e != nil {
		t.Errorf("Error should be nil")
	}
}
