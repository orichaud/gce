#!/bin/sh

MACHINE_TYPE=n1-standard-1
IMAGE_TYPE=centos-7
INSTANCE_NAME=or
GROUP_NAME=or-grp
TEMPLATE_NAME=or-tpl
SIZE=3

gcloud compute instance-templates create $TEMPLATE_NAME \
    --machine-type $MACHINE_TYPE \
    --image $IMAGE_TYPE \
    --boot-disk-size 10GB \
    --preemptible


gcloud compute instance-groups managed create $GROUP_NAME \
      --base-instance-name $INSTANCE_NAME \
      --size $SIZE \
      --template $TEMPLATE_NAME

echo "Stack created"
