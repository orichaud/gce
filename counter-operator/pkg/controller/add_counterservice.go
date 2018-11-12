package controller

import (
	"github.com/gce/counter-operator/pkg/controller/counterservice"
)

func init() {
	// AddToManagerFuncs is a list of functions to create controllers and add them to a manager.
	AddToManagerFuncs = append(AddToManagerFuncs, counterservice.Add)
}
