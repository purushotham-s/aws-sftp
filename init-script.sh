#!/bin/bash -xe

# Script to setup upload only SFTP host with S3 Backend

# Create a common group for SFTP users
groupadd sftp-upload

# Create a directory for SFTP uploads and grant permission to allow SFTP chroot
mkdir -p /opt/sftp/incoming
chown root:root /opt/sftp
chmod 755 /opt/sftp
chown root:sftp-upload /opt/sftp/incoming

# Config allows password auth to users on sftp-upload group, chains them to /opt/sftp. SFTP users
# will not be able to login through SSH. 
echo -e "\n# Upload Only SFTP Config\nMatch Group sftp-upload\n\tForceCommand internal-sftp\n\tPasswordAuthentication yes\n\tChrootDirectory /opt/sftp\n\tPermitTunnel no\n\tAllowAgentForwarding no\n\tAllowTcpForwarding no\n\tX11Forwarding no" >> /etc/ssh/sshd_config
systemctl restart sshd

# s3fs-fuse provides drivers to mount S3 buckets
amazon-linux-extras install epel
yum install s3fs-fuse awscli -y

# Adding /etc/fstab entry to keep the mount persistent
echo -e "sftp-srv-bucket-1\t/opt/sftp/incoming\tfuse.s3fs\t_netdev,allow_other,use_path_request_style,iam_role=ec2_s3_access_role,url=https://s3.us-east-1.amazonaws.com/\t0\t0" >> /etc/fstab
mount -a

# Fetches script to manage SFTP users and API Keys
pip3 install boto3
wget https://raw.githubusercontent.com/purushotham-s/aws-sftp/main/manage-sftp-users.py -O /usr/local/sbin/manage-sftp-users
chmod +x /usr/local/sbin/manage-sftp-users
