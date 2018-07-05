#!/bin/sh

PROJECT=mp-box-dev
CLUSTER=or-cluster
NS=orns

OPTS=--namespace=$NS

COUNT=5


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
        --num-nodes=3 --enable-autoscaling --min-nodes=3 --max-nodes=10 \
        --machine-type=n1-standard-1 \
        --tags=or-cluster \
        --enable-cloud-logging --enable-cloud-monitoring  \
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
   
    kubectl apply -f counter-deployment.yaml $OPTS
    kubectl apply -f counter-hpa.yaml $OPTS 
    kubectl apply -f counter-pdb.yaml $OPTS
    kubectl apply -f counter-service.yaml $OPTS
    kubectl apply -f counter-netpolicy.yaml $OPTS
    echo "+ deploy: finished"
    ;;

    --undeploy)
    echo "+ undeploy: undeploy with descriptors from cluster $CLUSTER"
    shift

    kubectl delete -f counter-service.yaml $OPTS
    kubectl delete -f counter-deployment.yaml $OPTS
    kubectl delete -f counter-hpa.yaml $OPTS
    kubectl delete -f counter-pdb.yaml $
    kubectl delete -f counter-test.yaml $OPTS
    echo "+ undeploy: finished"
    ;;

     --deploy-CLI)
    echo "+ deploy: deploy with CLI into cluster $CLUSTER"
    shift

    OPTS=

    kubectl create deployment counter-deployment --image eu.gcr.io/$PROJECT/hserver:latest $OPTS
    kubectl scale deployment counter-deployment --replicas=3 $OPTS
    kubectl autoscale deployment counter-deployment --min=3 --max=10 $OPTS
    kubectl expose deployment counter-deployment --name counter-service --type "LoadBalancer"  --port=8080 --target-port=8080 $OPTS
    kubectl label deployments counter-deployment app=counter env=test --overwrite $OPTS
    kubectl label hpa counter-deployment app=counter env=test --overwrite $OPTS
    kubectl label services counter-service app=counter env=test --overwrite $OPTS
    
    echo "+ deploy: finished"
    ;;

    --undeploy-CLI)
    echo "+ undeploy: undeploy with CLI fom cluster $CLUSTER"
    shift

    kubectl delete deployments,pods,services,hpa -l app=counter,env=test $OPTS

    echo "+ undeploy: finished"
    ;;

    --test)
    echo "+ test: invoking service"
    shift
    
    ip=""
    port=""
    while [[ -z $ip || -z $port ]]
    do
        ip=`kubectl get service counter-service -o=jsonpath='{.status.loadBalancer.ingress[0].ip}' $OPTS`
        port=`kubectl get service counter-service -o=jsonpath='{.spec.ports[0].port}' $OPTS`

        sleep 1
    done
    url="http://$ip:$port/counter"
    echo "URL:      $url"

    for ((i=0; i<$COUNT;i++))
    do
        response=$(curl -XGET -sb -H 'Accept: application/json' $url)
        echo "Response: $response"
    done
    echo "+ test: finished"
    ;;

    --stop-test-internal)
    echo "+ delete test internal"
    shift
    kubectl delete pods/counter-test $OPTS
    echo "+ delete test internal: finished"
    ;;

    --start-test-internal)
    echo "+ start test internal"
    shift
    kubectl create -f ./counter-test.yaml $OPTS
    sleep 5
    kubectl logs -f counter-test -c test $OPTS
    ;;

    *)    # unknown option
    POSITIONAL+=("$1") # save it in an array for later
    echo "- unknown option: failing"
    shift 
    ;;
esac
done

echo "# done"