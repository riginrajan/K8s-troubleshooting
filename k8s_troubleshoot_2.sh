#!/bin/sh
# Shell Script 2 to Troubleshoot and Learn Kubernetes

#Set Variables

namespace=issue2
issue_env="Issue 2"
svcname=svc2
podname=pod2
cmname=nginx-index-cm2
volname=nginx-conf2
subpath=index2.html
indexfile=/data/index2.html

mkdir /data 2>/dev/null
echo "HCL-K8s: \e[1;36mCongrats - You are moving ahead and successfully fixed $issue_env\e[0m \n " >$indexfile
#echo "HCL-K8s: Congrats - You fixed Issue number 3 \n " >/data/index3.html
#echo "HCL-K8s: Awesome - You fixed Issue number 4 \n " >/data/index4.html

# Creating Issue Number 2
echo "\n\n************************************************"
echo "\nSetting up environment for Troubleshooting in \"\e[1;34mNamespace:\e[0m \e[1;33m$namespace\e[0m\" . . . . Please Wait . . . .  "
sleep 2

echo ""

kubectl get nodes|sed 1d|awk '{print $1" "$3}'|while read node role
do
if [ `echo "$role"|grep -ic "control-plane"` -gt 0 ];then
kubectl taint node $node node-role.kubernetes.io/master:NoSchedule 2>/dev/null >/dev/null
else
kubectl taint node $node key1=value1:NoSchedule 2>/dev/null >/dev/null
fi
done

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
 echo "\n\e[1;33mNote: Your Application is not functioning, you need to fix the issue. \e[0m We need to get application output while running  \"curl `kubectl get svc $svcname -n $namespace|sed 1d|awk '{print $3}'`\" command ( IP mentioned here is nothing but your service IP in $namespace Namespace )"
 echo "\nAll Definition files are saved in /$namespace directory feel free to review"
 echo "\nYou are currently in \e[1;34m`kubectl config view|grep -i namespace|awk '{print $NF}'`\e[0m namespace, run \"kubectl config set-context --current --namespace=$namespace\" to change your namespace to \e[1;34m$namespace\e[0m if required"
 echo "\n\n* All the Best *"
else
 echo "Some Issue with deploying - do cleanup and re-run the script"
fi
echo "\n\n************************************************"
