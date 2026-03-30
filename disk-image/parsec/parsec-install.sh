#!/bin/bash
set -e

# 1. Force the frontend to be non-interactive
export DEBIAN_FRONTEND=noninteractive

# 2. Specifically tell the system to restart services without asking
# This targets the exact prompt you are seeing right now
echo "libssl1.1:amd64 libraries/restart-without-asking boolean true" | sudo debconf-set-selections
echo "libssl1.1 libraries/restart-without-asking boolean true" | sudo debconf-set-selections

# 3. Use -y and the noninteractive flag for the install commands
echo "12345" | sudo -S apt-get update
sudo apt-get install -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" \
     build-essential m4 git python python-dev gettext \
     libx11-dev libxext-dev xorg-dev unzip texinfo freeglut3-dev debconf-utils

# 4. Fix permissions (Packer's file provisioner often uploads as root)
sudo chown -R gem5:gem5 /home/gem5/parsec-benchmark

# 5. Build PARSEC locally
cd /home/gem5/parsec-benchmark

echo 'Starting Parsec Install script'
# Use sudo -u gem5 to ensure the build happens as the correct user
# sudo -u gem5 ./install.sh | tee build_log.txt
sudo -u gem5 bash -c "cd /home/gem5/parsec-benchmark && bash ./install.sh" | tee build_log.txt

# IMPORTANT: If you have the inputs already in the folder, 
# you can skip ./get-inputs (which is what was failing with wget)
# sudo -u gem5 ./get-inputs | tee get_inputs.txt
echo 'Parsec Installation Done'
