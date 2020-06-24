sudo wget -O /usr/local/bin/gimme https://raw.githubusercontent.com/travis-ci/gimme/master/gimme
sudo chmod +x /usr/local/bin/gimme
gimme 1.12 >> .bashrc

mkdir ~/go
eval "$(/usr/local/bin/gimme 1.12)"
echo 'export GOPATH=$HOME/go' >> .bashrc
export GOPATH=$HOME/go

export PATH=$PATH:$HOME/terraform:$HOME/go/bin
echo 'export GO111MODULE=on' >> .bashrc
echo 'export PATH=$PATH:$HOME/terraform:$HOME/go/bin' >> .bashrc
source .bashrc

cd
git clone https://github.com/jtopjian/dotfiles .dotfiles
pushd .dotfiles
bash create.sh
popd

git clone https://github.com/terraform-providers/terraform-provider-openstack
pushd terraform-provider-openstack
git remote add jtopjian https://github.com/jtopjian/terraform-provider-openstack
git fetch jtopjian
popd

git clone https://github.com/gophercloud/gophercloud
pushd gophercloud
git remote add jtopjian https://github.com/jtopjian/gophercloud
git fetch jtopjian
popd
