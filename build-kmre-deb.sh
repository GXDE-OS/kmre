#!/bin/bash
# Kmre 构建脚本
echo ">>>>> 检测是否满足构建/运行要求"
#cd "$(dirname $0)"
if [[ ! -f /usr/bin/apt ]]; then
    echo 暂只支持 Debian 及其衍生发行版（如 GXDE、Ubuntu）
    exit 1
fi
# 判断发行版
arch=$(dpkg --print-architecture)
kernel_version=$(uname -r)
amd64_array=(
    https://mirrors.sdu.edu.cn/GXDE/gxde-os/bixie/k/kylin-kmre-image-data-x64/kylin-kmre-image-data-x64_3.0-231108.10_amd64.deb
    https://mirrors.sdu.edu.cn/GXDE/gxde-os/bixie/k/kylin-kmre-image-update-x64/kylin-kmre-image-update-x64_3.0-231108.10+231108.12_amd64.deb
)
arm64_array=(
    https://mirrors.sdu.edu.cn/GXDE/gxde-os/bixie/k/kylin-kmre-image-data/kylin-kmre-image-data_3.0-240731.10_arm64.deb
    https://mirrors.sdu.edu.cn/GXDE/gxde-os/bixie/k/kylin-kmre-image-update-kunpeng920/kylin-kmre-image-update-kunpeng920_3.0-240731.10+240731.11_arm64.deb
    https://mirrors.sdu.edu.cn/GXDE/gxde-os/bixie/k/kylin-kmre-image-update/kylin-kmre-image-update_3.0-240731.10+240731.11_arm64.deb
)
kmre_git_repo=(
    https://gitee.com/GXDE-OS/kylin-kmre-emugl
    https://gitee.com/GXDE-OS/kylin-kmre-display-control
    https://gitee.com/GXDE-OS/libkylin-kmre
    https://gitee.com/GXDE-OS/kylin-kmre-manager
    https://gitee.com/GXDE-OS/kylin-kmre-daemon
    https://gitee.com/GXDE-OS/kylin-kmre-window
    https://gitee.com/GXDE-OS/kylin-kmre-apk-installer
    https://gitee.com/GXDE-OS/kylin-kmre-modules-dkms
    https://gitee.com/GXDE-OS/kmre
)
echo 当前CPU架构：$arch
case $arch in
    "amd64")
        image_array=${amd64_array[@]}
    ;;
    "arm64")
        image_array=${arm64_array[@]}
    ;;
    *)
        echo 不支持该架构
        exit 1
    ;;
esac

if [[ ! -f /usr/src/linux-headers-${kernel_version}/Module.symvers ]]; then
    echo 无法找到 linux-headers 包，无法继续，需安装后才可进行后续操作
    echo 参考包名：linux-headers-${kernel_version}
    exit 1
fi
# 检测内核是否有启用必要的 patch
# https://gitee.com/GXDE-OS/gxde-kernel/blob/master/patch/export-symbols-needed-by-android-drivers.patch
# 或者 https://salsa.debian.org/kernel-team/linux/-/blob/debian/latest/debian/patches/debian/export-symbols-needed-by-android-drivers.patch
grep can_nice /usr/src/linux-headers-$(uname -r)/Module.symvers
if [[ $? != 0 ]]; then
    echo Kmre 暂不支持该内核，您可以尝试如下操作：
    echo "  - 更换受支持的内核，当前支持 Debian 的主线内核"
    echo "  - 手动编译内核，同时要开启 Binder 选项以及合并以下 Patch（二选一）"
    echo "    + https://gitee.com/GXDE-OS/gxde-kernel/blob/master/patch/export-symbols-needed-by-android-drivers.patch"
    echo "    + https://salsa.debian.org/kernel-team/linux/-/blob/debian/latest/debian/patches/debian/export-symbols-needed-by-android-drivers.patch"
    exit 1
fi
# 开始构建
set +e
mkdir -pv build-temp
cd build-temp
echo ">>>>> 安装所需基础依赖"
sudo apt update
sudo apt install git aria2 dpkg-dev fakeroot -y --allow-downgrades
echo ">>>>> 下载 Android Image"
for i in ${image_array[@]}; do
    aria2c -x 16 -s 16 $i -c
done
echo ">>>>> 构建 Kmre 软件包"
for i in ${kmre_git_repo[@]}; do
    repo_name=$(basename $i)
    echo ">>> 构建包 $repo_name"
    echo ">> 拉取 $repo_name 源码"
    git clone $i --depth=1
    echo ">> 安装 $repo_name 依赖包"
    cd $repo_name
    rm ../*dbg*.deb -v
    sudo apt install ../*.deb -y --allow-downgrades
    sudo apt build-dep . -y --allow-downgrades
    echo ">> 构建 $repo_name deb 包"
    dpkg-buildpackage -b
    cd ..
done
echo ">>>>> 安装 kmre"
sudo apt install ./*.deb -y --allow-downgrades
echo 安装完成！重启后即可生效
