#!/bin/bash


# Source
http://jeffmendoza.github.io/kubernetes/v1.0/examples/cassandra/README.html
https://robertbrem.github.io/Microservices_with_Kubernetes/17_Event_Sourcing_with_Cassandra/01_Setup_Cassandra/

https://docs.portworx.com/scheduler/kubernetes/cassandra-k8s.html
https://www.ibm.com/developerworks/library/ba-multi-data-center-cassandra-cluster-kubernetes-platform/index.html

https://kubernetes.io/docs/tutorials/stateful-application/cassandra/
https://kubernetes.io/docs/concepts/storage/persistent-volumes/#persistent-volumes
https://cloud.google.com/kubernetes-engine/docs/concepts/persistent-volumes

# Login
USER_PASS='AAasdf5asdf5' # 12 char
sshpass -p $USER_PASS ssh greg@104.40.128.197

# Become root
sudo -i
mkdir cassandra
cd cassandra

# create persistent volume
cat <<EOF >persistentVolume.yaml
kind: PersistentVolume
apiVersion: v1
metadata:
  name: pv-00
  labels:
    type: local
spec:
  storageClassName: manual
  capacity:
    storage: 10Gi
  accessModes:
    - ReadWriteOnce
  hostPath:
    path: "/mnt/data"
EOF

kubectl create -f persistentVolume.yaml
kubectl get pv task-pv-volume
kubectl delete pv task-pv-volume


###IBM###

# source
https://github.com/IBM/Scalable-Cassandra-deployment-on-Kubernetes

# cassandra service yaml
cat <<EOF >cassandra-service.yaml
---
apiVersion: v1
kind: Service
metadata:
  labels:
    app: cassandra
  name: cassandra
spec:
  clusterIP: None
  ports:
    - port: 9042
  selector:
    app: cassandra
EOF

kubectl get svc cassandra


# persistent volumes yaml
cat <<EOF >local-volumes.yaml
---
apiVersion: v1
kind: PersistentVolume
metadata:
  name: cassandra-data-1
  labels:
    type: local
    app: cassandra
spec:
  capacity:
    storage: 1Gi
  accessModes:
    - ReadWriteOnce
  hostPath:
    path: /tmp/data/cassandra-data-1
  persistentVolumeReclaimPolicy: Recycle
---
apiVersion: v1
kind: PersistentVolume
metadata:
  name: cassandra-data-2
  labels:
    type: local
    app: cassandra
spec:
  capacity:
    storage: 1Gi
  accessModes:
    - ReadWriteOnce
  hostPath:
    path: /tmp/data/cassandra-data-2
  persistentVolumeReclaimPolicy: Recycle
---
apiVersion: v1
kind: PersistentVolume
metadata:
  name: cassandra-data-3
  labels:
    type: local
    app: cassandra
spec:
  capacity:
    storage: 1Gi
  accessModes:
    - ReadWriteOnce
  hostPath:
    path: /tmp/data/cassandra-data-3
  persistentVolumeReclaimPolicy: Recycle
EOF

kubeclt create -f local-volumes


# stateful service yaml
cat <<EOF >cassandra-statefulset.yaml
---
apiVersion: "apps/v1beta1"
kind: StatefulSet
metadata:
  name: cassandra
spec:
  serviceName: cassandra
  replicas: 1
  template:
    metadata:
      labels:
        app: cassandra
    spec:
      containers:
        - name: cassandra
          image: cassandra:3.11
          imagePullPolicy: IfNotPresent
          ports:
            - containerPort: 7000
              name: intra-node
            - containerPort: 7001
              name: tls-intra-node
            - containerPort: 7199
              name: jmx
            - containerPort: 9042
              name: cql
          env:
            - name: CASSANDRA_SEEDS
              value: cassandra-0.cassandra.default.svc.cluster.local
            - name: MAX_HEAP_SIZE
              value: 256M
            - name: HEAP_NEWSIZE
              value: 100M
            - name: CASSANDRA_CLUSTER_NAME
              value: "Cassandra"
            - name: CASSANDRA_DC
              value: "DC1"
            - name: CASSANDRA_RACK
              value: "Rack1"
            - name: CASSANDRA_ENDPOINT_SNITCH
              value: GossipingPropertyFileSnitch
          volumeMounts:
            - name: cassandra-data
              mountPath: /var/lib/cassandra/data
  volumeClaimTemplates:
    - metadata:
        name: cassandra-data
        annotations:  # comment line if you want to use a StorageClass
          # or specify which StorageClass
          volume.beta.kubernetes.io/storage-class: ""   # comment line if you
          # want to use a StorageClass or specify which StorageClass
      spec:
        accessModes: ["ReadWriteOnce"]
        resources:
          requests:
            storage: 1Gi
