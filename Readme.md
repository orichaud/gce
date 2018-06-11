# Google Cloud Account

To initiliaze the environemnt and connect to your google account, you will run the following commands. It assumes you a vec a GCP account and that you have adefualt project. 
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
The result is the creation of a GKE cluster belonging to your default project as defined previously.
Then you can go to the second set which is the full depployment of a simple GO program incrementing a counter. 
You must first compile: 
```sh 
make build
```
And then you can build the docker image and push the image to the Google Container Respository. 
```sh
make docker
```
Once the image is available in GCR, you can go to the next step, and start the effective deploymenf of your cluster. I have create to options:
* First option is with descriptors. This will first create a deployment, asssociate an autoscaler and a POD disruption budget and finally create a Load Balancer directly accessilble on the public Internet.
```sh
./gke_admin.sh --deploy
```
* Second option is with CLI options. This will first create a deployment, scale the number of replicas, asssociate an autoscaler and finally create a Load Balancer directly accessilble on the public Internet. No POD Disruption Budget is defined.
 ```sh
./gke_admin.sh --deploy-CLI
```
The CLI options are limited. The YAML offers much more possibilities to configure the Kubernetes objects. 