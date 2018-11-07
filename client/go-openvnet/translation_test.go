package openvnet

import "testing"

var trService = NewTranslationService(testClient())

func TestTranslation(t *testing.T) {
	c := NewClient(nil, nil)

	if c.Translation == nil {
		t.Errorf("Segment should not be nil")
	}
}

func TestTranslationCreate(t *testing.T) {
	r, _, e := trService.Create(testTranslation)
	if e != nil {
		t.Errorf("Error should be nil")
	}

	checkType(t, new(Translation), r)
}

func TestTranslationGet(t *testing.T) {
	r, _, e := trService.Get()
	if e != nil {
		t.Errorf("Error should be nil")
	}

	checkType(t, new(TranslationList), r)
}

func TestTranslationGetByUUID(t *testing.T) {
	r, _, e := trService.GetByUUID(testTranslation.UUID)
	if e != nil {
		t.Errorf("Error should be nil")
	}

	checkType(t, new(Translation), r)
}

func TestTranslationDelete(t *testing.T) {
	_, e := trService.Delete(testTranslation.UUID)
	if e != nil {
		t.Errorf("Error should be nil")
	}
}
