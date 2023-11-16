set -e

JAVA_HOME="/usr/local"

function confirm() {
read -r -p "Are You Sure? [Y/n] " input
case $input in
    [yY][eE][sS]|[yY])
		echo "Yes"
		$1
		;;

    [nN][oO]|[nN])
		echo "No"
		$2
    ;;
    *)
		echo "Invalid input..."
		exit 1
		;;
esac
}

function select_java_version() {
read -r -p "Are You Sure? [8, 17, 21] " input
if [ "$input" = "8" ]; then
$1
elif [ "$input" = "17" ]; then
$2
elif [ "$input" = "21" ]; then
$3
else
echo 'Invalid input...'
fi
}

function download() {
curl -o "$2" "$1"
}

function profile() {
echo "
# JDK
export JAVA_HOME=${JAVA_HOME}/$1
export PATH=\$PATH:\$JAVA_HOME:\$JAVA_HOME/bin
" >> /etc/profile

echo "source /etc/profile"
source /etc/profile
}

function jdk8() {
echo "Installing JDK 8 ..."
# JDK 小版本
VERSION="8u382b05"
# JDK 路径
JDK_PATH="jdk8u382-b05"
download "https://mirrors.tuna.tsinghua.edu.cn/Adoptium/8/jdk/x64/linux/OpenJDK8U-jdk_x64_linux_hotspot_$VERSION.tar.gz" "./java8.tar.gz"
tar vzxf "./java8.tar.gz" -C "${JAVA_HOME}"
profile $JDK_PATH
}

function jdk17() {
echo "Installing JDK 17 ..."
# JDK 小版本
VERSION="17.0.8.1_1"
# JDK 路径
JDK_PATH="jdk-17.0.8.1+1"
download "https://mirrors.tuna.tsinghua.edu.cn/Adoptium/17/jdk/x64/linux/OpenJDK17U-jdk_x64_linux_hotspot_$VERSION.tar.gz" "./java17.tar.gz"
tar vzxf "./java17.tar.gz" -C "${JAVA_HOME}"
profile $JDK_PATH
}

function jdk21() {
echo "Installing JDK 21 ..."
}

function install_java() {
echo "Get: https://mirrors.tuna.tsinghua.edu.cn/Adoptium/"
echo "Select JDK Version ?"
select_java_version jdk8 jdk17 jdk21
}

echo "Confirm install Java?"
confirm install_java