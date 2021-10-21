
# EKS manager

A docker image that contains the tools required to interact with and EKS cluster.

This image contains:
* eksctl
* kubectl
* helm


## Running this image

**with AWS credentials as env vars**
```bash
export AWS_ACCESS_KEY_ID="<removed>"
export AWS_SECRET_ACCESS_KEY="<removed>"

docker run \
  -it --rm
  -e AWS_ACCESS_KEY_ID="${AWS_ACCESS_KEY_ID}" \
  -e AWS_SECRET_ACCESS_KEY="${AWS_SECRET_ACCESS_KEY}" \
  eks-manager
```
