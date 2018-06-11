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
    echo "+ deploy: deploy with descriptors into cluster $CLUSTER"
    shift

    kubectl create -f counter-deployment.yaml
    kubectl create -f counter-hpa.yaml  
    kubectl create -f counter-pdb.yaml 
    kubectl create -f counter-service.yaml 
    
    echo "+ deploy: finished"
    ;;

    --undeploy)
    echo "+ undeploy: undeploy with descriptors from cluster $CLUSTER"
    shift

    kubectl delete -f counter-service.yaml 
    kubectl delete -f counter-deployment.yaml
    kubectl delete -f counter-hpa.yaml  
    kubectl delete -f counter-pdb.yaml 
    
    echo "+ undeploy: finished"
    ;;

     --deploy-CLI)
    echo "+ deploy: deploy with CLI into cluster $CLUSTER"
    shift

    kubectl create deployment counter-deployment --image gcr.io/google-samples/hserver --port 8080
    kubectl scale deployment counter-deployment --replicas=3
    kubectl autoscale deployment counter-deployment --min=3 --max=10
    kubectl expose deployment counter-deployment --type "LoadBalancer"  --port=8080 --target-port=8080

    echo "+ deploy: finished"
    ;;

    --undeploy-CLI)
    echo "+ undeploy: undeploy with CLI fom cluster $CLUSTER"
    shift

    kubectl delete deployment counter
    kubectl delete service counter
    kubectl delete hpacounter
    
    echo "+ undeploy: finished"
    ;;

    --test)
    echo "+ test: invoking service"
    shift
    
    ip=`kubectl get service counter-service -o=jsonpath='{.status.loadBalancer.ingress[0].ip}'`
    port=`kubectl get service counter-service -o=jsonpath='{.spec.ports[0].port}'`

    url=http://$ip:$port
    echo "URL: http://$url/"
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