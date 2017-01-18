# To launch a base Ubunut 15.04 machine I used:
#   (FOR COMPUTE OPTIMIZED AMI)
#   starcluster start -o -s 1 -I c4.large -m ami-20435d41 imagehost
#   (FOR MEMORY OPTIMIZED AMI)
#   starcluster start -o -s 1 -I r3.large -m ami-20435d41 imagehost
# Now ssh to the instance using:
#   starcluster sshmaster imagehost

sudo locale-gen UTF-8
export LANGUAGE=en_US.UTF-8
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8
locale-gen en_US.UTF-8
dpkg-reconfigure locales

# Run Alex Gitten's script to base config the system.
wget https://github.com/github/git-lfs/releases/download/v1.1.0/git-lfs-linux-amd64-1.1.0.tar.gz
tar zxvf git-lfs-linux-amd64-1.1.0.tar.gz
cd git-lfs-1.1.0/
./install.sh
cd ..
rm -rf git-lfs-*
git clone https://github.com/rustandruin/starcluster-spark-skylark.git
mv starcluster-spark-skylark/doall.sh starcluster-spark-skylark/sge.tar.gz starcluster-spark-skylark/scimage_13.04.py .
rm -rf starcluster-spark-skylark/
chmod +x doall.sh
./doall.sh

curl -L -O https://github.com/xdata-skylark/libskylark/releases/download/v0.20/install.sh
bash install.sh -b -p /opt/libskylark

# Now create an AMI, e.g. using the command:
#   starcluster ebsimage <instance-id> <imagename>
#
# You can use 'starcluster listclusters' to find the instance-id.
#
# When you launch an instance from this AMI, libskylark should be in /opt/libskylark.
# It is useful to do:
# export PATH=/opt/libskylark/bin:${PATH}
