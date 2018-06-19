#!/bin/sh

PROJECT=mp-box-dev
CLUSTER=or-cluster
NS=orns

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
        --machine-type=n1-standard-1 \
        --tags=or-cluster \
        --enable-autorepair --enable-autoupgrade

    kubectl create namespace $NS

    echo "+ create: finished"
    ;;
    
    --delete-cluster)
    echo "+ delete: delete cluster $CLUSTER"
    shift
    kubectl delete namespace $NS
    gcloud container clusters delete $CLUSTER << CONFIRM
    Y
    Y
CONFIRM

    echo "+ delete: finished"
    ;;

    --deploy)
    echo "+ deploy: deploy with descriptors into cluster $CLUSTER"
    shift
   
    kubectl create -f counter-deployment.yaml --namespace=$NS
    kubectl create -f counter-hpa.yaml --namespace=$NS  
    kubectl create -f counter-pdb.yaml --namespace=$NS
    kubectl create -f counter-service.yaml --namespace=$NS
    
    echo "+ deploy: finished"
    ;;

    --undeploy)
    echo "+ undeploy: undeploy with descriptors from cluster $CLUSTER"
    shift

    kubectl delete -f counter-service.yaml --namespace=$NS
    kubectl delete -f counter-deployment.yaml --namespace=$NS
    kubectl delete -f counter-hpa.yaml --namespace=$NS
    kubectl delete -f counter-pdb.yaml --namespace=$NS
    kubectl create delete $NS
    
    echo "+ undeploy: finished"
    ;;

     --deploy-CLI)
    echo "+ deploy: deploy with CLI into cluster $CLUSTER"
    shift

    OPTS=

    kubectl create deployment counter-deployment $OPTS --image eu.gcr.io/$PROJECT/hserver --namespace=$NS
    kubectl scale deployment counter-deployment $OPTS --replicas=3 --namespace=$NS
    kubectl autoscale deployment counter-deployment $OPTS--min=3 --max=10 --namespace=$NS
    kubectl expose deployment counter-deployment $OPTS --name counter-service --type "LoadBalancer"  --port=8080 --target-port=8080 --namespace=$NS
    kubectl label deployments counter-deployment $OPTS app=counter version=v2 --overwrite --namespace=$NS
    kubectl label hpa counter-deployment $OPTS app=counter version=v2 --overwrite --namespace=$NS
    kubectl label services counter-service $OPTS app=counter version=v2 --overwrite --namespace=$NS
    
    echo "+ deploy: finished"
    ;;

    --undeploy-CLI)
    echo "+ undeploy: undeploy with CLI fom cluster $CLUSTER"
    shift

    kubectl delete deployments,pods,services,hpa -l app=counter,version=v2 --namespace=$NS

    echo "+ undeploy: finished"
    ;;

    --test)
    echo "+ test: invoking service"
    shift
    
    ip=`kubectl get service counter-service -o=jsonpath='{.status.loadBalancer.ingress[0].ip}'  --namespace=$NS`
    port=`kubectl get service counter-service -o=jsonpath='{.spec.ports[0].port}' --namespace=$NS`

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