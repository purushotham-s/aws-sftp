#!/bin/bash -xe
groupadd sftp-upload
mkdir -p /opt/sftp/incoming
chown root:root /opt/sftp
chmod 755 /opt/sftp
chown root:sftp-upload /opt/sftp/incoming
echo -e "\n# Upload Only SFTP Config\nMatch Group sftp-upload\n\tForceCommand internal-sftp\n\tPasswordAuthentication yes\n\tChrootDirectory /opt/sftp\n\tPermitTunnel no\n\tAllowAgentForwarding no\n\tAllowTcpForwarding no\n\tX11Forwarding no" >> /etc/ssh/sshd_config
systemctl restart sshd
amazon-linux-extras install epel
yum install s3fs-fuse awscli -y
echo -e "sftp-srv-bucket-1\t/opt/sftp/incoming\tfuse.s3fs\t_netdev,allow_other,use_path_request_style,iam_role=ec2_s3_access_role,url=https://s3.us-east-1.amazonaws.com/\t0\t0" >> /etc/fstab
mount -a
pip3 install boto3
wget https://raw.githubusercontent.com/purushotham-s/aws-sftp/main/manage-sftp-users.py -O /usr/local/sbin/manage-sftp-users
chmod +x /usr/local/sbin/manage-sftp-users
