# Ansible + Boundary
This repo contains the necessary resources to DEMO the interaction with Ansible using the secure remote access capabilities from Boundary. This integration is achieved by dynamically generating an inventory file for Ansible using the IPs and ports provided by Boundary when a connection is established to a remote host.

![Ansible + Boundary workflow diagram](./src/Boundary%20Ansible.png)

The basic workflow is:
0. Authentication to Boundary: guarantees RBAC to the required targets
1. Python script: generates Boundary clients to connect to the target
2. Boundary identifies the hosts in the target
3. Credential injection using Vault provides a passwordless experience
4. Inventory file for Ansible is generated using the addresses and ports provided by Boundary
5. Secure connection between Ansible and hosts via a secure tunnel provided by Boundary

In this example, the playbook only does a basic ping and prints a message from every server in the inventory.

## Prerequisites
In order to execute this workflow you'll need to have installed or configured the following resources and apps:
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
For a detailed explanation check the [README](./infrastructure/README.md) from the Infrastructure directory.

#### 2.1. Deploy the 'Plataforma' (Boundary and Vault clusters)
```bash
cd Infrastructure/Plataforma
terraform init
terraform apply -auto-approve
```

Run these commands to create the required environment variables:
```bash
export BOUNDARY_ADDR=$(terraform output -raw boundary_public_url)
export VAULT_ADDR=$( terraform output -raw vault_public_url)
export VAULT_NAMESPACE=admin
export VAULT_TOKEN=$(terraform output -raw vault_token)
# Log to boundary interactively. You'll be asked for the password
boundary authenticate password -password=''
export TF_VAR_authmethod=$(boundary auth-methods list -format json | jq -r '.items[0].id')
```

#### 2.2. Deploy the target:
> If you feel like trying some things out you can change the number of VMs created by modifying the `hosts_number` variable in the [variables](./infrastructure/Target/variables.tf) file.

```bash
# Configure Vault:
cd ../Target/vault_config
terraform init
terraform apply -auto-approve

#Deploy target:
cd ..
terraform init
terraform apply -auto-approve

```

### 3. Generate `inventory.ini` file

#### 3.1. Environment variables
In order to successfully generate the inventory file you'll need to specify the environment variables needed to connect to Boundary. Ignore this step if you already created them in step 2.1:
```bash
export BOUNDARY_AUTHENTICATE_PASSWORD_PASSWORD=<your-boundary-password>
export BOUNDARY_AUTHENTICATE_PASSWORD_LOGIN_NAME=<your-boundary-login-name>
export BOUNDARY_ADDR=<your-boundary-cluster-url>
```

#### 3.2. Inventory
Change to the Ansible directory:

```bash
cd ../../ansible
```

Run the `generate_inventory.py` with the alias of your target. If you're using the example target deployed in step 2 this will look like:
```bash
python3 generate_inventory.py ssh.ansible.boundary.demo   #Change according to your alias
```

You should see an `inventory.ini` file created under the `/ansible` directory. This file was populated with the IP addresses and ports of the connections created by Boundary, this is what Ansible will use to establish a secure connection (on top of SSH) to each of the hosts in the target.

### 4. Execute the playbook
This demo uses a simple [playbook](./ansible/playbook.yaml) example that only executes a basic ping and prints a message from each of the connected hosts. 

The Python script handling the connections should be running in the current terminal. To run the playbook with the inventory file that was just generated open a new terminal, go to the `ansible` directory and run:

```bash
ansible-playbook -i inventory.ini playbook.yaml
```

This is more or less what the output should look like:
```
PLAY [My first play] ***********************************************************

TASK [Gathering Facts] *********************************************************
ok: [server2]
ok: [server0]
ok: [server1]

TASK [Ping my hosts] ***********************************************************
ok: [server2]
ok: [server1]
ok: [server0]

TASK [Print message] ***********************************************************
ok: [server0] => {
    "msg": "Hello world"
}
ok: [server1] => {
    "msg": "Hello world"
}
ok: [server2] => {
    "msg": "Hello world"
}

PLAY RECAP *********************************************************************
server0                    : ok=3    changed=0    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   
server1                    : ok=3    changed=0    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   
server2                    : ok=3    changed=0    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
```
### 5. Stop connections
To stop the open connections with Boundary go back to the terminal running the Python script and press `CTRL+c`

### 6. Cleanup 
If you ran every step sequentially you should currently be in the `/ansible` directory. Now we'll destroy everything from the last to the first resource.

Move back to `infrastructure/Target`:

```bash
# Destroy target:
cd ../infrastructure/Target
rm -f cert.pem
terraform destroy -auto-approve

# Destroy Vault configurations:
cd vault_config
terraform destroy -auto-approve

# Destroy plataforma:
cd ../../Plataforma
terraform destroy -auto-approve
```


