# azure-infrastructure-samples

Workflows connect to azure using a service principal.  This can be setup one time and added to both Actions/Codespace secrets in your [settings](settings/secrets/actions) as `AZURE_CREDENTIALS`.

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