# step-1)
# Let's create the role that we are going to use to create the eks cluster.
resource "aws_iam_role" "eks_cluster_role" {
  # The name of the role
  name = "eks_cluster_role"


  # The policy that grants an entity permission to assume the role
  # This role will be used by AWS EKS to create the AWS resources for Kubernetes cluster. 
  assume_role_policy = <<POLICY
{
 "Version": "2012-10-17",
 "Statement": [
   {
     "Effect": "Allow",
     "Principal": {
       "Service": "eks.amazonaws.com"
     },
     "Action": "sts:AssumeRole"
   }
 ]
}
POLICY
}
#attaching one more policy to the role we created above
resource "aws_iam_role_policy_attachment" "amazon_eks_cluster_policy" {
  #The ARN of the policy you want to apply
  # https://github.com/SummitRoute/aws_managed_policies/blob/master/policies/AmazonEKSClusterPolicy
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  #the role name ot which this pilicy should attach
  role = aws_iam_role.eks_cluster_role.name
}

# Step -2) 
# create the EKS CLuster 

#Resource: aws_eks_cluster

resource "aws_eks_cluster" "eks-poc" {
  # Name of the cluster.
  name = "eks-poc"

  # The Amazon Resource Name (ARN) of the IAM role that provides permissions for
  #The Kubernetes control plane to make calls to AWS API operations on your behalf
  role_arn = aws_iam_role.eks_cluster_role.arn

  #Desired Kubernetes master version
  version = "1.18"

  enabled_cluster_log_types = [
    "api",
    "audit",
    "authenticator",
    "controllerManager",
    "scheduler"
  ]

  vpc_config {

    # Indicates whether or not the Amazon EKS Private API server endpoint is enabled
    endpoint_private_access = false


    #Indicates wether or not the Amazon EKS public API server endpoint is enabled
    endpoint_public_access = true

    # Must be in at least two different availability zones

    subnet_ids = [
      #aws_subnet.eks-publicsubnet1.id,
      subnet-06794af9fd1203cb2,
      #aws_subnet.eks-publicsubnet2.id,
      subnet-099236eefe932518b,
      #aws_subnet.eks-privatesubnet1.id,
      subnet-0fad36f04a2bbf526,
      #aws_subnet.eks-privatesubnet2.id
      subnet-0ee4c4d2bd0a04ae0
    ]

  }

  # Ensure that IAM Role permission are created before and deleted after EKS Cluster
  #Otherwise, EKS will not be able to properly delete EKS Managed EC2 infrastructure

  depends_on = [
    aws_iam_role_policy_attachment.amazon_eks_cluster_policy,
    aws_cloudwatch_log_group.eks_logs
  ]

}

resource "aws_cloudwatch_log_group" "eks_logs" {
  name              = "eks_logs"
  retention_in_days = 30
}