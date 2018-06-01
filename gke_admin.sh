#!/bin/sh

CLUSTER=or-cluster

POSITIONAL=()
while [[ $# -gt 0 ]]
do
key="$1"

case $key in
    --create-cluster)
    echo "+ create: start cluster $CLUSTER"
    shift

    gcloud container clusters create $CLUSTER \
        --preemptible \
        --num-nodes=5 --enable-autoscaling --min-nodes=3 --max-nodes=10 \
        --tags=or-cluster \
        --enable-autorepair --enable-autoupgrade

    echo "+ create: finished"
    ;;
    
    --delete-cluster)
    echo "+ delete: delete cluster $CLUSTER"
    shift

    gcloud container clusters delete $CLUSTER << CONFIRM
    Y
    Y
CONFIRM

    echo "+ delete: finished"
    ;;

    --deploy)
    echo "+ deploy: deploy into cluster $CLUSTER"
    shift

    kubectl run hello-server --image gcr.io/google-samples/hello-app:1.0 --port 8080
    kubectl expose deployment hello-server --type "LoadBalancer"
    kubectl get service hello-server

    echo "+ deploy: finished"
    ;;

    --undeploy)
    echo "+ undeploy: undeploy into cluster $CLUSTER"
    shift

    kubectl delete deployment hello-server

    echo "+ undeploy: finished"
    ;;

    --test)
    echo "+ test: invoking hello-server service"
    shift
    
    ip=`kubectl get service hello-server -o=jsonpath='{.status.loadBalancer.ingress[0].ip}'`
    port=`kubectl get service hello-server -o=jsonpath='{.spec.ports[0].port}'`
    
    url="http://$ip:$port"
    echo "+ invoking $url"

    curl $url
    ;;

    *)    # unknown option
    POSITIONAL+=("$1") # save it in an array for later
    echo "- unknow noption: failing"
    shift 
    ;;
esac
done

echo "# done"