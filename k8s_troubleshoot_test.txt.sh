#/bin/ksh
# Shell Script to Troubleshoot and Learn Kubernetes

#Set Variables

namespace=test
issue_env="Test"
svcname=svc
podname=pod
cmname=nginx-index-cm
volname=nginx-conf
subpath=index.html
indexfile=/data/index.html


mkdir /data 2>/dev/null
echo "\nHCL-K8s: \e[1;36mCool - This is just a test setup, everything should be fine\e[0m \n " >$indexfile


echo "\n\n************************************************"
echo "\nSetting up Test environment in \"\e[1;34mNamespace:\e[0m \e[1;33m$namespace\e[0m\" . . . . Please Wait . . . .  "
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
 echo "\n\e[1;33mNote: Your Application is working fine, this is just a test setup for demo. \e[0m Your Application can be accessed by running \"curl `kubectl get svc $svcname -n $namespace|sed 1d|awk '{print $3}'`\" command ( IP mentioned here is nothing but your service IP in $namespace Namespace )"
 echo "\nAll Definition files are saved in /$namespace directory feel free to review"
 echo "\nYou are currently in \e[1;34m`kubectl config view|grep -i namespace|awk '{print $NF}'`\e[0m namespace, run \"kubectl config set-context --current --namespace=$namespace\" to change your namespace to  \e[1;34m$namespace\e[0m if required"
else
 echo "Some Issue with deploying - do cleanup and re-run the script"
fi
echo "\n\n************************************************"
