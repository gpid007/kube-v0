#!/bin/bash

# source
https://github.com/NetAppEMEA/kubernetes-netapp/tree/master/spark-s3
https://github.com/eBay/Kubernetes/tree/master/examples/spark
https://github.com/eBay/Kubernetes/tree/master/docs/getting-started-guides#on-premises-vms

# explanation
http://www.noqcks.io/notes/2018/02/03/understanding-kubernetes-resources/

# global setup
SPARK_DIR='/root/spark/'
cd $SPARK_DIR


# replication controller
cat <<EOF >spark-master-controller.yaml
kind: ReplicationController
apiVersion: v1
metadata:
  name: spark-master-controller
spec:
  replicas: 1
  selector:
    component: spark-master
  template:
    metadata:
      labels:
        component: spark-master
    spec:
      containers:
        - name: spark-master
          image: gcr.io/google_containers/spark-master:1.5.1_v2
          ports:
            - containerPort: 7077
            - containerPort: 8080
          resources:
            requests:
              cpu: 100m
EOF

kubectl create -f spark-master-controller.yaml


# stateless service
cat <<EOF >spark-master-service.yaml
kind: Service
apiVersion: v1
metadata:
  name: spark-master
spec:
  ports:
    - port: 7077
      targetPort: 7077
  selector:
    component: spark-master
EOF

kubectl create -f spark-master-service.yaml

# check state
kubectl get pods
kubectl logs spark-master-controller-wcv8d
kubectl exec spark-master-controller-wcv8d -it spark-shell


# declare workers cpu: 100m = 100 milli cores = 10% per CPU
cat <<EOF >spark-worker-controller.yaml
kind: ReplicationController
apiVersion: v1
metadata:
  name: spark-worker-controller
spec:
  replicas: 3
  selector:
    component: spark-worker
  template:
    metadata:
      labels:
        component: spark-worker
    spec:
      containers:
        - name: spark-worker
          image: gcr.io/google_containers/spark-worker:1.5.1_v2
          ports:
            - containerPort: 8081
          resources:
            requests:
              cpu: 100m
EOF

kubectl create -f spark-worker-controller.yaml



# add cassandra driver
# https://stackoverflow.com/questions/25837436/how-to-load-spark-cassandra-connector-in-the-shell
k get pods # check names
kubectl exec -it spark-worker-controller-44xsx -- bash

cd /opt/spark/lib
wget http://dl.bintray.com/spark-packages/maven/datastax/spark-cassandra-connector/2.3.1-s_2.11/spark-cassandra-connector-2.3.1-s_2.11.jar


# execute spark service
kubectl exec spark-master-controller-j6x9n -it -- spark-shell --jars ~/spark-cassandra-connector/spark-cassandra-connector/target/scala-2.10/connector-assembly-1.2.0-SNAPSHOT.jar


git clone https://github.com/datastax/spark-cassandra-connector.git
cd spark-cassandra-connector
sbt/sbt assembly
$SPARK_HOME/bin/spark-shell --jars ~/spark-cassandra-connector/spark-cassandra-connector/target/scala-2.10/connector-assembly-1.2.0-SNAPSHOT.jar


val data = sc.cassandraTable("ks_one", "t_one");

sc.stop
import com.datastax.spark.connector._
import org.apache.spark.SparkContext
import org.apache.spark.SparkContext._
import org.apache.spark.SparkConf
val conf = new SparkConf(true).set("spark.cassandra.connection.host", "my cassandra host")
val sc = new SparkContext("spark://spark host:7077", "test", conf)



# spark webui
cat <<EOF >spark-webui.yaml
kind: Service
apiVersion: v1
metadata:
  name: spark-webui
spec:
  ports:
    - port: 8080
      targetPort: 8080
  selector:
    component: spark-master
EOF

kubectl create -f spark-webui.yaml



# zeppelin controller
cat <<EOF >zeppelin-controller.yaml
kind: ReplicationController
apiVersion: v1
metadata:
  name: zeppelin-controller
