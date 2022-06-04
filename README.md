# OCI K3s Cluster

OCI K3s Cluster Infrastructure Repository

Guide used: https://github.com/r0b2g1t/k3s-cluster-on-oracle-cloud-infrastructure

## Build Cluster

Get an API Key and fill out the tfvars example file, then rename it. Create a reserved public IP and create some DNS Records.

``` bash
cd terraform
terraform plan
terraform apply -auto-approve
```

Get kubeconfig and adjust URL

## TODOs

- Longhorn setup
- Add Tailscale for node ssh access
- Deploy service with persistence
- Test persistence
- Ingress with cloudflared
- ...