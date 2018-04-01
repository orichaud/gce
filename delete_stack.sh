#!/bin/sh

GROUP_NAME=or-grp
TEMPLATE_NAME=or-tpl

gcloud compute instance-groups managed delete $GROUP_NAME
gcloud compute instance-templates delete $TEMPLATE_NAME

echo "Stack deleted"
