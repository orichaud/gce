package counterservice

import (
	"context"
	"io/ioutil"
	"log"
	"time"

	counterv1alpha1 "github.com/gce/counter-operator/pkg/apis/counter/v1alpha1"
	appsv1 "k8s.io/api/apps/v1"
	corev1 "k8s.io/api/core/v1"
	"k8s.io/apimachinery/pkg/api/errors"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/apimachinery/pkg/runtime"
	"k8s.io/apimachinery/pkg/types"
	"k8s.io/client-go/kubernetes/scheme"
	"sigs.k8s.io/controller-runtime/pkg/client"
	"sigs.k8s.io/controller-runtime/pkg/controller"
	"sigs.k8s.io/controller-runtime/pkg/controller/controllerutil"
	"sigs.k8s.io/controller-runtime/pkg/handler"
	"sigs.k8s.io/controller-runtime/pkg/manager"
	"sigs.k8s.io/controller-runtime/pkg/reconcile"
	"sigs.k8s.io/controller-runtime/pkg/source"
)

// Add creates a new CounterService Controller and adds it to the Manager. The Manager will set fields on the Controller
// and Start it when the Manager is Started.
func Add(mgr manager.Manager) error {
	return add(mgr, newReconciler(mgr))
}

// newReconciler returns a new reconcile.Reconciler
func newReconciler(mgr manager.Manager) reconcile.Reconciler {

	return &ReconcileCounterService{
		client: mgr.GetClient(),
		scheme: mgr.GetScheme()}
}

// add adds a new Controller to mgr with r as the reconcile.Reconciler
func add(mgr manager.Manager, r reconcile.Reconciler) error {
	// Create a new controller
	c, err := controller.New("counterservice-controller", mgr, controller.Options{Reconciler: r})
	if err != nil {
		return err
	}

	// Watch for changes to primary resource CounterService
	err = c.Watch(&source.Kind{Type: &counterv1alpha1.CounterService{}}, &handler.EnqueueRequestForObject{})
	if err != nil {
		return err
	}

	// TODO(user): Modify this to be the types you create that are owned by the primary resource
	// Watch for changes to secondary resource Pods and requeue the owner CounterService
	err = c.Watch(&source.Kind{Type: &corev1.Pod{}}, &handler.EnqueueRequestForOwner{
		IsController: true,
		OwnerType:    &counterv1alpha1.CounterService{},
	})
	if err != nil {
		return err
	}

	return nil
}

var _ reconcile.Reconciler = &ReconcileCounterService{}

// ReconcileCounterService reconciles a CounterService object
type ReconcileCounterService struct {
	// This client, initialized using mgr.Client() above, is a split client
	// that reads objects from the cache and writes to the apiserver
	client client.Client
	scheme *runtime.Scheme
}

type ReconcilerContext struct {
	reconciler     *ReconcileCounterService
	request        reconcile.Request
	counterService *counterv1alpha1.CounterService
	handlers       []*PackagedObjectHandler
}

// PackagedObjectHandler manages a list of packaged k8s object and process them
type PackagedObjectHandler struct {
	name                string
	reconcileDeployment func(founDep *appsv1.Deployment, rcontext *ReconcilerContext) error
}

func reconcileCounterDeployment(dep *appsv1.Deployment, rcontext *ReconcilerContext) error {
	log.Printf("Reconciling Counter Deploymnet %s/%s\n", dep.Namespace, dep.Name)

	cs := rcontext.counterService
	if *dep.Spec.Replicas != cs.Spec.Backends {
		log.Printf("Counter deployment %s/%s: target backends=%d vs found replicas=%d", cs.Namespace, cs.Name, cs.Spec.Backends, *dep.Spec.Replicas)
		*dep.Spec.Replicas = cs.Spec.Backends
		err := rcontext.reconciler.client.Update(context.TODO(), dep)
		if err != nil {
			return err
		}
	}

	return nil
}

func reconcileRedisDeployment(dep *appsv1.Deployment, context *ReconcilerContext) error {
	log.Printf("Reconciling Redis Deploymnet %s/%s\n", dep.Namespace, dep.Name)
	return nil
}

func newReconcilerContext(reconciler *ReconcileCounterService, request reconcile.Request) (*ReconcilerContext, error) {
	cs := &counterv1alpha1.CounterService{}
	if err := reconciler.client.Get(context.TODO(), request.NamespacedName, cs); err != nil {
		return nil, err
	}
	handlers := []*PackagedObjectHandler{
		&PackagedObjectHandler{name: "counter", reconcileDeployment: reconcileCounterDeployment},
		&PackagedObjectHandler{name: "redis", reconcileDeployment: reconcileRedisDeployment}}

	return &ReconcilerContext{
		reconciler:     reconciler,
		request:        request,
		counterService: cs,
		handlers:       handlers}, nil
}