EOF

k delete sts cassandra
k create -f cassandra-statefulset.yaml

# check status
kubectl get statefulsets
kubectl get pods -o wide
kubectl exec -ti cassandra-0 -- nodetool status

# scaling
kubectl scale --replicas=3 statefulset/cassandra
kubectl get statefulsets

# kubectl exec cqlsh
kubectl exec -ti cassandra-0 -- nodetool status
kubectl exec -it cassandra-0 cqlsh


### IBM ###


# Create service
cat <<EOF > cassandra.yaml
apiVersion: v1
kind: Service
metadata:
  labels:
    name: cassandra
  name: cassandra
spec:
  ports:
    - port: 9042
  selector:
    name: cassandra" > cassandra-service.yaml
kubectl create -f cassandra-service.yaml
kubectl get services

# Create cassandra pod
echo -e "apiVersion: v1
kind: Pod
metadata:
  labels:
    name: cassandra
  name: cassandra
spec:
  containers:
  - args:
    - /run.sh
    resources:
      limits:
        cpu: "0.5"
    image: gcr.io/google_containers/cassandra:v5
    name: cassandra
    ports:
    - name: cql
      containerPort: 9042
    - name: thrift
      containerPort: 9160
    volumeMounts:
    - name: data
      mountPath: /cassandra_data
    env:
    - name: MAX_HEAP_SIZE
      value: 512M
    - name: HEAP_NEWSIZE
      value: 100M
    - name: POD_NAMESPACE
      valueFrom:
        fieldRef:
          fieldPath: metadata.namespace
  volumes:
    - name: data
      emptyDir: {}
EOF

kubectl create -f cassandra.yaml
kubectl get pods cassandra

# Replication controller
cat <<EOF > cassandra-controller.yaml
apiVersion: v1
kind: ReplicationController
metadata:
  labels:
    name: cassandra
  name: cassandra
spec:
  replicas: 1
  selector:
    name: cassandra
  template:
    metadata:
      labels:
        name: cassandra
    spec:
      containers:
        - command:
            - /run.sh
          resources:
            limits:
              cpu: 0.5
          env:
            - name: MAX_HEAP_SIZE
              value: 512M
            - name: HEAP_NEWSIZE
              value: 100M
            - name: POD_NAMESPACE
              valueFrom:
                fieldRef:
                  fieldPath: metadata.namespace
          image: gcr.io/google_containers/cassandra:v5
          name: cassandra
          ports:
            - containerPort: 9042
              name: cql
            - containerPort: 9160
              name: thrift
          volumeMounts:
            - mountPath: /cassandra_data
              name: data
      volumes:
        - name: data
          emptyDir: {}
EOF

kubectl create -f cassandra-controller.yaml
kubectl get pods cassandra

# Scale number of containers up
kubectl scale rc cassandra --replicas=4
kubectl get pods -l="name=cassandra"

# Use Cassandra nodetool
kubectl exec -ti cassandra -- nodetool status


# Access Cassandra CQL cqlsh
kubectl exec -it cassandra cqlsh cassandra



kubectl run kubia --image=luksa/kubia --port=8080 --generator=run/v1
kubectl expose rc kubia --type=LoadBalancer --name kubia-http


kubectl run kubia --image=luksa/kubia --port=8080 --generator=run/v1
replicationcontroller "kubia" created
kubectl expose rc kubia --type=LoadBalancer --name kubia-http
service "kubia-http" exposed