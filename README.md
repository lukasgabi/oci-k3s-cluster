# OCI K3s Cluster

OCI K3s Cluster Infrastructure Repository

Guide used: https://github.com/r0b2g1t/k3s-cluster-on-oracle-cloud-infrastructure

## Required tools

- terraform
- kubectl
- helm
- ...

## Build Cluster

### Infrastructure

Get an API Key and fill out the tfvars example file, then rename it. Create a reserved public IP and create some DNS Records.

``` bash
cd terraform
terraform plan
terraform apply -auto-approve
cd ..
```

Get a Coffee and wait until everything is deployed, then get the kubeconfig and check access.

``` bash
kubectl get nodes
```

The infrastructure should be ready now, get kubeconfig and adjust URL to continue.

### Kubernetes

#### Cert Manager

``` bash
helm repo add jetstack https://charts.jetstack.io
helm repo update
helm install cert-manager jetstack/cert-manager --namespace cert-manager --create-namespace --version v1.7.1 --set installCRDs=true

kubectl apply -f ./services/cert-manager/cluster_issuer.yaml
```

#### Longhorn

``` bash
helm repo add longhorn https://charts.longhorn.io
helm repo update
helm install -f ./services/longhorn/values.yaml longhorn longhorn/longhorn --namespace longhorn-system --create-namespace
kubectl patch storageclass local-path -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"false"}}}'
kubectl patch storageclass longhorn -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'
```

#### Sample App

``` bash
kubectl create namespace nginx
kubectl apply -f ./services/nginx
```

## TODOs

- Longhorn setup
- Add Tailscale for node ssh access
- Deploy service with persistence
- Test persistence
- Ingress with cloudflared
- ...