spec:
  replicas: 1
  selector:
    component: zeppelin
  template:
    metadata:
      labels:
        component: zeppelin
    spec:
      containers:
        - name: zeppelin
          image: gcr.io/google_containers/zeppelin:v0.5.5_v2
          ports:
            - containerPort: 8080
          resources:
            requests:
              cpu: 100m
EOF

kubectl create -f zeppelin-controller.yaml
kubectl get pods -lcomponent=zeppelin


# zeppelin service
cat <<EOF >zeppelin-service.yaml
kind: Service
apiVersion: v1
metadata:
  name: zeppelin
spec:
  ports:
    - port: 8080
      targetPort: 8080
  selector:
    component: zeppelin
EOF

kubectl create -f zeppelin-service.yaml
kubectl get service zeppelin

# enable ui
kubectl port-forward zeppelin-controller-mphbs 8080:8080





# Apache spark
mkdir $SPARK_DIR
cd $SPARK_DIR
wget http://mirror.klaus-uwe.me/apache/spark/spark-2.3.1/spark-2.3.1-bin-hadoop2.7.tgz
tar -xvzf spark*

# Cassandra driver
cd $SPARK_DIR/spark*/jars
wget http://dl.bintray.com/spark-packages/maven/datastax/spark-cassandra-connector/2.3.1-s_2.11/spark-cassandra-connector-2.3.1-s_2.11.jar

# Docker build spark
cd /root/spark/spark-2.3.1-bin-hadoop2.7
docker build -t gpid007/spark-cassandra -f kubernetes/dockerfiles/spark/Dockerfile .

docker login --username gpid007 --password ASDF%asdf5
docker push gpid007/spark-cassandra






# download and setup spark
mkdir $SPARK_DIR
wget http://mirror.klaus-uwe.me/apache/spark/spark-2.3.1/spark-2.3.1-bin-hadoop2.7.tgz
tar -xvzf spark*

# build docker image and replace gpid007 with your own dockerID (registration required)
docker login
cd $SPARK_DIR/spark*
docker build -t gpid007/spark -f kubernetes/dockerfiles/spark/Dockerfile .
docker push gpid007/spark

kubectl cluster-info


bin/spark-submit \
    --master k8s://https://10.0.0.5:6443 \
    --deploy-mode cluster \
    --name spark-pi \
    --class org.apache.spark.examples.SparkPi \
    --conf spark.executor.instances=5 \
    --conf spark.kubernetes.container.image= gpid007/spark\
    local:///path/to/examples.jar



cd ~/spark-2.3.0-bin-hadoop2.7
bin/spark-submit \
    --master k8s://test-cluster.eastus2.cloudapp.azure.com:443 \
    --deploy-mode cluster \
    --name copyLocations \
    --class io.timpark.CopyData \
    --conf spark.kubernetes.authenticate.driver.serviceAccountName=spark \
    --conf spark.copydata.containerpath=wasb://CONTAINERS@STORAGE_ACCOUNT.blob.core.windows.net \
    --conf spark.copydata.storageaccount=STORAGE_ACCOUNT \
    --conf spark.copydata.storageaccountkey=STORAGE_ACCOUNT_KEY \
    --conf spark.copydata.frompath=wasb://CONTAINER1@STORAGE_ACCOUNT.blob.core.windows.net/PATH1 \
    --conf spark.copydata.topath=wasb://CONTAINER2@locationdata.blob.core.windows.net/PATH2 \
    --conf spark.executor.instances=16 \
    --conf spark.kubernetes.container.image=timfpark/copy-data:latest \
    --jars http://central.maven.org/maven2/org/apache/hadoop/hadoop-azure/2.7.2/hadoop-azure-2.7.2.jar,http://central.maven.org/maven2/com/microsoft/azure/azure-storage/3.1.0/azure-storage-3.1.0.jar,http://central.maven.org/maven2/com/databricks/spark-avro_2.11/4.0.0/spark-avro_2.11-4.0.0.jar \
    local:///opt/spark/jars/copy-data_2.11-0.1.0-SNAPSHOT.jar



cat <<EOF >dockerImage
FROM timfpark/spark:2.3.0
RUN mkdir -p /opt/spark/jars
COPY target/scala-2.11/copy-locations_2.11-0.1.0-SNAPSHOT.jar /opt/spark/jars
EOF











