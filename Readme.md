# Google Cloud Account
We assume you have installed [gcloud]( https://cloud.google.com/sdk/) and [kubectl]( https://kubernetes.io/docs/tasks/tools/install-kubectl/).

To initialize the environemnt and connect to your google account, you will run the following commands. It assumes you have a GCP account and that you have defined default project, your region/zone (you can refer to this [page](https://cloud.google.com/kubernetes-engine/docs/quickstart)):
```sh
gcloud config set project myProject
# e.g.: europe-west1-b can be a zone, see the list of zones defined by GCP
gcloud config set compute/zone myzone 
```


``` sh
gcloud init
gcloud auth login
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

Remark: the `gke_admin.sh` will assume the `default` zone has been created. Otherwise it will will request the selection of the zone.

# Git
In case you want to access and contribute:
* [https://github.com/orichaud/gce.git](https://github.com/orichaud/gce.git)


# Initialization of the GKE cluster
To deploy the cluster, you will call the predefined script:
``` sh
./gke_admin.sh --create-cluster
```
The result is the creation of a GKE cluster belonging to your default project as defined previously. To delete your cluster:
``` sh
./gke_admin.sh --delete-cluster
```


Then you can go to the second set which is the full depployment of a simple GO program incrementing a counter. 
You must first compile: 
```sh 
make build
```
And then you can build the docker image and push the image to the Google Container Respository. 
```sh
make docker
```
Once the image is available in GCR, you can go to the next step, and start the effective deploymenf of your cluster. 2 options are available:
* First option is with descriptors. This will first create a deployment, asssociate an autoscaler and a POD disruption budget and finally create a Load Balancer directly accessilble on the public Internet.
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
