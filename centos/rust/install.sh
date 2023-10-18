#!/usr/bin/env bash
set -e

# 安装Clang
echo -e "\033[1;33m Clang $1 \033[0m"
sudo yum install clang wget -y

if [ -f "./rust.sh" ];then
  echo "./rust.sh"
else
  # 安装Rust (国内源)
  echo -e "\033[1;33m Install Rust .. $1 \033[0m"
  export RUSTUP_DIST_SERVER=https://mirrors.ustc.edu.cn/rust-static
  export RUSTUP_UPDATE_ROOT=https://mirrors.ustc.edu.cn/rust-static/rustup
  echo -e "\033[1;33m get https://sh.rustup.rs .. $1 \033[0m"
  wget -O rust.sh https://sh.rustup.rs
fi
echo -e "\033[1;33m Start install $1 \033[0m"
chmod +x rust.sh
source rust.sh


# 切换依赖源
mkdir -p ~/.cargo

echo -e "\033[1;33m Set cargo Config \033[0m"
cat > ~/.cargo/config <<EOF
[source.crates-io]
replace-with = 'rsproxy-sparse'
[source.rsproxy]
registry = "https://rsproxy.cn/crates.io-index"
[source.rsproxy-sparse]
registry = "sparse+https://rsproxy.cn/index/"
[registries.rsproxy]
index = "https://rsproxy.cn/crates.io-index"
[net]
git-fetch-with-cli = true
EOF