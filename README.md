# Provisioning AWS to run the Syndetic data shop

## Infrastructure

 + Put a secure password for the DB in config/secrets.tfvars 
 + Customize variables in config/config.tfvars
 + Update service-account-for-alb.yml with your AWS account ID (

Run the following commands:

terraform init
terraform plan --var-file=./secrets/secrets.tfvars
terraform apply --var-file=./secrets/secrets.tfvars

## Load balancer

You can't run a load balancer without further steps. The previous
terraform invocation sets up the OpenID provider, a role, and a
policy, but not the service account inside kubernetes. For that run:

kubectl apply -f kubernetes/service-account-for-alb.yaml

Then, (from https://docs.aws.amazon.com/eks/latest/userguide/aws-load-balancer-controller.html):

kubectl apply -k "github.com/aws/eks-charts/stable/aws-load-balancer-controller//crds?ref=master"
helm upgrade -i aws-load-balancer-controller eks/aws-load-balancer-controller \
  --set clusterName=staging-eks-jbw14mbB \
  --set serviceAccount.create=false \
  --set serviceAccount.name=aws-load-balancer-controller \
  -n kube-system

## SSL Cert
  1. Create a hosted zone in Route 53
  2. Create a certificate for the subdomain using route53 for validation

## Logging (optional)
https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/Container-Insights-setup-logs.html

  1. kubectl apply -f https://raw.githubusercontent.com/aws-samples/amazon-cloudwatch-container-insights/latest/k8s-deployment-manifest-templates/deployment-mode/daemonset/container-insights-monitoring/cloudwatch-namespace.yaml

  2 kubectl create configmap cluster-info \
--from-literal=cluster.name=staging-eks-jbw14mbB \
--from-literal=logs.region=us-east-1 -n amazon-cloudwatch
