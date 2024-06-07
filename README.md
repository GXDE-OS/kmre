#  <center> KMRE

## <font face="Courier New">引言
<font face="Courier New">麒麟移动运行环境，简称KMRE，旨在将丰富的Android应用生态迁移到Linux桌面操作系统上，提供桌面化的操作体验。本项目为麒麟软件维护的对KMRE支持的仓库，主要包含了Linux侧和Android侧的修改支持，其余组件直接从上游AOSP仓库拉取。

---
<BR/>


## <font face="Courier New">一.搭建Android开发环境

#### <font face="Courier New">1.1 硬件配置要求
<font face="Courier New">多核X86主机，内存最低配置要求16G，硬盘大小最低配置要求512G。追求编译速度，硬件配置可以翻倍。

#### <font face="Courier New">1.2 操作系统要求
<font face="Courier New">Ubuntu 18.04、20.04或22.04等，本项目推荐使用Ubuntu 20.04。

#### <font face="Courier New">1.3 编译环境安装和配置
###### <font face="Courier New">1.3.1 工具包安装

```bash
  sudo apt-get install git git-lfs curl python zip
```

###### <font face="Courier New">1.3.2 编译依赖包安装

```bash
  sudo apt install libgl1-mesa-dev g++-multilib flex bison gperf build-essential tofrodos python-markdown libxml2-utils xsltproc dpkg-dev libsdl1.2-dev gnupg flex bison gperf build-essential zlib1g-dev gcc-multilib g++-multilib libc6-dev-i386 lib32ncurses-dev x11proto-core-dev libx11-dev libgl1-mesa-dev libxml2-utils xsltproc unzip m4 lib32z1-dev ccache libssl-dev device-tree-compiler liblz4-tool libncurses5
```

###### <font face="Courier New">1.3.3 配置PATH环境变量

```bash
  mkdir ~/bin
  echo "PATH=~/bin:\$PATH" >> ~/.bashrc
  source ~/.bashrc
```

###### <font face="Courier New">1.3.4 下载repo脚本文件

```bash
  curl https://mirrors.tuna.tsinghua.edu.cn/git/git-repo > ~/bin/repo
  chmod a+x ~/bin/repo
  vim ~/.bashrc
  export REPO_URL='https://mirrors.tuna.tsinghua.edu.cn/git/git-repo/'
  source ~/.bashrc
```

###### <font face="Courier New">1.3.5 修改默认Python版本
  <font face="Courier New">将默认Python版本指定位Python2 ，执行如下命令

```bash
   ln -s /usr/bin/python2 /usr/bin/python  
```

###### <font face="Courier New">1.3.6 配置git账户

```bash
  git config --global user.email "xxxxxxx@kylinos.com"
  git config --global user.name "xxxxx"
```

---

<BR/>


## <font face="Courier New">二.构建Android镜像包
#### <font face="Courier New">2.1 AOSP源代码下载

```bash
  mkdir kmre-aosp-src
  cd kmre-aosp-src
  repo init -u git@gitee.com:openkylin/platform_manifest.git -b kmre-opensource-devel
  repo sync -c --no-repo-verify --no-tags --no-clone-bundle --force-sync -j8
```


<font face="Courier New">下载完成后的目录结构如下:（或者tree -L 1 kmre-aosp-src 查看）
```bash
  lixiang@kylin-pc3:/build1/lixiang/kmre-aosp-src$ ls
  Android.bp      compatibility  frameworks       Makefile          system
  art             cts            hardware         packages          test
  bionic          dalvik         kernel           pdk               toolchain
  bootable        development    kmre             platform_testing  tools
  bootstrap.bash  device         libcore          prebuilts         vendor
  build           external       libnativehelper  sdk
  lixiang@kylin-pc3:/build1/lixiang/kmre-aosp-src$
```

#### <font face="Courier New">2.2 lunch编译项目

