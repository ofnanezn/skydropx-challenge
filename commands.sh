# Setting some environment variables
export PROJECT_ID=$(gcloud config get-value project)
export PROJECT_NUMBER=$(gcloud projects list --filter="$(gcloud config get-value project)" --format="value(PROJECT_NUMBER)")
export REGION=us-east4
export ZONE=us-east4c
export SA_NAME=skydropx-sa
export BUCKET_NAME=skydropx-storage

# Enabling compute API
gcloud services enable compute.googleapis.com

# Creating network and subnets
gcloud compute networks create skydropx-net --project=$PROJECT_ID --subnet-mode=custom --mtu=1460 --bgp-routing-mode=regional

gcloud compute networks subnets create skydropx-public --project=$PROJECT_ID --range=10.0.0.0/24 --network=skydropx-net --region=$REGION

gcloud compute networks subnets create skydropx-private --project=$PROJECT_ID --range=10.0.1.0/24 --network=skydropx-net --region=$REGION --enable-private-ip-google-access

# Setting Cloud NAT for private instances 
gcloud compute routers create skydropx-router \
    --project=$PROJECT_ID \
    --network=skydropx-net \
    --region=$REGION

gcloud compute routers nats create skydropx-nat \
    --router=skydropx-router \
    --region=${REGION} \
    --auto-allocate-nat-external-ips \
    --nat-all-subnet-ip-ranges

# Managing service account
gcloud iam service-accounts create $SA_NAME

gcloud iam service-accounts keys create credentials.json --iam-account ${SA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com

gsutil mb gs://${BUCKET_NAME}

gsutil cp credentials.json gs://${BUCKET_NAME}/

# Creating instances group template
gcloud compute instance-templates create skydropx-template --project=${PROJECT_ID} --machine-type=e2-small \
	--network-interface=subnet=skydropx-private,no-address \
	--metadata=startup-script=sudo\ apt\ update$'\n'sudo\ apt\ install\ docker.io\ -y$'\n'sudo\ apt\ install\ docker-compose\ -y$'\n'sudo\ apt\ install\ git\ -y$'\n'git\ clone\ https://github.com/ofnanezn/skydropx-challenge.git$'\n'cd\ skydropx-challenge$'\n'gsutil\ cp\ gs://${BUCKET_NAME}/credentials.json\ .$'\n'gcloud\ auth\ activate-service-account\ skydropx-sa@skydropx-challenge-project.iam.gserviceaccount.com\ --key-file\ credentials.json$'\n'echo\ \"INTERNAL_IP=\$\(gcloud\ compute\ instances\ describe\ \$HOSTNAME\ --zone=${ZONE}\ --format=\'get\(networkInterfaces\[0\].networkIP\)\'\)\"\ \>\ .env$'\n'sudo\ docker-compose\ build$'\n'sudo\ docker-compose\ up\ -d \
	--maintenance-policy=MIGRATE --service-account=${PROJECT_NUMBER}-compute@developer.gserviceaccount.com \
	--scopes=https://www.googleapis.com/auth/devstorage.read_only,https://www.googleapis.com/auth/logging.write,https://www.googleapis.com/auth/monitoring.write,https://www.googleapis.com/auth/servicecontrol,https://www.googleapis.com/auth/service.management.readonly,https://www.googleapis.com/auth/trace.append \
	--region=${REGION} --tags=http-server,https-server \
	--create-disk=auto-delete=yes,boot=yes,device-name=skydropx-template,image=projects/ubuntu-os-cloud/global/images/ubuntu-2004-focal-v20211212,mode=rw,size=10,type=pd-balanced \
	--no-shielded-secure-boot --shielded-vtpm --shielded-integrity-monitoring --reservation-affinity=any

# Instances group creation
gcloud compute --project=${PROJECT_ID} instance-groups managed create instance-group-skydropx \
	--base-instance-name=instance-group-skydropx --template=skydropx-template --size=1 --zone=${ZONE}

gcloud beta compute --project "${PROJECT_ID}" instance-groups managed set-autoscaling "instance-group-skydropx" \
	--zone "${ZONE}" --cool-down-period "120" --max-num-replicas "4" --min-num-replicas "2" \
	--target-cpu-utilization "0.4" --mode "on"

# Health-check Creation
gcloud compute health-checks create http skydropx-hc \
    --global \
    --check-interval=10 \
    --timeout=10 \
    --healthy-threshold=2 \
    --unhealthy-threshold=5 \
    --port=80

gcloud compute firewall-rules create fw-allow-health-check \
     --network=skydropx-net \
     --action=allow \
     --direction=ingress \
     --source-ranges=130.211.0.0/22,35.191.0.0/16 \
     --target-tags=allow-health-check \
     --rules=tcp

# From this point, the load balancer will be created manually due to some errors when running in command line

#gcloud compute backend-services create lb-backend \
#	--project=${PROJECT_ID} \
#	--health-checks="https://www.googleapis.com/compute/v1/projects/${PROJECT_ID}/global/healthChecks/skydropx-hc" \
#	--protocol=http \
#	--global \
#	--global-health-checks

#gcloud compute backend-services add-backend lb-backend \
#	--project=${PROJECT_ID} \
#	--instance-group=instance-group-skydropx \
#	--instance-group-zone=${ZONE} \
#	--balancing-mode=UTILIZATION \
#	--global



