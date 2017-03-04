cd

apt-get install -y git vim
wget -O /usr/local/bin/gimme https://raw.githubusercontent.com/travis-ci/gimme/master/gimme
chmod +x /usr/local/bin/gimme
/usr/local/bin/gimme 1.8 >> .bashrc

mkdir ~/go
eval "$(/usr/local/bin/gimme 1.8)"
echo 'export GOPATH=$HOME/go' >> .bashrc
export GOPATH=$HOME/go

export PATH=$PATH:$HOME/terraform:$HOME/go/bin
echo 'export PATH=$PATH:$HOME/terraform:$HOME/go/bin' >> .bashrc
source .bashrc

go get github.com/hashicorp/terraform
go get github.com/gophercloud/gophercloud
go get golang.org/x/crypto/...
go get -u github.com/kardianos/govendor

cd
git clone https://github.com/jtopjian/dotfiles .dotfiles
pushd .dotfiles
bash create.sh
popd

pushd go/src/github.com/hashicorp/terraform
git remote add jtopjian https://github.com/jtopjian/terraform
git fetch jtopjian
popd

source ~/.bashrc
go get -u github.com/gophercloud/gophercloud
pushd go/src/github.com/gophercloud/gophercloud
git remote add jtopjian https://github.com/jtopjian/gophercloud
git fetch jtopjian
popd

cat >> .bashrc.local <<EOF
testacc() {
  if [[ -n \$1 ]]; then
    pushd ~/go/src/github.com/hashicorp/terraform
    TF_LOG=DEBUG make testacc TEST=./builtin/providers/openstack TESTARGS="-run=\$1" 2>&1 | tee ~/openstack.log
    popd
  fi
}

gophercloudtest() {
  if [[ -n \$1 ]] && [[ -n \$2 ]]; then
    export OS_TENANT_NAME=\$OS_PROJECT_NAME
    export OS_DOMAIN_NAME=default
    export OS_SHARE_NETWORK_ID=\$OS_NETWORK_ID

    pushd  ~/go/src/github.com/gophercloud/gophercloud
    go test -v -tags "fixtures acceptance" -run "\$1" github.com/gophercloud/gophercloud/acceptance/openstack/\$2 | tee ~/gophercloud.log
    popd

    unset OS_TENANT_NAME
    unset OS_DOMAIN_NAME
    unset OS_SHARE_NETWORK_ID
  fi
}
EOF

