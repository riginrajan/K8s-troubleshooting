#!/bin/sh
# Shell Script 2 to Troubleshoot and Learn Kubernetes

#Set Variables

namespace=issue5
issue_env="Issue 5"
svcname=svc5
podname=pod5
depname=HCL-deploy
cmname=nginx-index-cm5
volname=nginx-conf5
subpath=index5.html
indexfile=/data/index5.html

mkdir /data 2>/dev/null
echo "\nHCL-K8s: \e[1;36mCongrats - You successfully fixed $issue_env\e[0m \n " >$indexfile
#echo "HCL-K8s: Congrats - You fixed Issue number 3 \n " >/data/index3.html
#echo "HCL-K8s: Awesome - You fixed Issue number 4 \n " >/data/index4.html

# Creating Issue
echo "\n\n************************************************"
echo "\nSetting up environment for Troubleshooting in \"\e[1;34mNamespace:\e[0m \e[1;33m$namespace\e[0m\" . . . . Please Wait . . . .  "
sleep 2

echo ""

kubectl delete ns $namespace 2>/dev/null >/dev/null
kubectl create ns $namespace 

mkdir /$namespace 2>/dev/null >/dev/null

#Creating ConfigMap
cat << EOF >/$namespace/$cmname.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: $cmname
  namespace: $namespace
data:
  index5err.html: "HCL-K8s: Congrats - You are moving ahead and successfully
    fixed $issue_env \n \n"
EOF

#

#Creating Deployment
cat << EOF >/$namespace/$depname.yaml

apiVersion: apps/v1
kind: Deployment
metadata:
  name: $depname
  labels:
    name: $depname
  namespace: $namespace
spec:
  replicas: 2
  selector:
    matchLabels:
      name: $podname
  template:
   metadata:
    name: $podname
    labels:
     name: $podname
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

kubectl delete deploy $depname -n $namespace 2>/dev/null >/dev/null
kubectl create -f /$namespace/$depname.yaml

kubectl delete svc $svcname -n $namespace 2>/dev/null >/dev/null
sleep 3

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
 echo "\n\e[1;33mNote: Your Application is not functioning, you need to fix the issue. \e[0m We need to get application output while running  \"curl `kubectl get svc $svcname -n $namespace|sed 1d|awk '{print $3}'`\" command ( IP mentioned here is nothing but your service IP in $namespace Namespace )"
 echo "\nAll Definition files are saved in /$namespace directory feel free to review"
 echo "\nYou are currently in \e[1;34m`kubectl config view|grep -i namespace|awk '{print $NF}'`\e[0m namespace, run \"kubectl config set-context --current --namespace=$namespace\" to change your namespace to \e[1;34m$namespace\e[0m if required"
 echo "\n\n* All the Best *"
else
 echo "Some Issue with deploying - do cleanup and re-run the script"
fi
echo "\n\n************************************************"
