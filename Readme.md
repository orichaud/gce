# Objective
This is a simple tutorial including some advanced concepts like autoscaler and POD disruption budget for those wnting to start with Google Cloud and Kubernetes. It ias based on a simple GO program. 

You can simply clone this project and follow the instructions defined in this page.

# Prequisites
We assume you have installed:
* [gcloud]( https://cloud.google.com/sdk/)
* [kubectl]( https://kubernetes.io/docs/tasks/tools/install-kubectl/)
* [Docker](https://docs.docker.com/install/): In particular, a local registry must be run and it will be used to push images to Google Container Repository.

# Google Cloud account set up


To initialize the environment and connect to your google account, you will run the following commands. It assumes you have a GCP account:
``` sh
gcloud init
gcloud auth login
```

#Setup
You must have created a project. If not, please creta ea Google Cloud project with the Google Console. You can define the default project (you can refer to this [page](https://cloud.google.com/kubernetes-engine/docs/quickstart)):
```sh
gcloud config set project myProject
```
Then, you can define the regions you want to use and select a default one:
```sh
gcloud compute project-info add-metadata \
    --metadata google-compute-default-region=europe-west1 google-compute-default-zone=europe-west1-b
gcloud config set compute/zone europe-west1-b
```
You can configure you ssh access:
``` sh
gcloud compute config-ssh
```

# Git
In case you want to access and contribute:
* [https://github.com/orichaud/gce.git](https://github.com/orichaud/gce.git)


# Creation of the GKE cluster
To deploy the cluster and perform operatiosn on the clusters, you will call the predefined script `gke_admin.sh`. It will assume the `default` zone has been defined. Otherwise it will will request the selection of a zone:
``` sh
./gke_admin.sh --create-cluster
```
The result is the creation of a GKE cluster belonging to your default project as defined previously. To delete your cluster:
``` sh
./gke_admin.sh --delete-cluster
```
# Building and deploying the docker image
You can go to the second set which is the full depployment of a simple GO program incrementing a counter. 
You must first compile. The script will build for MacOS and for Linux. The Linux version will be used to create the Docker image:
```sh 
make build
```
You can build the docker image and push the image to the Google Container Respository. This is the latest version of the image that will be picked up by Kubernetes to schedule the deployment of your POD. The base image is based on the latest Golang image:
```sh
make docker
```
# Deployment on the GKE cluster
Once the image is available in GCR, you can go to the next step, and start the effective deployment of your cluster. 2 options are available:
* First option is with descriptors (see YMAL files defining the various objects). This will first create a deployment object, asssociate an autoscaler, a POD disruption budget and finally create a Load Balancer directly accessilble on the public Internet.
```sh
./gke_admin.sh --deploy
```
Then to dismantle:
```sh
./gke_admin.sh --undeploy
```
* Second option is with CLI options. This will first create a deployment, scale the number of replicas, asssociate an autoscaler and finally create a Load Balancer directly accessilble on the public Internet. No POD Disruption Budget is defined.
 ```sh
./gke_admin.sh --deploy-CLI
```
Then to dismantle:
```sh
./gke_admin.sh --undeploy-CLI
```
The CLI options are limited. The YAML offers much more possibilities to configure the Kubernetes objects.

# Testing
You can check the service with `kubectl get services`. Your service is available for external traffic once the EXTRNAL-IP is defined and not marked as pending:
```sh
NAME              TYPE           CLUSTER-IP      EXTERNAL-IP     PORT(S)          AGE
counter-service   LoadBalancer   10.27.241.241   35.233.100.85   8080:30000/TCP   1m
kubernetes        ClusterIP      10.27.240.1     <none>          443/TCP          8h
```
The script will not check the availability of the EXTERNAL-IP.
You can run the test:
```sh
./gke_admin.sh --test
```
whose output is:
```sh
+ test: invoking service
URL: http://http://35.233.100.85:8080/
{"Status":"OK","Response":"counter-deployment-86699789d4-wq8hb - counter=1"}# done
```