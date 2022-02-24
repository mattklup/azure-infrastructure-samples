# azure-infrastructure-samples

## Azure Auth

Workflows connect to azure using a service principal.  This can be setup one time and added to both Actions/Codespace secrets in your [settings](../../settings/secrets/actions) as `AZURE_CREDENTIALS`.

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
