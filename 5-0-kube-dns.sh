#!/bin/bash

cat <<EOF >busybox.yaml
apiVersion: v1
kind: Pod
metadata:
  name: busybox
  namespace: default
spec:
  containers:
  - name: busybox
    image: busybox
    command:
      - sleep
      - "3600"
    imagePullPolicy: IfNotPresent
  restartPolicy: Always
EOF

kubectl create -f busybox.yaml
kubectl exec -ti busybox -- sh
kubectl exec -ti busybox -- nslookup kubernetes.default