```bash
  lixiang@kylin-pc3:/build1/lixiang/kmre-aosp-src$ source build/envsetup.sh && lunch kmre_x86_64-user

  ============================================
  PLATFORM_VERSION_CODENAME=REL
  PLATFORM_VERSION=11
  TARGET_PRODUCT=e2000
  TARGET_BUILD_VARIANT=userdebug
  TARGET_BUILD_TYPE=release
  TARGET_ARCH=arm64
  TARGET_ARCH_VARIANT=armv8-a
  TARGET_CPU_VARIANT=generic
  TARGET_2ND_ARCH=arm
  TARGET_2ND_ARCH_VARIANT=armv8-a
  TARGET_2ND_CPU_VARIANT=generic
  HOST_ARCH=x86_64
  HOST_2ND_ARCH=x86
  HOST_OS=linux
  HOST_OS_EXTRA=Linux-5.15.0-56-generic-x86_64-Ubuntu-20.04.5-LTS
  HOST_CROSS_OS=windows
  HOST_CROSS_ARCH=x86
  HOST_CROSS_2ND_ARCH=x86_64
  HOST_BUILD_TYPE=release
  BUILD_ID=RQ2A.210505.003
  OUT_DIR=out
  PRODUCT_SOONG_NAMESPACES=device/generic/goldfish device/generic/goldfish-opengl
  ============================================
```
如果编译ARM版本，则使用`lunch kmre_arm64-user`

#### <font face="Courier New">2.2 安卓源码编译
```bash
  lixiang@kylin-pc3:/build1/lixiang/kmre-aosp-src$ make img -j12
```

整个编译过程耗时较长，请耐心等待。编译成功后，可以在 out/target/product/kmre_x86_64 目录下查看到编译生成的相关镜像文件system.sfs。如果是ARM平台，则镜像路径为 out/target/product/kmre_arm64/system.sfs。如下：

```bash
lixiang@kylin-pc3:/build1/lixiang/kmre-aosp-src$ cd out/target/product/kmre_x86_64/
lixiang@kylin-pc3:/build1/lixiang/kmre-aosp-src/out/target/product/kmre_x86_64$ ls
android-info.txt       build_thumbprint.txt  gen                        obj                       symbols
apex                   clean_steps.mk        installed-files.json       obj_x86                   system
appcompat              data                  installed-files-root.json  previous_build_config.mk  system.sfs
build_fingerprint.txt  debug_ramdisk         installed-files-root.txt   recovery                  testcases
build.prop             fake_packages         installed-files.txt        root
lixiang@kylin-pc3:/build1/lixiang/kmre-aosp-src/out/target/product/kmre_x86_64$
```
----

<BR/>


## <font face="Courier New">三. 构建Linux侧KMRE安装包
以下以x86_64平台为例进行说明，推荐使用银河麒麟桌面操作系统V10 SP1、Ubuntu 20.04和Ubuntu 22.04。x86_64平台上编译生成的deb包只能安装到x86_64平台上，如果需要arm64平台上的deb包，则需要在arm64平台上对源码进行编译。

####  <font face="Courier New">3.1 下载Linux侧KMRE各模块源码包

```bash
  sudo apt-get update
  sudo apt install git devscripts
  mkdir kmre-host-src
  cd kmre-host-src
  lixiang@kylin-pc3:/build1/lixiang/kmre-host-src$ git clone https://gitee.com/openkylin/kylin-kmre-manager.git
  lixiang@kylin-pc3:/build1/lixiang/kmre-host-src$ git clone https://gitee.com/openkylin/kylin-kmre-window.git
  lixiang@kylin-pc3:/build1/lixiang/kmre-host-src$ git clone https://gitee.com/openkylin/kylin-kmre-daemon.git
  lixiang@kylin-pc3:/build1/lixiang/kmre-host-src$ git clone https://gitee.com/openkylin/kylin-kmre-emugl.git
  lixiang@kylin-pc3:/build1/lixiang/kmre-host-src$ git clone https://gitee.com/openkylin/kylin-kmre-display-control.git
  lixiang@kylin-pc3:/build1/lixiang/kmre-host-src$ git clone https://gitee.com/openkylin/kylin-kmre-image-data-x64.git
  lixiang@kylin-pc3:/build1/lixiang/kmre-host-src$ git clone https://gitee.com/openkylin/libkylin-kmre.git
  lixiang@kylin-pc3:/build1/lixiang/kmre-host-src$ git clone https://gitee.com/openkylin/kylin-kmre-apk-installer.git
  lixiang@kylin-pc3:/build1/lixiang/kmre-host-src$ git clone https://gitee.com/openkylin/kylin-kmre-make-image.git
  ......
```

<font face="Courier New">代码clone完成后，用命令查看会有如下目录:

