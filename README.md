# azure-infrastructure-samples

## Azure Auth

Workflows connect to azure using a service principal.  This can be setup one time and added to both Actions/Codespace secrets in your [settings](https://docs.github.com/en/actions/security-guides/encrypted-secrets) as `AZURE_CREDENTIALS`.

```bash
az login --use-device-code
az account set --subscription <<your preferred subscription>>
az account show

AZURE_SUBSCRIPTION_ID=$(az account show --query "id" --output tsv)
az ad sp create-for-rbac \
    --name "azure-infrastructure-samples" \
    --role contributor \
    --scopes /subscriptions/$AZURE_SUBSCRIPTION_ID \
    --sdk-auth
```

## SSH Keys

[Instructions](https://docs.microsoft.com/en-us/azure/virtual-machines/linux/mac-create-ssh-keys)

```bash
ssh-keygen -m PEM -t rsa -b 4096 -N '' -f ./ssh

# Store the private key somewhere safe to ssh to your vm

chmod 400 ./ssh

# Sample based on my workflow action
ssh -i ./ssh mattklup@samples-mattklup-centralus.centralus.cloudapp.azure.com

```

## Actions

Workflows are provided to deploy bicep files.  See the [descriptions](bicep/README.md)

## Tools

After connecting to a network, you can do some things to validate your network.

```bash
# Install nmap
sudo apt-get install nmap

# Get ip info and network address in CIDE notation
ip address

# sample output
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
    inet6 ::1/128 scope host 
       valid_lft forever preferred_lft forever
2: eth0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc mq state UP group default qlen 1000
    link/ether 00:22:48:46:17:f4 brd ff:ff:ff:ff:ff:ff
    inet 10.0.0.6/24 brd 10.0.0.255 scope global eth0
       valid_lft forever preferred_lft forever
    inet6 fe80::222:48ff:fe46:17f4/64 scope link 
       valid_lft forever preferred_lft forever

# Run nmap on network mask
nmap -sP 10.0.0.0/24

# sample output (showing other vms)
Starting Nmap 7.60 ( https://nmap.org ) at 2022-02-24 22:32 UTC
Nmap scan report for samples-mattklup-centralus-0.internal.cloudapp.net (10.0.0.5)
Host is up (0.019s latency).
Nmap scan report for samples-mattklup-centralus-1.internal.cloudapp.net (10.0.0.6)
Host is up (0.000088s latency).
Nmap done: 256 IP addresses (2 hosts up) scanned in 3.03 seconds

# Show 'devices' on your network
arp -n

# sample output
Address                  HWtype  HWaddress           Flags Mask            Iface
10.0.0.1                 ether   12:34:56:78:9a:bc   C                     eth0
10.0.0.5                 ether   12:34:56:78:9a:bc   C                     eth0
```