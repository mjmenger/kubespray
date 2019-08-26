# use virtualenv to install all python requirements
# changed location of python and pip due to how python3 gets installed on macos 
VENVDIR=venv
virtualenv --python=/usr/local/bin/python3 $VENVDIR
source $VENVDIR/bin/activate
pip3 install -r requirements.txt

# prepare an inventory to test with
INV=inventory/my_lab
rm -rf ${INV}.bak &> /dev/null
mv ${INV} ${INV}.bak &> /dev/null
cp -a inventory/sample ${INV}
rm -f ${INV}/hosts.ini

# customize the vagrant environment
mkdir vagrant
cat << EOF > vagrant/config.rb
\$instance_name_prefix = "kub"
\$vm_cpus = 2
\$num_instances = 3
\$os = "centos-bento"
\$subnet = "10.0.20"
\$network_plugin = "flannel"
\$inventory = "$INV"
\$shared_folders = { 'temp/docker_rpms' => "/var/cache/yum/x86_64/7/docker-ce/packages" }
EOF

# make the rpm cache
mkdir -p temp/docker_rpms

vagrant up

# make a copy of the downloaded docker rpm, to speed up the next provisioning run
scp kub-1:/var/cache/yum/x86_64/7/docker-ce/packages/* temp/docker_rpms/

# copy kubectl access configuration in place
mkdir $HOME/.kube/ &> /dev/null
ln -s $INV/artifacts/admin.conf $HOME/.kube/config
# make the kubectl binary available
sudo ln -s $INV/artifacts/kubectl /usr/local/bin/kubectl
#or
export PATH=$PATH:$INV/artifacts
