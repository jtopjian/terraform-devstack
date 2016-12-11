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
    pushd  ~/go/src/github.com/gophercloud/gophercloud
    go test -v -tags "fixtures acceptance" -run "\$1" github.com/gophercloud/gophercloud/acceptance/openstack/\$2 | tee ~/gophercloud.log
    popd
  fi
}
EOF