// Reconcile reads that state of the cluster for a CounterService object and makes changes based on the state read
// and what is in the CounterService.Spec
// The Controller will requeue the Request to be processed again if the returned error is non-nil or
// Result.Requeue is true, otherwise upon completion it will remove the work from the queue.
func (r *ReconcileCounterService) Reconcile(request reconcile.Request) (reconcile.Result, error) {
	log.Printf("Reconciling CounterService %s/%s\n", request.Namespace, request.Name)

	// Fetch the CounterService instance
	context, err := newReconcilerContext(r, request)
	if err != nil {
		if errors.IsNotFound(err) {
			return reconcile.Result{RequeueAfter: time.Second * 5}, nil
		}
		// Error reading the object - requeue the request.
		return reconcile.Result{RequeueAfter: time.Second * 5}, err
	}

	for _, handler := range context.handlers {
		// try create the various deployments and services
		if err := context.ProcessHandler(handler); err != nil {
			return reconcile.Result{RequeueAfter: time.Second * 5}, err
		}
	}

	// return and requeue
	return reconcile.Result{RequeueAfter: time.Second * 5}, nil
}

// ProcessHandler Will create packaged obejcts and adjust with reconciliation
func (rcontext *ReconcilerContext) ProcessHandler(handler *PackagedObjectHandler) error {
	cs := rcontext.counterService

	createOrRetrieve := func(name types.NamespacedName, found runtime.Object) error {
		err := rcontext.reconciler.client.Get(context.TODO(), name, found)
		if err != nil {
			if errors.IsNotFound(err) {
				obj, err := loadDescriptor(name.Name, found)
				if err != nil {
					log.Printf("Cannot load descriptor %s/%s - %s\n", name.Namespace, name.Name, err.Error())
					return err
				}
				desc := obj.(metav1.Object)
				desc.SetNamespace(cs.Namespace)
				desc.SetLabels(cs.Labels)
				err = rcontext.reconciler.client.Create(context.TODO(), obj)
				log.Printf("Creating a new object %s/%s\n", name.Namespace, name.Name)
				if err != nil {
					log.Printf("Cannot create object %s/%s - %s\n", name.Namespace, name.Name, err.Error())
					return err
				}

				if err := controllerutil.SetControllerReference(rcontext.counterService, obj.(metav1.Object), rcontext.reconciler.scheme); err != nil {
					return err
				}
				err = rcontext.reconciler.client.Get(context.TODO(), name, found)
				if err != nil {
					log.Printf("Cannot retrieve object after creation %s/%s - %s\n", name.Namespace, name.Name, err.Error())
					return err
				}

			} else {
				log.Printf("Invalid error found: %s\n", err.Error())
				return err
			}
		}
		desc := found.(metav1.Object)
		log.Printf("Found %T - %s/%s", found, desc.GetNamespace(), desc.GetName())

		return nil
	}

	deploymentName := func(handler *PackagedObjectHandler) types.NamespacedName {
		return types.NamespacedName{Name: handler.name + "-deployment", Namespace: cs.Namespace}
	}
	serviceName := func(handler *PackagedObjectHandler) types.NamespacedName {
		return types.NamespacedName{Name: handler.name + "-service", Namespace: cs.Namespace}
	}

	foundDep := &appsv1.Deployment{}
	if err := createOrRetrieve(deploymentName(handler), foundDep); err != nil {
		return err
	}
	if handler.reconcileDeployment != nil {
		handler.reconcileDeployment(foundDep, rcontext)
	}

	foundSvc := &corev1.Service{}
	if err := createOrRetrieve(serviceName(handler), foundSvc); err != nil {
		return err
	}

	return nil
}

func loadDescriptor(key string, obj runtime.Object) (runtime.Object, error) {
	filename := "../descriptors/" + key + ".yaml"
	content, err := ioutil.ReadFile(filename)
	if err != nil {
		log.Fatalf("cannot read %s\n", filename)
		return nil, err
	}

	decode := scheme.Codecs.UniversalDeserializer().Decode
	desc, _, err := decode([]byte(content), nil, nil)
	if err != nil {
		log.Fatalf("error decoding %s", filename)
		return nil, err
	}

	return desc, nil
}