```bash
  lixiang@kylin-pc3:/build1/lixiang$$ tree  -L 1 kmre-host-src/
  kmre-host-src/
  ├── kylin-kmre-apk-installer
  ├── kylin-kmre-daemon
  ├── kylin-kmre-display-control
  ├── kylin-kmre-emugl
  ├── kylin-kmre-image-data-x64
  ├── kylin-kmre-make-image
  ├── kylin-kmre-manager
  ├── kylin-kmre-window
  └── libkylin-kmre

  9 directories, 0 files
```

####  <font face="Courier New">3.2 生成Linux侧KMRE各模块deb包

先解决编译依赖问题，通过如下命令可以查询到对应源码包在系统上缺失的编译依赖包：
```bash
  lixiang@kylin-pc3:/build1/lixiang/kmre-host-src/libkylin-kmre$ debuild -S
   dpkg-buildpackage -us -uc -ui -S
  dpkg-buildpackage: info: 源码包 libkylin-kmre
  dpkg-buildpackage: info: 源码版本 1.3.4
  dpkg-buildpackage: info: source distribution v101
  dpkg-buildpackage: info: 源码修改者 lixiang <lixiang@kylinos.cn>
   dpkg-source --before-build .
  dpkg-checkbuilddeps: 错误: Unmet build dependencies: debhelper g++ cmake libprotobuf-dev
  dpkg-buildpackage: 警告: build dependencies/conflicts unsatisfied; aborting
  dpkg-buildpackage: 警告: (使用 -d 参数来忽略)
  debuild: fatal error at line 1182:
  dpkg-buildpackage -us -uc -ui -S failed
  lixiang@kylin-pc3:/build1/lixiang/kmre-host-src/libkylin-kmre$
```

根据缺失依赖信息，解决编译依赖问题：
```bash
  sudo apt install debhelper g++ cmake libprotobuf-dev
```

执行编译命令：
```bash
  lixiang@kylin-pc3:/build1/lixiang/kmre-host-src/libkylin-kmre$ debuild -S -sa
   dpkg-buildpackage -us -uc -ui -S -sa
  dpkg-buildpackage: info: 源码包 libkylin-kmre
  dpkg-buildpackage: info: 源码版本 1.3.4
  dpkg-buildpackage: info: source distribution v101
  dpkg-buildpackage: info: 源码修改者 lixiang <lixiang@kylinos.cn>
   dpkg-source --before-build .
   fakeroot debian/rules clean
  dh  clean --parallel
     dh_auto_clean -O--parallel
  	make -j8 clean
  make[1]: 进入目录“/build1/lixiang/kmre-host-src/libkylin-kmre”
  rm -f *.o
  rm -f KmreCore.pb.*
  rm -f libkmre.so
  make[1]: 离开目录“/build1/lixiang/kmre-host-src/libkylin-kmre”
     dh_clean -O--parallel
   dpkg-source -b .
  dpkg-source: info: using source format '3.0 (native)'
  dpkg-source: info: building libkylin-kmre in libkylin-kmre_1.3.4.tar.xz
  dpkg-source: info: building libkylin-kmre in libkylin-kmre_1.3.4.dsc
   dpkg-genbuildinfo --build=source
   dpkg-genchanges -sa --build=source >../libkylin-kmre_1.3.4_source.changes
  dpkg-genchanges: info: 上传数据中包含完整的原始代码
   dpkg-source --after-build .
  dpkg-buildpackage: info: source-only upload: Debian-native package
  Now signing changes and any dsc files...
   signfile dsc libkylin-kmre_1.3.4.dsc lixiang <lixiang@kylinos.cn>
  gpg: 警告：家目录‘/home/lixiang/.gnupg’的权限位不安全
  gpg: 警告：家目录‘/home/lixiang/.gnupg’的权限位不安全

   fixup_buildinfo libkylin-kmre_1.3.4.dsc libkylin-kmre_1.3.4_source.buildinfo
   signfile buildinfo libkylin-kmre_1.3.4_source.buildinfo lixiang <lixiang@kylinos.cn>
  gpg: 警告：家目录‘/home/lixiang/.gnupg’的权限位不安全
  gpg: 警告：家目录‘/home/lixiang/.gnupg’的权限位不安全

   fixup_changes dsc libkylin-kmre_1.3.4.dsc libkylin-kmre_1.3.4_source.changes
   fixup_changes buildinfo libkylin-kmre_1.3.4_source.buildinfo libkylin-kmre_1.3.4_source.changes
   signfile changes libkylin-kmre_1.3.4_source.changes lixiang <lixiang@kylinos.cn>
  gpg: 警告：家目录‘/home/lixiang/.gnupg’的权限位不安全
  gpg: 警告：家目录‘/home/lixiang/.gnupg’的权限位不安全

  Successfully signed dsc, buildinfo, changes files
  lixiang@kylin-pc3:/build1/lixiang/kmre-host-src/libkylin-kmre$
```

