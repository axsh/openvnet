package openvnet

import (
	"github.com/hashicorp/terraform/helper/schema"
)

type relationCallback func(map[string]interface{}) (interface{}, error)

func parseRelation(d *schema.ResourceData, t string, fn relationCallback) ([]interface{}, error) {
	relations := make([]interface{}, 0)
	if r := d.Get(t[:len(t)-1]); r != nil {
		for _, relationTypeMap := range r.([]interface{}) {
			relationResource, err := fn(relationTypeMap.(map[string]interface{}))
			if err != nil {
				return nil, err
			}

			relations = append(relations, relationResource)
		}
	}
	return relations, nil
}
