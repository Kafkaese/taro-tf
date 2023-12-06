<h1>Arms-tracker App</h1>

This repository is part of the arms-tracker app, an interactive web-application visualising the flow of arms ex- and imports and the impact on global conflict.

You can visit the app at <a href=https://www.arms-tracker.app>www.arms-tracker.app</a>

For a full documentation please go to <a href=https://github.com/Kafkaese/taro> this repository </a>, which serves as a landing page and gives a better overview of the entire project. Below you can find the section of the documentation that refers to this repository in particular.

<h2>Production Environment Infrastructure Repository</h2>
<img title="Production Environment Structure" alt="This should be a really nice diagram of the infrastructure of the production environment" src="https://raw.githubusercontent.com/Kafkaese/taro/main/images/taro_production_schema.svg">

The indiviudal components of the infrastructure are listed below:

<h4>Resource Group, Storage, Registry and Network</h4>
All resources on Azure must  be part of a Resource Group, so the production environment has a dedicated Resource Group. 
Part of the Resource Group is a Storage Account, that stores the backend for all the Terraform Configurations, including the one for the production environment. 
For this reason the Resource Group  and the Storage Account are marked as indestructible.
<br></br> 
A dedicated Virtual Network for the prodcution environment is also created, as well as a Container Registry for all docker images needed.
  
<h4>Postgres Server</h4>
An Azure Postgresql Flexible Server. The server is initiated with a database for the backend. It also comes with a private DNS zone that assigns a FQDN within the Virtual Network to the Postgres Server. 
The server has a dedicated Subnet with a servide delegation to 'Azure Postgres Flexible Server'.  

<h4>API and Data Pipeline</h4>
The API and the Data Pipeline are both containerized and deployed as part of a Container Group. The Data Pipeline is deployed as an init container that is run exactly once during creation of the Container Group. Then the API container is deployed in the same Container Group. The API container runs a Uvicorn server, serving a FastAPI application.
Like most resources, the Container Group has a dedicated Subnet with a service delegation.

<h4>Frontend</h4>
The React frontend is also containerized and deployed in a dedicated Container Group, again with its own subnet with a service delegation.  The container runs an Nginx webserver that serves the built React application.

<h4>Reverse Proxy</h4>
The Application is reachable via a single public IP address that has a number of DNS records on Google Domains. The public IP is associated with a Network Interface connected to a Virtual Machine.
The Virtual Machine runs an Nginx Reverse Proxy Server. The server is configured to listen on the 443 HTTPS port. For this purpose the ssl certificate and keychain are stored on the VM. The certifcate is valid for arms-tracker.app as well as api.arms-tracker.app, so all traffic is ssl encrypted.
The Network Interface has a Network Security Group attached, with Inbound Rules for HTTPS for regular encrypted traffic to the API and the Frontend, and also for SSH for development and maintenance purposes.
The reverse proxy server is configured to send traffic to arms-tracker.app to the Frontend Container Groups private IP. All traffic to api.arms-tracker.app is directed to the API Container Groups private IP. 
