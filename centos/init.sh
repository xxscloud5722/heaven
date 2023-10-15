
# 更新依赖库
CMD1="yum update -y"
echo -e "\033[1;33m$CMD1 \033[0m"
$CMD1

# 下载安装基础依赖
CMD2="yum install -y vim wget net-tools telnet telnet-server unzip"
echo -e "\033[1;33m$CMD2 \033[0m"
$CMD2

# 下载安装编译套件
CMD3="sudo yum install -y gcc make autoconf automake libtool zlib-devel openssl-devel pcre-devel libxml2-devel bzip2-devel libcurl-devel libjpeg-devel libpng-devel freetype-devel libicu-devel"
echo -e "\033[1;33m$CMD3 \033[0m"
$CMD3