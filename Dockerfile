FROM jenkins/inbound-agent:alpine as jnlp

FROM jenkins/agent:latest-jdk17

ARG version
LABEL Description="This is a base image, which allows connecting Jenkins agents via JNLP protocols" Vendor="Jenkins project" Version="$version"

ARG user=jenkins

USER root

COPY --from=jnlp /usr/local/bin/jenkins-agent /usr/local/bin/jenkins-agent

RUN chmod +x /usr/local/bin/jenkins-agent && \
    ln -s /usr/local/bin/jenkins-agent /usr/local/bin/jenkins-slave

ARG TF_VERSION=1.3.4
ARG AWS_IAM_AUTH_VERSION=0.5.7

# Update packages and install general dependencies
RUN apt-get update && apt-get upgrade -y
RUN apt-get install -y gnupg software-properties-common curl wget git

# install terraform
RUN apt-get update && apt-get install -y gnupg software-properties-common curl wget git \
    && wget -qO - terraform.gpg https://apt.releases.hashicorp.com/gpg | gpg --dearmor -o /usr/share/keyrings/terraform-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/terraform-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" > /etc/apt/sources.list.d/terraform.list \
    && apt-get update \
    && apt-get install terraform=${TF_VERSION}
RUN which terraform
RUN terraform version

# install kubectl
RUN snap install kubectl --channel=1.22/stable --classic
RUN which kubectl

# install aws cli
RUN apt-get install -y unzip less
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
RUN unzip -q awscliv2.zip
RUN ./aws/install
RUN which aws

# Install aws cli ssm
RUN curl "https://s3.amazonaws.com/session-manager-downloads/plugin/latest/ubuntu_64bit/session-manager-plugin.deb" -o "session-manager-plugin.deb"
RUN dpkg -i session-manager-plugin.deb

# Install aws-iam-authenticator
RUN curl -L -o aws-iam-authenticator https://github.com/kubernetes-sigs/aws-iam-authenticator/releases/download/v${AWS_IAM_AUTH_VERSION}/aws-iam-authenticator_${AWS_IAM_AUTH_VERSION}_linux_amd64
RUN chmod +x ./aws-iam-authenticator && cp aws-iam-authenticator /usr/bin/aws-iam-authenticator
RUN which aws-iam-authenticator

# Output installed versions
RUN aws --version
RUN kubectl version --client=true
RUN terraform version
RUN aws-iam-authenticator version

USER ${user}

ENTRYPOINT ["/usr/local/bin/jenkins-agent"]
