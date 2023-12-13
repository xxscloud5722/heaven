
cat /etc/redhat-release
ip route show
lscpu

# 基础组件
yum install -y yum-utils device-mapper-persistent-data lvm2 curl vim wget
yum install -y nfs-utils
yum install -y wget

# 阿里云
# 移除
mv /etc/yum.repos.d/CentOS-* /tmp/
# 下载阿里源
curl -o /etc/yum.repos.d/CentOS-Base.repo http://mirrors.aliyun.com/repo/Centos-8.repo
# 刷新
yum makecache


# 防火墙
systemctl stop firewalld
systemctl disable firewalld

# 关闭SeLinux
setenforce 0
sed -i "s/SELINUX=enforcing/SELINUX=disabled/g" /etc/selinux/config

# 关闭虚拟内存
swapoff -a
yes | cp /etc/fstab /etc/fstab_bak
cat /etc/fstab_bak |grep -v swap > /etc/fstab


# NTP
# 安装插件
sudo dnf install chrony
# 设置服务器
sudo sed -i 's/^pool 2.centos.pool.ntp.org iburst/#&/' /etc/chrony.conf
echo -e "server ntp1.aliyun.com iburst\nserver ntp2.aliyun.com iburst\nserver ntp3.aliyun.com iburst" | sudo tee -a /etc/chrony.conf
# 启用
sudo systemctl restart chronyd
sudo systemctl enable chronyd
# 更新
chronyc tracking
# 上海时区
timedatectl set-timezone Asia/Shanghai
# 查看
date

# 加载内核
cat <<EOF | sudo tee /etc/modules-load.d/centos.conf
overlay
br_netfilter
iptable_filter
iptable_nat
EOF

echo net.bridge.bridge-nf-call-iptables = 1 > /etc/sysctl.conf
echo net.ipv4.ip_forward = 1 > /etc/sysctl.conf
sudo sysctl -p

sudo modprobe br_netfilter
sudo modprobe iptable_filter
sudo modprobe iptable_nat

echo 1 > /proc/sys/net/bridge/bridge-nf-call-iptables
echo 1 > /proc/sys/net/ipv4/ip_forward


# 输出检查
cat /etc/redhat-release
ip route show
lscpu
date