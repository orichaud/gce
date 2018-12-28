#!/bin/sh

PROJECT=mp-box-dev
CLUSTER=or-cluster
NETWORK=or-net
NS=orns

OPTS=--namespace=$NS

COUNT=5

CLUSTER_USERNAME=admin
CLUSTER_PASSWORD=admin1234adminfsdfoisfou

DESCRIPTORS=./descriptors

POSITIONAL=()
while [[ $# -gt 0 ]]
do
key="$1"

case $key in
    --create-cluster)
    echo "+ create: start cluster $CLUSTER and initialize network and storage"
    shift

    gcloud compute networks create $NETWORK

    gcloud container clusters create $CLUSTER \
        --preemptible \
        --num-nodes=3 --enable-autoscaling --min-nodes=3 --max-nodes=10 \
        --machine-type=n1-standard-1 \
        --tags=$CLUSTER \
        --enable-cloud-logging --enable-cloud-monitoring  \
        --enable-autorepair --enable-autoupgrade \
        --enable-network-policy \
        --enable-ip-alias \
        --issue-client-certificate \
        --no-enable-legacy-authorization \
        --network=$NETWORK \
        --username=$CLUSTER_USERNAME \
        --password=$CLUSTER_PASSWORD

    kubectl create namespace $NS

    kubectl apply -f $DESCRIPTORS/denyall-netpolicy.yaml $OPTS
    kubectl apply -f $DESCRIPTORS/egress-networkpolicy.yaml $OPTS

    kubectl apply -f $DESCRIPTORS/redis-sa.yaml $OPTS
    kubectl apply -f $DESCRIPTORS/redis-storageclass.yaml $OPTS
    kubectl apply -f $DESCRIPTORS/redis-pvc.yaml $OPTS
    kubectl apply -f $DESCRIPTORS/redis-netpolicy.yaml $OPTS

    kubectl apply -f $DESCRIPTORS/counter-sa.yaml $OPTS
    kubectl apply -f $DESCRIPTORS/counter-hpa.yaml $OPTS 
    kubectl apply -f $DESCRIPTORS/counter-pdb.yaml $OPTS
    kubectl apply -f $DESCRIPTORS/counter-netpolicy.yaml $OPTS

    kubectl create -f counter-operator/deploy/service_account.yaml

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
    gcloud compute networks delete or-net << CONFIRM
    Y
CONFIRM

    echo "+ delete: finished"
    ;;

    --deploy)
    echo "+ deploy: deploy with descriptors into cluster $CLUSTER"
    shift

    kubectl apply -f $DESCRIPTORS/redis-deployment.yaml $OPTS
    kubectl apply -f $DESCRIPTORS/redis-service.yaml $OPTS

    kubectl apply -f $DESCRIPTORS/counter-deployment.yaml $OPTS
    kubectl apply -f $DESCRIPTORS/counter-service.yaml $OPTS

    echo "+ deploy: finished"
    ;;

    --undeploy)
    echo "+ undeploy: undeploy with descriptors from cluster $CLUSTER"
    shift
    kubectl delete -f $DESCRIPTORS/counter-test.yaml $OPTS
    kubectl delete -f $DESCRIPTORS/counter-redis-test.yaml $OPTS

    kubectl delete -f $DESCRIPTORS/counter-service.yaml $OPTS
    kubectl delete -f $DESCRIPTORS/counter-deployment.yaml $OPTS

    kubectl delete -f $DESCRIPTORS/redis-deployment.yaml $OPTS
    kubectl delete -f $DESCRIPTORS/redis-service.yaml $OPTS

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

    url="http://$ip:$port/redis"
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
    kubectl delete deployment counter-test $OPTS
    echo "+ delete test internal: finished"
    ;;

    --start-test-internal)
    echo "+ start test internal"
    shift
    kubectl create -f ./descriptors/counter-test.yaml $OPTS
    sleep 5
    kubectl logs -l name=counter-test $OPTS
    ;;

    --start-operator)
    echo "+ start local operator"
    shift

    cd counter-operator
    kubectl apply -f deploy/crds/counter_v1alpha1_counterservice_crd.yaml $OPTS
    kubectl apply -f deploy/crds/counter_v1alpha1_counterservice_cr.yaml $OPTS
    operator-sdk up local $OPTS
    cd -

    ;;

    *)    # unknown option
    POSITIONAL+=("$1") # save it in an array for later
    echo "- unknown option: failing"
    shift 
    ;;
esac
done

echo "# done"