#!/bin/sh
# Shell Script to Troubleshoot and Learn Kubernetes

#Set Variables

namespace=issue6
issue_env="Issue 6"
svcname=svc6
podname=pod6
cmname=nginx-index-cm6
volname=nginx-conf6
subpath=index6.html
indexfile=/data/index6.html


mkdir /data 2>/dev/null
echo "\nHCL-K8s: \e[1;36mGood - You fixed $issue_env\e[0m \n " >$indexfile

echo "\n\n************************************************"
echo "\nSetting up environment for Troubleshooting in \"\e[1;34mNamespace:\e[0m \e[1;33m$namespace\e[0m\" . . . . Please Wait . . . .  "
sleep 2

echo ""


kubectl delete ns $namespace 2>/dev/null >/dev/null
kubectl create ns $namespace 

#Create Config Maps
kubectl delete cm $cmname -n $namespace >/dev/null 2>/dev/null
kubectl create configmap $cmname --from-file=$indexfile -n $namespace

mkdir /$namespace 2>/dev/null >/dev/null

cat << EOF >/$namespace/$podname.yaml
apiVersion: v1
kind: Pod
metadata:
  name: $podname
  labels:
    name: $podname
  namespace: $namespace
spec:

  containers:
  - name: nginx
    image: nginx
    ports:
      - containerPort: 80
    volumeMounts:
      - mountPath: /usr/share/nginx/html/index.html
        name: $volname
        subPath: $subpath
  volumes:
    - name: $volname
      configMap:
        name: $cmname
EOF

kubectl delete pod $podname -n $namespace 2>/dev/null >/dev/null
kubectl create -f /$namespace/$podname.yaml
cp ~/.kube/config /tmp/config
kubectl delete svc $svcname -n $namespace 2>/dev/null >/dev/null
sleep 5

cat << EOF >/$namespace/$svcname.yaml
apiVersion: v1
kind: Service
metadata:
  name: $svcname
  namespace: $namespace
spec:
  selector:
    name: $podname
  ports:
    - protocol: TCP
      port: 80
EOF

kubectl create -f /$namespace/$svcname.yaml

if [ $? -eq 0 ];then
 echo "\n\n$issue_env: Environment is successfully setup"
 echo "\n\e[1;33mNote: None of the Cluster commands are working, you need to fix the issue. \e[0m We need to get application output while running  \"curl serviceip\" command ( Unable to fetch actual IP address due to cluster issue, fix the issue and curl command for service ip in $namespace Namespace )"
 echo "\nAll Definition files & backups are saved in /$namespace directory feel free to review"
 echo "\nYou are currently in \e[1;34m`kubectl config view|grep -i namespace|awk '{print $NF}'`\e[0m namespace, you need to fix the issue and run \"kubectl config set-context --current --namespace=$namespace\" to change your namespace to  \e[1;34m$namespace\e[0m if required"
 echo "\n\n* All the Best *"
else
 echo "Some Issue with deploying - do cleanup and re-run the script"
fi
mv ~/.kube/config /$namespace/config
echo "\n\n************************************************"
