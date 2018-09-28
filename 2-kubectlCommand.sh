####################
# kubectl commands #
####################

kubectl describe pods

# Reading
kubectl get services

# Pausing
kubectl scale deployment XXX --replicas=0

# Delete deployment
kubectl delete deployment XXX

# Delete service
kubectl delete service XXX


# Print info

# anzeige der aktiven pods, services, deployments, ...
kubectl get deployments,services,pods --all-namespaces

# bzw. mit " -o wide" für weiter info's
kubectl get deployments,services,pods --all-namespaces -o wide

# nur von bestimmten namespace
kubectl get deployments,services,pods -n $namspace

# deployments/services/pods kann auch alleine oder in beliebiger kombination verwendet werden

# ausgabe kann man auch speziell zusammenstellen - hier ein paar beispiele (details hat dr. google ;-) )
kubectl get daemonsets --all-namespaces -o jsonpath="{range .items[*]}[{.metadata.name}, {..image}, {.spec.replicas}] {end}"
kubectl get deployment -n nqual -o jsonpath="{range .items[*]}[{.metadata.name}, {..image}, {.spec.replicas}] {end}"
kubectl get pods -n kube-system -o jsonpath="{range .items[*]}[{.metadata.name}, {..image}, {.spec.replicas}] {end}"

# detail info's zum pod anzeigen
kubectl describe pod $podName -n $namespace


# neue pods, services, deployments, ... erstellen und anpassen

# deployment (pods/services/...) via yaml-file
kubectl apply -f $file.yaml -n $namespace

# anzahl der pods anpassen
kubectl scale deployment $deploymentname --replicas=$anzahl -n $namespace

# service editieren
kubectl edit service $servicename -n $namespace

# löschen
kubectl delete pod $podName -n $namespace

# löschen mit selector
kubectl -n $STAGE delete pod --selector=app=$DEPLOYMENT

# löschen erzwingen - wenn der Pod zB auf Terminating bleibt
kubectl -n $STAGE delete pod $podName --grace-period=0 --force

# in pod einsteigen - muss nicht immer /bin/bash sein! VAL teilweise /bin/sh
kubectl exec -ti $POD-NAME /bin/bash -n $STAGE


# maintenance

# node wartungsmode enable - alle pods werden auf andere cld-server verschoben

# eigentlich nur bei den sbecld* notwendig
kubectl drain $node-fqdn --ignore-daemonsets  --delete-local-data

# deployment status anzeigen
kubectl rollout status deployment/$DEPLOYMENT -n $STAGE

# deployments auf node disablen
kubectl cordon $node-fqdn

# node wieder enablen
kubectl uncordon $node-fqdn


# neuen namespace erstellen - muss nur 1x pro namespace/stagename ausgeführt werden
kubectl create namespace $stage
kubectl create secret docker-registry ts-nexus --docker-server=docker-ts-release.ts-$env.oebb.at:443 --docker-username=$repo-user --docker-password=$password --docker-email=oebbticketshop-support-ikt@oebb.at -n $namespace
kubectl get secret -n $namespace

