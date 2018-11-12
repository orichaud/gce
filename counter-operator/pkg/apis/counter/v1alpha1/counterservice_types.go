package v1alpha1

import (
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
)

// CounterServiceSpec defines the desired state of CounterService
type CounterServiceSpec struct {
	Backends int32 `json:"backends"`
}

// CounterServiceStatus defines the observed state of CounterService
type CounterServiceStatus struct {
	Backends int32 `json:"backends"`
}

// +k8s:deepcopy-gen:interfaces=k8s.io/apimachinery/pkg/runtime.Object

// CounterService is the Schema for the counterservices API
// +k8s:openapi-gen=true
type CounterService struct {
	metav1.TypeMeta   `json:",inline"`
	metav1.ObjectMeta `json:"metadata,omitempty"`

	Spec   CounterServiceSpec   `json:"spec,omitempty"`
	Status CounterServiceStatus `json:"status,omitempty"`
}

// +k8s:deepcopy-gen:interfaces=k8s.io/apimachinery/pkg/runtime.Object

// CounterServiceList contains a list of CounterService
type CounterServiceList struct {
	metav1.TypeMeta `json:",inline"`
	metav1.ListMeta `json:"metadata,omitempty"`
	Items           []CounterService `json:"items"`
}

func init() {
	SchemeBuilder.Register(&CounterService{}, &CounterServiceList{})
}
