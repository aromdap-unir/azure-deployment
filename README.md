# Project: Azure Terraform deployment & Ansible configuration of Kubernetes cluster

## Scope
This project will cover the deployment of 2 virtual machines in Azure to act as:
- NFS & Master
- Worker

Via Terraform we will be able to create all resources in Azure.
Via Ansible we will configure all Centos8 machines to be able to run a Kubernetes cluster.

## Terraform
Within the Terraform folder, you will find a set of files that will create all the resources you need for the virtual machines.

You will have to create a credentials.tf file that, for security reasons, has not been uploaded to Github, with your account details:

```vim
provider "azurerm" {
  features {}
  subscription_id = "7e748d57-xxxx-1111-x1x1-xx11xx11xx11xx11"
  client_id       = "4c5d624e-x1x1-x1x1-x1x1-x1x1x1x1x1x1x1"
  client_secret   = "DqA9x2x2x2x2x2x2x2.x2x2x2"
  tenant_id       = "899789dc-x3x3-x3x3-x3x3-x3x3x3x3x3x3"
}
```

### Previous steps
To get that information, follow the Azure Login steps on the CLI. We recommend this [Github repository from jadebustos](https://github.com/aromdap-unir/devopslabs/blob/master/labs-azure/00-primeros-pasos-azure.md) to get an accurate way of reaching that stage.

You will also need to have [configure the SSH credentials](https://www.ssh.com/ssh/keygen/) in your machine. The public SSH key of your local machine will be passed on the authorised keys of the virtual machines automatically via Terraform: ```vm.tf```
```vim
admin_ssh_key {
    username   = "adminUsername"
    public_key = file("~/.ssh/id_rsa.pub")
    }
```

### Run the Terraforms
Go to the folder that holds the Terraform files and simply run:
```console
terraform init
terraform apply
```
You will need to accept the resources that will be created.

In case of wanting to destroy them, use:
```
terraform destroy
```
### Check connection
Via SSH, login into your virtual machines: Get the public IPs from the VMs and place them after the ```ssh adminUsername@```
```
ssh adminUsername@10.10.10.1
```

## Ansible

### Previous steps
Apart from downloading/installing Ansible, you should have a look at the ```99-inventory.yaml``` file in the ```ansible``` folder. There, you should change the hosts, updating them to the new public IPs from your VMs.

Some of the files in the ```/ansible/config``` folder should be also updated to have the most up to date hosts.

### Run the playbooks
You can either create a new playbook to run the rest of the partial playbooks in order, or simply run manually one by one each of them. If you have a look a the ```/ansible``` folder, you can see that the playbooks are named in a numeric sorted basis. Go from 00 to 04 in that order:
```console
ansible-playbook -i 99-inventory.yaml 00-config-all.yaml
```
