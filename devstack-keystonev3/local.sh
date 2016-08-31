cd
git clone https://github.com/jtopjian/dotfiles .dotfiles
pushd .dotfiles
bash create.sh
popd

pushd go/src/github.com/hashicorp/terraform
git remote add jtopjian https://github.com/jtopjian/terraform
git fetch jtopjian
popd

cat >> .bashrc.local <<EOF
testacc() {
  if [[ -n \$1 ]]; then
    pushd ~/go/src/github.com/hashicorp/terraform
    export OS_DOMAIN_NAME=default
    TF_LOG=DEBUG make testacc TEST=./builtin/providers/openstack TESTARGS="-run=\$1" 2>&1 | tee ~/openstack.log
    unset OS_DOMAIN_NAME
    popd
  fi
}
EOF
