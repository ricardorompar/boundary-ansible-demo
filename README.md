# Ansible + Boundary
This repo contains the necessary resources to DEMO the interaction with Ansible using the secure remote access capabilities from Boundary. This integration is achieved by dynamically generating an inventory file for Ansible using the IPs and ports provided by Boundary when a connection is established to a remote host.

The basic workflow is:
- Authentication to Boundary: guarantees RBAC to the required targets
- Dynamic generation of the inventory file
- Ansible uses the tunnel created by Boundary 
- Credentials are injected using Vault
- Ansible playbook execution

In this example the playbook only does a basic ping from every server in the inventory.

## Prerequisites
In order to execute this workflow you'll need to have installed or configured the following resources and apps:
- A Boundary cluster.
- A Vault cluster to configure credential injection for your target hosts.
- Terraform to deploy the demo target (version used in this demo: 1.9.5)
- An AWS account where your target will be created.
- Python (version used in this demo: 3.13)
- Ansible (version used in this demo: 2.17)

## Execution

### 1. Clone repo
Copy this repo into your working directory:
```bash
git clone https://github.com/ricardorompar/boundary-ansible-demo.git && cd boundary-ansible-demo
```

You'll need a Boundary target with a named alias and credential injection configured for that target. If you have an existing one feel free to move to step 3. Or, you can deploy the demo example by following the commands in step 2.

### 2. Deploy infrastructure
> ⚠️ Work in progress...
```bash
#work in progress...
cd infrastructure
terraform init
terraform apply -auto-approve
```

### 3. Generate `inventory.ini` file

#### Environment variables
In order to successfully generate the inventory file you'll need to specify the environment variables needed to connect to Boundary:
```bash
export BOUNDARY_AUTHENTICATE_PASSWORD_PASSWORD=<your-boundary-password>
export BOUNDARY_AUTHENTICATE_PASSWORD_LOGIN_NAME=<your-boundary-login-name>
export BOUNDARY_ADDR=<your-boundary-cluster-url>
```

#### Inventory
Change to the Ansible directory:

```bash
cd ../ansible
```

Run the `generate_inventory.py` with the alias of your target. If you're using the example target deployed in step 2 this will look like:
```bash
python3 generate_inventory.py scenario1.boundary.demo   #change according to your alias
```

You should see an `inventory.ini` file created under the `/ansible` directory. This file was populated with the IP addresses and ports of the connections created by Boundary, this is what Ansible will use to establish a secure connection (on top of SSH) to each of the hosts in the target.

### 4. Execute the playbook
This demo uses a simple [playbook](./ansible/playbook.yaml) example that only executes a basic ping and prints a message from each of the connected hosts. To run the playbook with the inventory file that was just generated run:
```bash
ansible-playbook
```


