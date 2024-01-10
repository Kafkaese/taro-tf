all:
	plan
	apply
plan:
	tf plan -out main.tfplan -var "container_registry_credential_user=$ARM_CLIENT_ID" -var "container_registry_credential_password=$ARM_CLIENT_SECRET" -var "api_ip_address=4.211.64.61" -var "api_ip_id=/subscriptions/25b8173d-c366-46e1-8796-8d6207239832/resourceGroups/taro/providers/Microsoft.Network/publicIPAddresses/taro-production-api-public-ip" -var "frontend_ip_address=20.74.1.73" -var "frontend_ip_id=/subscriptions/25b8173d-c366-46e1-8796-8d6207239832/resourceGroups/taro/providers/Microsoft.Network/publicIPAddresses/taro-production-frontend-public-ip"
apply:
	tf apply main.tfplan