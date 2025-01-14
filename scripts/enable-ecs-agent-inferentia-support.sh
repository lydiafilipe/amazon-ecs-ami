#!/usr/bin/env bash
set -ex

if [[ $AMI_TYPE != "al2inf" ]]; then
    exit 0
fi

# Copy the neuron repo
cat >/tmp/neuron.repo <<EOF
[neuron]
name=neuron
baseurl=https://yum.repos.neuron.amazonaws.com/
priority=12
gpgcheck=0
gpgkey=https://yum.repos.neuron.amazonaws.com/GPG-PUB-KEY-AMAZON-AWS-NEURON.PUB
enabled=1
keepcache=0
EOF

sudo mv /tmp/neuron.repo /etc/yum.repos.d/neuron.repo

sudo yum install -y pciutils aws-neuron-runtime-base aws-neuron-tools oci-add-hooks

NEURON_RUNTIME=/etc/docker-runtimes.d/neuron
# Add env variable to identify if inf is supported on this ami
mkdir -p /tmp/ecs
echo 'ECS_ENABLE_INF_SUPPORT=true' >>/tmp/ecs/ecs.config
sudo mv /tmp/ecs/ecs.config /var/lib/ecs/ecs.config

# Copy neuron runtime to docker runtime to be accessed as one of the runtimes supported.
if [ ! -f $NEURON_RUNTIME ]; then
    sudo cp /opt/aws/neuron/bin/oci_neuron_hook_wrapper.sh $NEURON_RUNTIME
    sudo chmod +x $NEURON_RUNTIME
fi

# Copy neuron-discovery which is a prereq for neuron to function
if [ ! -f /lib/systemd/system/neuron-discovery.service ]; then
    sudo cp /opt/aws/neuron/config/neuron-discovery.service /lib/systemd/system/
    sudo systemctl enable neuron-discovery
fi
