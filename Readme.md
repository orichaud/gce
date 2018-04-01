# GCE Account

Initialized with `default` and `orichaud@gmail.com`. Source hosting not selected. Command to initialize the cloud:
``` sh
gcloud init
gcloud auth login

gcloud compute project-info add-metadata \
    --metadata google-compute-default-region=europe-west1,google-compute-default-zone=europe-west1-b

gcloud config set compute/zone europe-west1-b

gcloud compute config-ssh
```

Remark: the `create_stack.sh` will assume the `default` zone has been created. Otherwise it will will request the selection of the zone.

# Git
* [https://github.com/orichaud/gce.git](https://github.com/orichaud/gce.git)

``` sh
git init
git add .
git commit -m "initialization"
git remote add origin https://github.com/orichaud/gce.git
git remote -v
git push origin master
```

# Creating a VM formation

``` sh
./create_stack.sh
```
