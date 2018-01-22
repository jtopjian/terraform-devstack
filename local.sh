sudo yum install -y git vim wget

cd
git clone https://github.com/jtopjian/dotfiles .dotfiles
pushd .dotfiles
bash create.sh
popd

source ~/.bashrc
install_go
source ~/.bashrc

go get -u github.com/terraform-providers/terraform-provider-openstack
pushd go/src/github.com/terraform-providers/terraform-provider-openstack
git remote add jtopjian https://github.com/jtopjian/terraform-provider-openstack
git fetch jtopjian
popd

go get -u github.com/gophercloud/gophercloud
pushd go/src/github.com/gophercloud/gophercloud
go get -u ./...
git remote add jtopjian https://github.com/jtopjian/gophercloud
git fetch jtopjian
popd
