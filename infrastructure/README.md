# HCP Boundary / Vault Plataforma + Target

This configuration is cloned from the great [repo](https://github.com/jm-merchan/Simple_Boundary_Demo) by [Jose](https://github.com/jm-merchan) with some slight modifications to only create the targets for interacting with Ansible.

In order to run the Ansible demo you'll need a Boundary and Vault cluster. The configuration files in this folder helps you create both clusters as well as the target required to run the [Ansible + Boundary](../) demo.

### Prerequisites:
- Terraform (version used in this demo: 1.9.5)
- An AWS account and credentials accessible in your current environment.
- An HCP account.

Run the following commands to prepare the infrastructure for the Ansible + Boundary demo. First move to the `/infrastructure` directory:
```bash
cd infrastructure/
```

## 1. Create the Plataforma
> ⚠️ NOTE: These resources should take around 5-7 minutes to create
```bash
cd Plataforma/

<export AWS Creds>

terraform init
# Logs to HCP interactively using the browser
terraform apply -auto-approve
```

## 2. Export the following environment variables:
```bash
export BOUNDARY_ADDR=$(terraform output -raw boundary_public_url)
export VAULT_ADDR=$( terraform output -raw vault_public_url)
export VAULT_NAMESPACE=admin
export VAULT_TOKEN=$(terraform output -raw vault_token)
# Log to boundary interactively using password Auth with admin user
boundary authenticate password -password=''
export TF_VAR_authmethod=$(boundary auth-methods list -format json | jq -r '.items[0].id')
```

## 3. Create the Target

### 3.1. Configure Vault
This step creates the necessary policies and enables the SSH secrets engine for Vault to be able to generate SSH certificates and inject them to each host.

```bash
cd ../Target/vault_config
terraform init
terraform apply -auto-approve
```

### 3.2. Deploy target
The target references to a host catalog that by default contains 3 VMs (hosts). You can change the number of VMs created by modifying the `hosts_number` variable in the [variables](./infrastructure/Target/variables.tf) file.

```bash
cd ..
terraform init
terraform apply -auto-approve
```