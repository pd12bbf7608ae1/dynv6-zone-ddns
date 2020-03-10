# dynv6-zone-ddns

[English Version](https://github.com/pdxgf1208/)

调用[dynv6](https://dynv6.com/)提供的ssh api动态更新一个域内的ip地址。脚本配置文件有丰富的可选项，以适用不同的环境。该脚本主要用于家庭局域网环境中大量设备的ipv6地址上报，可部署于任意一台Linux主机（包括可用使用shell的路由器，目前只测试了梅林）。

## 原理及适用场景

本脚本使用openssh连接到配置文件中的主机获取ip地址，随后调用dynv6的api更新指定zone及zone下主机的ip（a与aaaa记录）。

脚本在大部分Linux（包括Ubuntu、CentOS、Raspbian、梅林路由、armbian）上测试成功，被获取ip的主机包括（Linux、Windows、VMware ESXi，需要安装并开启ssh服务端）。将脚本部署于任意一台主机上，即可更新能够通过ssh连接到的主机的ip。

## 依赖安装

脚本使用ssh进行各台主机间的通信，Linux平台的软件仓库基本都有，windows平台安装参照[此文](https://winscp.net/eng/docs/guide_windows_openssh_server#windows_older)

如果ssh登录方式选择password（不推荐）,需要使用sshpass命令，在Ubuntu、Raspbian、CentOS软件仓库均可找到。其他依赖命令为curl或wget，其中curl或wget为获取公网ipv4时使用，不需要可不安装。安装于Windows平台时需要将安装目录添加至环境变量`Path`中。

## 使用脚本的大致流程

1. 注册一个[dynv6](https://dynv6.com/)账号，并创建或导入自己的域名（dynv6提供免费二级域名）;

1. 在部署该脚本的主机上生成ssh秘钥对用于与dynv6进行通信（大多数Linux平台使用ssh-keygen，梅林路由平台（ssh登录路由器后）使用dropbearkey命令），dynv6支持的秘钥类型为ed25519与ecdsa。生成后将公钥填入[此处](https://dynv6.com/keys/ssh/new);

1. 按照个人需要修改配置文件，并做好各主机间ssh通信的配置；

1. 执行脚本一次，判断是否出现配置错误；

1. 将脚本写入crontab或使用其他定时机制。

## 使用脚本的详细流程

本内容针对小白，仅以最简配置为例，熟悉ssh操作的可以直接忽略。

### SSH客户端配置（部署脚本的主机）

#### 大多数Linux发行版

测试ssh命令是否可用，否则安装：

Debian系：`apt install openssh-client`

RedHat系：`yum install openssh-client`

生成秘钥（以ecdsa为例）`ssh-keygen -t ecdsa` 然后一路回车（使用默认参数）;

查看公钥`cat ~/.ssh/id_ecdsa.pub`将输出结果复制下来并保存；

到[此处](https://dynv6.com/keys/ssh/new)填入并保存。

执行`ssh api@dynv6.com`，如果出现欢迎界面则配置成功，下面配置ssh服务端。

#### 梅林路由

本人使用的是网件R7000的koolshare梅林系统，以下操作仅供参考，一切以实际为准。

登录路由管理界面，前往系统管理-系统设置-SSH Daemon，Enable SSH选择为LAN only，端口选择22；

使用ssh登录至路由，用户名和密码与管理界面相同，生成秘钥（以ecdsa为例）`dropbearkey -t ecdsa -f ~/.ssh/id_dropbear`