# get some infos
kubectl cluster-info
# start
cd /root/dockerBuild/greg/spark/spark-2.3.1-bin-hadoop2.7
bin/spark-submit --master \
    k8s://https://10.0.0.5:6443 \
    --deploy-mode cluster \
    --name spark-test \
    --class io.gpid007.spark \
    --conf spark.executor.instances=5 \
    --conf spark.kubernetes.container.image=<spark-image> \
    local:///path/to/examples.jar

    --conf spark.kubernetes.authenticate.driver.serviceAccountName=spark \
    --conf spark.copydata.containerpath=wasb://CONTAINERS@STORAGE_ACCOUNT.blob.core.windows.net \
    --conf spark.copydata.storageaccount=STORAGE_ACCOUNT \
    --conf spark.copydata.storageaccountkey=STORAGE_ACCOUNT_KEY \
    --conf spark.copydata.frompath=wasb://CONTAINER1@STORAGE_ACCOUNT.blob.core.windows.net/PATH1 \
    --conf spark.copydata.topath=wasb://CONTAINER2@locationdata.blob.core.windows.net/PATH2 \
    --conf spark.executor.instances=16 \
    --conf spark.kubernetes.container.image=timfpark/copy-data:latest \
    --jars http://central.maven.org/maven2/org/apache/hadoop/hadoop-azure/2.7.2/hadoop-azure-2.7.2.jar,http://central.maven.org/maven2/com/microsoft/azure/azure-storage/3.1.0/azure-storage-3.1.0.jar,http://central.maven.org/maven2/com/databricks/spark-avro_2.11/4.0.0/spark-avro_2.11-4.0.0.jar \
    local:///opt/spark/jars/copy-data_2.11-0.1.0-SNAPSHOT.jar












# source
https://github.com/kubernetes/examples/tree/master/staging/spark
https://github.com/kubernetes-retired/application-images/tree/master/spark
https://github.com/timfpark/copyData

https://kubernetes.io/blog/2018/03/apache-spark-23-with-native-kubernetes/
http://mirror.klaus-uwe.me/apache/spark/spark-2.3.1/spark-2.3.1-bin-hadoop2.7.tgz

# ssh
sshpass -p 'AAasdf5asdf5' ssh greg@13.80.135.169

# download
cd /opt
wget https://www.apache.org/dyn/closer.lua/spark/spark-2.3.1/spark-2.3.1-bin-hadoop2.7.tgz
tar -xvzf /opt/spark*

# check kubedns
kubectl cluster-info
for word in `kubectl cluster-info | grep master`; do MASTER=`echo $word | grep http`; done
echo $MASTER

# run spark as pod
/opt/spark-2.3.1-bin-hadoop2.7/bin/spark-submit \
   --master k8s://https://10.0.0.5:6443 \
   --deploy-mode cluster \
   --name spark-pi \
   --class org.apache.spark.examples.SparkPi \
   --conf spark.executor.instances=5 \
   --conf spark.kubernetes.container.image= \
   --conf spark.kubernetes.driver.pod.name=spark-pi-driver \
   local:///opt/spark-2.3.1-bin-hadoop2.7/examples/jars/spark-examples_2.11-2.3.1.jar



# ----------------------------------- #



# Sources
https://spark.apache.org/downloads.html
https://spark.apache.org/docs/latest/building-spark.html
#https://spark.apache.org/docs/2.3.0/running-on-kubernetes.html
#https://kubernetes.io/docs/setup/independent/high-availability/
#https://medium.com/@bambash/ha-kubernetes-cluster-via-kubeadm-b2133360b198

# Install java and maven
yum install -y java-1.8.0-openjdk maven

# Export maven settings
export MAVEN_OPTS="-Xmx2g -XX:ReservedCodeCacheSize=512m"
echo $MAVEN_OPTS

# Download spark
cd /opt
wget https://archive.apache.org/dist/spark/spark-2.3.1/spark-2.3.1.tgz

# Extract spark
tar -xvzf spark-2.3.1.tgz
cd spark-2.3.1*

# Build spark with Kubernetes
./build/mvn -Pkubernetes -DskipTests clean package

