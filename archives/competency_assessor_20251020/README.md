# SE Competency Assessment App

This repository contains the source code and related artifacts for the **Systems Engineering Competency Assessment App**. This application was developed as part of my Master Thesis (***Generative AI Driven Systems Engineering Competency Assessment***) in Computer Science at Paderborn University (Derik Roby). It is designed to evaluate the competency of systems engineers within a company based on an established framework. It is build on the theoretical foundations from Ulf Könemann. 
---

## Overview

The SE Competency Assessment App is a web-based solution that:
- **Evaluates Systems Engineering Competencies:** Captures responses via structured questionnaires.
- **Provide competency gap analysis:** Automatically from user selections calculate the users required competency levels and assess the user and provide gap analysis between the asssessed and required levels.
- **Suggest best fit roles:** Based on Assessment Results.

---

## Technologies Used

- **Backend:** Flask (Python)
- **Frontend:** Vue.js
- **LLM & RAG Pipelines:** Langchain
- **Database:** PostgreSQL
- **Deployment:** Docker

---

## Main folders in Repository

- **app**  
  Contains the Flask backend code.

- **frontend**  
  Contains the Vue.js frontend code.

- **postgres-init**  
  Database initialization scripts for PostgreSQL.

- **Validation**  
  Scripts and analysis files for validating and processing assessment results.

- **competency_questionnaires**  
  Contains competency indicators and all related survey questions.

- **Docker files present used for containerized deployment**

---

## Deployment Instructions

Follow these steps to deploy the SE Competency Assessment App on a Linux server:

### 1. SSH into Your Virtual Machine (VM)
```bash
ssh your_username@your_vm_ip_address
```
### 2. Install Git
```bash
sudo apt update
sudo apt install git -y
```

### 3. Generate and configure SSH Key
Generate a new SSH key:
```
ssh-keygen -t rsa -b 4096 -C "derik.roby@outlook.com"

```
Copy your generated public key and add it to your GitHub account:
```
cat ~/.ssh/id_rsa.pub
```

### 4. Verify Github connectivity
```
ssh -T git@github.com
```

### 5.  Clone the Repository
```
git clone git@github.com:yourgitusername/sesurveyapp.git  
# go to the main directory
cd sesurveyapp
```

### 6. Configure Environment Variables
In the `docker-compose.yml` file, update the `VUE_APP_API_URL` to point to your machine’s IP address and port 5000 or Flask (e.g., http://50xxxxx79:5000).

Create a `.env` file in the project root directory with the following content:
```
AZURE_OPENAI_API_KEY="your azure open ai api key" #Not needed for app
AZURE_OPENAI_ENDPOINT="Azure llm deployment endpoint" #Not needed for app

# Frontend Environment Variables
VUE_APP_API_URL=http://xx.xx.xx:5000 #Give IP of your machine -- IMP
OPENAI_API_KEY="xxxxxxx" # Open AI API Key IMP
DATABASE_URL=postgresql://ma0349:MA0349_2025@postgres:5432/competency_assessment #Keep it like this --IMP
```

### 7. Build and Deploy the Containers
```
docker compose build --no-cache
docker compose --env-file .env up -d
```

### 8. Clearing the database of survey assessments 
To clear past responses from the survey, you can truncate the app_user table:
Find container id of postgres container (corresponds to image name sesurveyapp-postgres)
```
docker ps
```

SSH into PostgreSQL container
```
docker exec -it <postgres_container_id> bash
```

Connect to PostgreSQL DB
```
psql -U ma0349 competency_assessment
```

Truncate the taböe
```
TRUNCATE TABLE app_user CASCADE;

```

## Additional Information
This repository not only includes the web application but also contains folders with the analysis performed for evaluation and other tasks. 

For any questions or further information, please contact Derik Roby at `derik.roby@outlook.com` or my thesis supervisor Ulf Könemann (`ulf.koenemann@iem.fraunhofer.de`). 