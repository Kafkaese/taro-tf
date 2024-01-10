tfplan :
	terraform plan -var "image_registry_credential_user=$ARM_CLIENT_ID" -var "image_registry_credential_password=$ARM_CLIENT_SECRET" -out 'main.tfplan'

runapi:
	docker run -it -p 8000:8000 -e "POSTGRES_PORT=5432" -e "TF_VAR_postgres_user=postgres" -e "TF_VAR_postgres_password=secret" -e "POSTGRES_HOST=taro-postgresql-server.postgres.database.azure.com" -e "POSTGRES_USER=postgres" -e "POSTGRES_PASSWORD=secret" -e "POSTGRES_DB=taro-db" -e "ENV=production" tarocontainerregistry.azurecr.io/taro:api