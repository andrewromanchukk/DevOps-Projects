#!/bin/bash

set -euo pipefail

LOG_FILE="/var/log/setup.log"
exec > >(tee -a "$LOG_FILE") 2>&1

echo "🔍 Detecting OS..."
OS="$(uname -a)"
DISTRO_ID="$(. /etc/os-release && echo "$ID")"

  sudo yum update -y
  sudo yum install -y awscli httpd unzip 

  echo "📥 Downloading index.html from S3..."
  aws s3 cp s3://devops-project-02-097097079/DevOps-Project-02/html-web-app/index.html /var/www/html/

  echo "🚀 Starting and enabling Apache..."
  sudo systemctl enable httpd
  sudo systemctl start httpd

  echo "📥 Installing CloudWatch Agent..."
  sudo yum install -y amazon-cloudwatch-agent

  if ! command -v aws &> /dev/null; then
    echo "📦 Installing AWS CLI v2..."
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    unzip awscliv2.zip
    sudo ./aws/install
  fi

echo "🛠️ Configuring CloudWatch Agent..."

# Common CloudWatch config
sudo mkdir -p /opt/aws/amazon-cloudwatch-agent/etc

cat <<EOF | sudo tee /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json > /dev/null
{
  "logs": {
    "logs_collected": {
      "files": {
        "collect_list": [
          {
            "file_path": "/var/log/messages",
            "log_group_name": "system-logs",
            "log_stream_name": "{instance_id}",
            "timestamp_format": "%b %d %H:%M:%S"
          }
        ]
      }
    }
  }
}
EOF

echo "🚀 Starting CloudWatch Agent..."
sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
  -a fetch-config \
  -m ec2 \
  -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json \
  -s

echo "✅ Setup completed successfully on $DISTRO_ID!"
echo "📜 Log file: $LOG_FILE"
echo "🔍 Checking Apache status..."
sudo systemctl status httpd || sudo systemctl status apache2
echo "🔍 Checking CloudWatch Agent status..."
sudo systemctl status amazon-cloudwatch-agent
echo "🔍 Checking AWS CLI version..."
aws --version
echo "🔍 Checking installed packages..."
if [[ "$DISTRO_ID" == "amzn" ]]; then
  rpm -qa | grep -E 'httpd|aws-cli|amazon-cloudwatch-agent'
fi
echo "🔍 Checking index.html content..."
if [[ -f /var/www/html/index.html ]]; then
  echo "✅ index.html exists and is not empty."
  cat /var/www/html/index.html
else
  echo "❌ index.html does not exist or is empty."
fi
echo "🔍 Checking Apache logs..."
if [[ "$DISTRO_ID" == "amzn" ]]; then
  sudo tail -n 10 /var/log/httpd/access_log
  sudo tail -n 10 /var/log/httpd/error_log
fi
echo "🔍 Checking CloudWatch Agent logs..."
if [[ "$DISTRO_ID" == "amzn" ]]; then
  sudo tail -n 10 /opt/aws/amazon-cloudwatch-agent/logs/amazon-cloudwatch-agent.log
fi
echo "🔍 Checking system logs..."
if [[ "$DISTRO_ID" == "amzn" ]]; then
  sudo tail -n 10 /var/log/messages
fi
echo "🔍 Checking network connectivity..."
ping -c 4 google.com || echo "❌ Network connectivity test failed."
echo "🔍 Checking S3 access..."
aws s3 ls s3://ed-web-config-project/ || echo "❌ S3 access test failed."
echo "🔍 Checking CloudWatch Agent configuration..."
if [[ "$DISTRO_ID" == "amzn" ]]; then
  sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a status
fi
