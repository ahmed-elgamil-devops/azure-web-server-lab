# Azure Web Server Lab — Terraform + Azure Monitor

A small, complete piece of Azure infrastructure built with Terraform: one hardened Linux
web server in its own network, nightly backups to Blob Storage, and Azure Monitor alerts
that e-mail when the server is down, slow, or running out of disk.

It is deliberately small. Everything here runs inside the **Azure free account** credit,
and `terraform destroy` removes all of it in one command.

## What it builds

```
Resource Group  rg-weblab
│
├── Virtual Network  10.20.0.0/16
│   └── Subnet  web  10.20.1.0/24
│       └── NSG   SSH -> my IP only, HTTP -> internet, everything else denied
│
├── Linux VM  Ubuntu 22.04, Standard_B1s, SSH key only (no password)
│   └── cloud-init installs and starts Nginx on boot
│
├── Storage Account  + private container "backups"
│
└── Azure Monitor
    ├── Action Group   -> e-mail
    └── Alerts         VM unavailable · CPU > 80% · disk free < 15%
```

## Why it is built this way

| Decision | Reason |
| --- | --- |
| SSH restricted to one IP in the NSG | Port 22 open to the internet is the most common way a lab VM gets compromised |
| SSH keys only, password auth disabled | No password to guess or leak |
| Server configured by cloud-init, not by hand | The VM can be destroyed and rebuilt identically |
| Backups to a **private** Blob container | Public containers are a frequent real-world data leak |
| Alerts defined in Terraform | Monitoring is part of the infrastructure, not something added later and forgotten |

## Running it

```bash
az login
cd terraform
cp terraform.tfvars.example terraform.tfvars   # put your own IP and e-mail in it
terraform init
terraform plan
terraform apply
```

`terraform output web_url` prints the address of the Nginx page.

To take it all down again:

```bash
terraform destroy
```

## Backups

`scripts/backup-to-blob.sh` tars the web root, uploads it to the Blob container with
`azcopy`, and keeps the last 7 copies. On the VM it is scheduled with cron:

```
0 2 * * *  /opt/scripts/backup-to-blob.sh >> /var/log/weblab-backup.log 2>&1
```

A backup you have never restored is not a backup, so `docs/monitoring-and-alerts.md`
includes the restore test as a step, not a footnote.

## Cost

Standard_B1s plus a small managed disk and a public IP. Covered by the Azure free
account's first-12-months allowance; outside it, a few dollars a month. Run
`terraform destroy` when you are finished with the lab.

## Layout

```
terraform/   network, VM, storage and alerts
scripts/     cloud-init for the VM, backup script
docs/        what each alert means and how to respond to it
screenshots/ evidence that each part of the lab actually ran
```
