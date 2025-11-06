Launch Amazon Linux 2023 , t2.micro

Attach a IAM ROLE TE=EC2, Permisions = admin

vi .bashrc
export PATH=$PATH:/usr/local/bin/


source .bashrc

ssh-keygen

cp /root/.ssh/id_rsa.pub my-keypair.pub

chmod 777 my-keypair.pub

vi kops.sh

# Step 1: Download kubectl and kops
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
wget https://github.com/kubernetes/kops/releases/download/v1.32.0/kops-linux-amd64

# Step 2: Make both binaries executable
chmod +x kubectl kops-linux-amd64

# Step 3: Move them to /usr/local/bin
sudo mv kubectl /usr/local/bin/
sudo mv kops-linux-amd64 /usr/local/bin/kops

# Step 4: Create a unique S3 bucket for KOps state store
# (Bucket name must be globally unique — so append date or random number)
BUCKET_NAME=reyaz-kops-state-$(date +%s)
aws s3api create-bucket \
  --bucket $BUCKET_NAME \
  --region ap-south-1 \
  --create-bucket-configuration LocationConstraint=ap-south-1

# Step 5: Enable versioning on the bucket
aws s3api put-bucket-versioning \
  --bucket $BUCKET_NAME \
  --region ap-south-1 \
  --versioning-configuration Status=Enabled

# Step 6: Export the KOps state store variable
export KOPS_STATE_STORE=s3://$BUCKET_NAME

# (Optional) Check it:
echo "KOPS_STATE_STORE is set to $KOPS_STATE_STORE"

# Step 7: Create the cluster configuration
kops create cluster \
  --name=reyaz.k8s.local \
  --zones=ap-south-1a \
  --control-plane-count=1 \
  --control-plane-size=t3.medium \
  --node-count=2 \
  --node-size=t3.small \
  --node-volume-size=20 \
  --control-plane-volume-size=20 \
  --ssh-public-key=my-keypair.pub \
  --image=ami-02d26659fd82cf299 \
  --networking=calico \
  --state=$KOPS_STATE_STORE

# Step 8: Apply the cluster configuration and start creation
kops update cluster --name reyaz.k8s.local --state=$KOPS_STATE_STORE --yes --admin

# Step 9: Validate the cluster (wait 10–15 minutes)
kops validate cluster --state=$KOPS_STATE_STORE

sh kops.sh 

wq!

export KOPS_STATE_STORE=s3://reyaz-kops-testbkt1433.k8s.local
kops validate cluster --wait 10m


-- kops get cluster

-- kubectl get nodes/no

-- kubectl get nodes -o wide

Suggestions:
 * list clusters with: kops get cluster
 * edit this cluster with: kops edit cluster reyaz.k8s.local
 * edit your node instance group: kops edit ig --name=reyaz.k8s.local nodes-ap-south-1a
 * edit your control-plane instance group: kops edit ig --name=reyaz.k8s.local control-plane-ap-south-1a




kops delete cluster --name reyaz.k8s.local --yes
