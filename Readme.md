# A simple GKE step-by-step example

## Objective

This is a simple tutorial including some advanced concepts like autoscaler and POD disruption budget for those wanting to start with Google Cloud and Kubernetes. It is based on a simple GO program. 

2 deployments are defined:
* `counter-deployment` spawns a single container running a go program with 2 URIs `/counter` (container lcoal counter) and `/redis` (global redis counter);
* a `redis-deployment` that runs a single Redis instance. It will host a single global counter incremented by invoking the `/redis` URI.

You can simply clone this project and follow the instructions defined in this page.

## Prequisites

We assume you have installed:
* [GO](https://golang.org) 
* [gcloud]( https://cloud.google.com/sdk/)
* [kubectl]( https://kubernetes.io/docs/tasks/tools/install-kubectl/)
* [Docker](https://docs.docker.com/install/): In particular, a local registry must be run and it will be used to push images to Google Container Repository.

***Tip*** if you use MacOS, use [brew](https://brew.sh) to install all the prerequisites.

It also assumes you have created or can create a Google Cloud project that will host the Kubernetes cluster and the deployment of the PODs.

## Google Cloud account set up

To initialize the environment and connect to your Google account, you will run the following commands. It assumes you have a GCP account:

``` sh
gcloud init
gcloud auth login
```

## Setup

You must have created a project. If not, please create a Google Cloud project with the Google Console. You can define the default project (you can refer to this [page](https://cloud.google.com/kubernetes-engine/docs/quickstart)):

``` sh 
gcloud config set project <myProject>
```

Then, you can define the regions you want to use and select a default one:

```sh
gcloud compute project-info add-metadata \
    --metadata google-compute-default-region=europe-west1 google-compute-default-zone=europe-west1-b
gcloud config set compute/zone europe-west1-b
```

You can configure your ssh access:

``` sh
gcloud compute config-ssh
```

## Git

In case you want to access and contribute:
* [https://github.com/orichaud/gce.git](https://github.com/orichaud/gce.git)


## Creation of the GKE cluster

To deploy the cluster and perform operatiosn on the clusters, you will call the predefined script `gke_admin.sh`. It will assume the `default` zone has been defined. Otherwise it will will request the selection of a zone:

``` sh
./gke_admin.sh --create-cluster
```

The result is the creation of a GKE cluster belonging to your default project as defined previously. You can check the status of your cluster. Please note that starting from this point, your `kubectl` CLI will point to that cluster hosted in Google Cloud. 

``` sh
kubectl cluster-info

Kubernetes master is running at https://35.205.126.111
GLBCDefaultBackend is running at https://35.205.126.111/api/v1/namespaces/kube-system/services/default-http-backend:http/proxy
Heapster is running at https://35.205.126.111/api/v1/namespaces/kube-system/services/heapster/proxy
KubeDNS is running at https://35.205.126.111/api/v1/namespaces/kube-system/services/kube-dns:dns/proxy
kubernetes-dashboard is running at https://35.205.126.111/api/v1/namespaces/kube-system/services/https:kubernetes-dashboard:/proxy

```

To delete your cluster:

``` sh
./gke_admin.sh --delete-cluster
```

## Building and deploying the docker image

You can go to the second step which is the full depployment of a simple GO program incrementing a counter. The source files can be foudn in `src/main` directory.
You must first compile the go source file. The script will build for 2 targets: MacOS and for Linux in the `bin` directory. The Linux version will be used to create the Docker image. The `Makefile` will be used:

``` sh
make build
```

You can build the docker image and push the image to the Google Container Repository (in our case the one hosted in Europe). This is the latest version of the image that will be picked up by Kubernetes to schedule the deployment of your POD. The base image is based on the latest Golang image:

``` sh
DOCKER_REPO=eu.gcr.io PROJECT=<My Project> make docker
```

## Deployment of the cluster on GKE

Once the image is available in GCR, you can go to the next step, and start the effective deployment of your cluster. 2 options are available:

### Use descriptors

First option is with descriptors (see YMAL files defining the various objects). This will first create a deployment object, asssociate an autoscaler, a POD disruption budget and finally create a Load Balancer directly accessilble on the public Internet.
The approach is a declarative approach which sets the target for the desired state and let Kubernetes apply the changes. This is why `kubectl apply` is used in the script in stead of `kubectl create`.
You must update the `counter-deployment.yaml` file and update the image URL accordingly so that it matching your target repo and project as we use Google Container Repository:

``` sh
image: <DOCKER REPO>/<My Project>/hserver
```

Then you can trigger the create of the cluster and the namespace that will host the deployment:

``` sh
./gke_admin.sh --deploy

+ deploy: deploy with descriptors into cluster or-cluster
deployment.apps "redis-master" created
service "redis-service" created
deployment.apps "counter-deployment" created
horizontalpodautoscaler.autoscaling "counter-hpa" created
poddisruptionbudget.policy "counter-pdb" created
service "counter-service" created
+ deploy: finished
# done
```

Then to dismantle:

``` sh
./gke_admin.sh --undeploy

+ undeploy: undeploy with descriptors from cluster or-cluster
service "counter-service" deleted
deployment.apps "counter-deployment" deleted
horizontalpodautoscaler.autoscaling "counter-hpa" deleted
poddisruptionbudget.policy "counter-pdb" deleted
deployment.apps "redis-master" deleted
service "redis-service" deleted
+ undeploy: finished
# done
```

### Use only CLI

Second option is with CLI options. This is too limited and discontinued.

### Final deployment

For example with the first option, the output shoud look like what follows:

``` sh
kubectl get all --namespace=orns --show-labels

AME                                      READY     STATUS    RESTARTS   AGE       LABELS
pod/counter-deployment-6984666dc4-52lsb   1/1       Running   0          12m       app=counter,env=test,pod-template-hash=2540222870
pod/counter-deployment-6984666dc4-flmzr   1/1       Running   0          12m       app=counter,env=test,pod-template-hash=2540222870
pod/counter-deployment-6984666dc4-h6qkr   1/1       Running   0          12m       app=counter,env=test,pod-template-hash=2540222870
pod/redis-master-8444588cb-qs2t6          1/1       Running   0          12m       app=redis,env=test,pod-template-hash=400014476

NAME                      TYPE           CLUSTER-IP      EXTERNAL-IP      PORT(S)          AGE       LABELS
service/counter-service   LoadBalancer   10.27.253.253   35.205.246.235   8080:31336/TCP   12m       <none>
service/redis-service     ClusterIP      10.27.251.95    <none>           6379/TCP         12m       app=redis,env=test

NAME                                       DESIRED   CURRENT   UP-TO-DATE   AVAILABLE   AGE       LABELS
deployment.extensions/counter-deployment   3         3         3            3           12m       app=counter,env=test
deployment.extensions/redis-master         1         1         1            1           12m       app=redis

NAME                                                  DESIRED   CURRENT   READY     AGE       LABELS
replicaset.extensions/counter-deployment-6984666dc4   3         3         3         12m       app=counter,env=test,pod-template-hash=2540222870
replicaset.extensions/redis-master-8444588cb          1         1         1         12m       app=redis,env=test,pod-template-hash=400014476

NAME                                 DESIRED   CURRENT   UP-TO-DATE   AVAILABLE   AGE       LABELS
deployment.apps/counter-deployment   3         3         3            3           12m       app=counter,env=test
deployment.apps/redis-master         1         1         1            1           12m       app=redis

NAME                                            DESIRED   CURRENT   READY     AGE       LABELS
replicaset.apps/counter-deployment-6984666dc4   3         3         3         12m       app=counter,env=test,pod-template-hash=2540222870
replicaset.apps/redis-master-8444588cb          1         1         1         12m       app=redis,env=test,pod-template-hash=400014476

NAME                                              REFERENCE                       TARGETS   MINPODS   MAXPODS   REPLICAS   AGE       LABELS
horizontalpodautoscaler.autoscaling/counter-hpa   Deployment/counter-deployment   0%/10%    3         10        3          12m       <none>
```

## Testing

You can check the service with `kubectl get services --namespace=orns`. The `counter-service` service is available for external traffic once the EXTERNAL-IP is defined and not marked as pending. The `redis-service` is just a ClusterIP accessible within the cluster to expose the Redis instance.

``` sh
NAME              TYPE           CLUSTER-IP      EXTERNAL-IP      PORT(S)          AGE
counter-service   LoadBalancer   10.27.253.253   35.205.246.235   8080:31336/TCP   11m
redis-service     ClusterIP      10.27.251.95    <none>           6379/TCP         11m
```

The script will check the availability of the EXTERNAL-IP and try every second until the service becomes ready.
You can run the test:

``` sh
./gke_admin.sh --test
```

whose output is:

``` sh
+ test: invoking service
URL:      http://35.195.16.161:8080/counter
Response: {"status":"OK","host":"counter-deployment-6984666dc4-flmzr","response":"7","type":"count"}
...
URL:      http://35.205.246.235:8080/redis
Response: {"status":"OK","host":"counter-deployment-6984666dc4-52lsb","response":"13","type":"kcount"}
...
# done
```
you will notice the 2 URIs invoked:
* `/counter` invokes the atomic counter local to a POD.
* `/redis` will access `kcount` variable managed by the Redis instance. This results in incrementing a global counter.