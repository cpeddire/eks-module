# step -1)
# create the node group role to allow communication between control node and the worker nodes in the node group.

#Create IAM role for EKS Node Group
resource "aws_iam_role" "eks_nodegroup_role" {
  # The name of the role
  name = "eks_nodegroup_role"


  # The policy that grants an entity permission to assume the role 
  assume_role_policy = <<POLICY
{
 "Version": "2012-10-17",
 "Statement": [
   {
     "Effect": "Allow",
     "Principal": {
       "Service": "ec2.amazonaws.com"
     },
     "Action": "sts:AssumeRole"
   }
 ]
}
POLICY
}
#we need to add 3 more policies for this role and attach it to the worker nodes 
# in order to eable the communication with control plane and provide the control on node group worker nodes.

#Amazon EKS Worker Node Policy
resource "aws_iam_role_policy_attachment" "amazon_eks_worker_node_policy" {
  #The ARN of the policy you want to apply.
  # https://github.com/SummitRoute/aws_managed_policies/blob/master/policies/AmazonEKSWorkerNodePolicy
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"

  #The role name to which this policy should apply to
  role = aws_iam_role.eks_nodegroup_role.name
}

#Amazon EKS CNI Policy
resource "aws_iam_role_policy_attachment" "amazon_eks_cni_policy" {
  #The ARN of the policy you want to apply.
  # https://github.com/SummitRoute/aws_managed_policies/blob/master/policies/AmazonEKS_CNI_Policy
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"

  #The role name to which this policy should apply to
  role = aws_iam_role.eks_nodegroup_role.name
}

#Amazon EC2_Container_Registry_Read_Only Policy
resource "aws_iam_role_policy_attachment" "amazon_ec2_container_registry_read_only" {
  #The ARN of the policy you want to apply.
  # https://github.com/SummitRoute/aws_managed_policies/blob/master/policies/AmazonEKS_CNI_Policy
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"

  #The role name to which this policy should apply to
  role = aws_iam_role.eks_nodegroup_role.name
}

# step -2)
#create the AWS EKS Node Group

resource "aws_eks_node_group" "eks-poc-nodegroup" {

  # Name of the EKS Cluster to which this worker nodes are going to be part  of 
  cluster_name = aws_eks_cluster.eks-poc.name

  # Name of the EKS Node Group
  node_group_name = "eks-poc-nodegroup"

  # Amazon Resource Name (ARN) of the IAM Role that provides permissions for the EKS 
  node_role_arn = aws_iam_role.eks_nodegroup_role.arn


  # Identifiers of EC2 Subnets to associate with the EKS Node Group.
  # These Subnets must have the following resource tag: Kubernetes.io/cluster/CLUSTER_NAME
  #(where CLUSTER_NAME is replaced with the name of the EKS Cluster).
  subnet_ids = [
    #aws_subnet.eks-privatesubnet1.id,
    subnet-0fad36f04a2bbf526,
    #aws_subnet.eks-privatesubnet2.id
    subnet-0ee4c4d2bd0a04ae0
  ]

  # Configuration blcok with scaling settings
  scaling_config {
    # Desired number of worker nodes.
    desired_size = 2

    # Maximum number of worker nodes.
    max_size = 3

    # Minimum number of worker nodes.
    min_size = 2
  }

  # Type of Amazon Machine Image (AMI) associated with the EKS Node Group.
  # Vaid values ex: AL2_x86_64, AL2_x86_64_GPU, AL2_ARM_64
  ami_type = "AL2_x86_64"

  # Type of capacity associated with the EKS Node Group
  # Valid values: ON_DEMAND, SPOT
  capacity_type = "ON_DEMAND"

  # DISK SIZE IN GIB FOR WORKER NODES

  disk_size = 50

  # Force version update if existing pods are unable to be drained due to a pod disruption budget issue.
  force_update_version = false

  # List of instance types associated with the EKS Node Group
  instance_type = ["t3.small"]

  labels = {
    role = "eks_nodegroup_role"
  }

  # kubernetes version
  #if not specified it will take the master plane version by default
  version = "1.18"

  # Ensure that IAM Role permissions are created before and deleted after EKS Node Group handling.
  # Otherwise, EKS will not be able to properly delete EC2 Instances and  Elastic Network Interfaces.
  depends_on = [
    aws_iam_role_policy_attachment.amazon_eks_worker_node_policy,
    aws_iam_role_policy_attachment.amazon_eks_cni_policy,
    aws_iam_role_policy_attachment.amazon_ec2_container_registry_read_only
  ]
  tags = {
    Name = "eks-poc-nodegroup"
  }
}