执行编译命令编译完成后，在上一级目录生成对应的deb包。所有源码都以上述方式解决依赖和编程生成deb包。


####  <font face="Courier New">3.3 将Android镜像包转换成deb包
```bash
lixiang@kylin-pc3:/build1/lixiang/kmre-host-src$ cd kylin-kmre-image-data-x86（x86的64位平台使用kylin-kmre-image-data-x86仓库，arm64平台使用kylin-kmre-image-data仓库）
lixiang@kylin-pc3:/build1/lixiang/kmre-host-src$ cd kylin-kmre-image-data-x64/amd64

拷贝之前编译生成的Android镜像文件system.sfs到当前路径下，若体系架构是arm64，则amd64变成arm64。

lixiang@kylin-pc3:/build1/lixiang/kmre-host-src/kylin-kmre-image-data-x86/amd64$ cd ../

lixiang@kylin-pc3:/build1/lixiang/kmre-host-src/kylin-kmre-image-data-x86/$ sudo make

make操作执行完成后，会在当前目录下生成kmre3_'tag_date-time'.tar，例如 kmre3_v3.0-240423.10_2024.04.23-19.11.tar，其中tag为v3.0-240423.10，date为2024.04.23，time为19.11。

lixiang@kylin-pc3:/build1/lixiang/kmre-host-src/kylin-kmre-image-data-x86/$ cp kmre3_v3.0-240423.10_2024.04.23-19.11.tar ./data/amd64/kmre-container-image.tar   (把上面的kmre3_v3.0-240423.10_2024.04.23-19.11.tar复制并改名到data/amd64/kmre-container-image.tar)

lixiang@kylin-pc3:/build1/lixiang/kmre-host-src/kylin-kmre-image-data-x86/amd64$ vim kmre.conf
[image]
repo=kmre2
tag=v3.0-240423.10

上一步操作是根据实际情况更新配置文件kmre.conf中的tag值。

lixiang@kylin-pc3:/build1/lixiang/kmre-host-src/kylin-kmre-image-data-x86/amd64$ cd ../

lixiang@kylin-pc3:/build1/lixiang/kmre-host-src/kylin-kmre-image-data-x86$ dch -n（建议把对应的tag去除v做成deb的版本号，如kylin-kmre-image-data-x64 (3.0-231108.10) xxx，然后保存）

lixiang@kylin-pc3:/build1/lixiang/kmre-host-src/kylin-kmre-image-data-x86$ debuild -S -sa  (开始编译，待编译完成，则在上一级目录下生成对应的Android镜像的deb包)
```

-----

<BR/>

##  <font face="Courier New">四.安装和启动KMRE
####  <font face="Courier New">4.1 安装deb包

```bash
  lixiang@kylin-pc3:/build1/lixiang/kmre-host-src$ sudo dpkg -i kylin-kmre-daemon_3.0.0.0-0k0.4_amd64.deb kylin-kmre-display-control_3.0.0.0-0k0.1_amd64.deb kylin-kmre-image-data_3.0-231108.10_amd64.deb kylin-kmre-manager_3.0.0.0-0k0.7_amd64.deb kylin-kmre-window_3.0.0.0-0k1.0_amd64.deb libkylin-kmre_3.0.0.0-0k0.1_amd64.deb libkylin-kmre-emugl_3.0.0.0-0k0.1_amd64.deb
```

####  <font face="Courier New">4.2 重启系统
保存用户文件后，再重启系统。

```bash
  lixiang@kylin-pc3:/build1/lixiang/kmre-host-src$ sudo reboot
```

####  <font face="Courier New">4.3 启动KMRE环境
保存用户文件后，再重启系统。

```bash
  startapp com.android.settings
```

如果KMRE环境正常，上述命令将会正常弹出安装的设置应用界面，后续可以通过麒麟软件商店安装和更新应用，或在本地双击apk包安装应用。

-----

<BR/>
