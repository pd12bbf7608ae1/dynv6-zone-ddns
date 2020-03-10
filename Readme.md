# dynv6-zone-ddns

[English Version]()

调用[dynv6](https://dynv6.com/)提供的ssh api动态更新一个域内的ip地址。脚本配置文件有丰富的可选项，以适用不同的环境。该脚本主要用于家庭局域网环境中大量设备的ipv6地址上报，可部署于任意一台Linux主机（包括可用使用shell的路由器，目前只测试了梅林）。

## 原理及适用场景

本脚本使用openssh连接到配置文件中的主机获取ip地址，随后调用dynv6的api更新指定zone及zone下主机的ip（a与aaaa记录）。

脚本在大部分Linux（包括Ubuntu、CentOS、Raspbian、梅林路由、armbian）上测试成功，被获取ip的主机包括（Linux、Windows、VMware ESXi，需要安装并开启ssh服务端）。将脚本部署于任意一台主机上，即可更新能够通过ssh连接到的主机的ip。

## 依赖安装

脚本使用ssh进行各台主机间的通信，Linux平台的软件仓库基本都有，windows平台安装参照[此文](https://winscp.net/eng/docs/guide_windows_openssh_server#windows_older)；

如果ssh登录方式选择password（不推荐）,需要使用sshpass命令，在Ubuntu、Raspbian、CentOS软件仓库均可找到；

其他依赖命令为ip、curl或wget，其中curl或wget为获取公网ipv4时使用，不需要可不安装；ip为获取ipv6时使用，基本内置。curl与wget安装于Windows平台时需要将安装目录添加至环境变量`Path`中。

## 使用脚本的大致流程

1. 注册一个[dynv6](https://dynv6.com/)账号，并创建或导入自己的域名（dynv6提供免费二级域名）;

1. 在部署该脚本的主机上生成ssh密钥对用于与dynv6进行通信（大多数Linux平台使用ssh-keygen，梅林路由平台（ssh登录路由器后）使用dropbearkey命令），dynv6支持的密钥类型为ed25519与ecdsa。生成后将公钥填入[此处](https://dynv6.com/keys/ssh/new);

1. 按照个人需要修改配置文件，并做好各主机间ssh通信的配置；

1. 执行脚本一次，判断是否出现配置错误；

1. 将脚本写入crontab或使用其他定时机制。

## 使用脚本的详细流程

本内容针对小白，仅以最简配置为例，熟悉ssh操作的可以直接忽略。

### SSH客户端配置（部署脚本的主机）

只需配置一处即可

#### 大多数Linux发行版(SSH客户端)

测试ssh命令是否可用，否则安装：

Debian系：`sudo apt install openssh-client`

RedHat系：`sudo yum install openssh-client`

生成密钥（以ecdsa为例）`ssh-keygen -t ecdsa` 然后一路回车（使用默认参数）;

查看公钥`cat ~/.ssh/id_ecdsa.pub`将输出结果复制下来并保存；

到[此处](https://dynv6.com/keys/ssh/new)填入并保存。

执行`ssh api@dynv6.com`，如果出现欢迎界面则配置成功，下面配置ssh服务端。

#### 梅林路由(SSH客户端)

本人使用的是网件R7000的koolshare梅林系统，以下操作仅供参考，一切以实际为准。

登录路由管理界面，前往系统管理-系统设置-SSH Daemon，Enable SSH选择为LAN only，端口选择22；

使用ssh登录至路由，用户名和密码与管理界面相同，生成密钥（以ecdsa为例）`dropbearkey -t ecdsa -f ~/.ssh/id_dropbear`；

复制显示的Public key（即ecdsa开头的一段）并保存；

到[此处](https://dynv6.com/keys/ssh/new)填入并保存。

执行`ssh api@dynv6.com`，如果出现欢迎界面则配置成功，下面配置ssh服务端。

### SSH服务端配置（脚本查询的主机）

所有需要更新ip地址的主机都要配置，建议在路由器端设置DHCP静态分配或使用静态地址

#### 大多数Linux发行版（SSH服务端）

一般openssh-server已经安装，否则安装：

Debian系：`sudo apt install openssh-server`

RedHat系：`sudo yum install openssh-server`

使用`ssh localhost`测试是否安装成功。

进入用户家目录的`.ssh`文件夹，命令`cd ~/.ssh`（没有就创建一个并进入，命令`mkdir ~/.ssh && cd ~/.ssh`），输入命令`echo "public key" >> authorized_keys`（命令中`public key`为客户端生成的公钥，自行替换）。

从SSH客户端（上文配置的）连接该主机，测试是否可以直接登录（命令`ssh username@serviceip`），出现欢迎界面则配置成功。

#### 梅林路由(SSH服务端)

本人使用的是网件R7000的koolshare梅林系统，以下操作仅供参考，一切以实际为准。

登录路由管理界面，前往系统管理-系统设置-SSH Daemon，Enable SSH选择为LAN only，端口选择22，使用ssh连接到路由器；

进入用户家目录的`.ssh`文件夹，命令`cd ~/.ssh`（没有就创建一个并进入，命令`mkdir ~/.ssh && cd ~/.ssh`），输入命令`echo "public key" >> authorized_keys`（命令中`public key`为客户端生成的公钥，自行替换）。

从SSH客户端（上文配置的）连接路由器，测试是否可以直接登录（命令`ssh username@serviceip`），出现欢迎界面则配置成功。

#### VMware ESXi(SSH服务端)

本人使用的ESXi版本为`6.7.0-20190402001`，以下操作仅供参考，一切以实际为准（假设使用root账号）。

登录ESXi的用户界面，选择管理-服务，启动TSM-SSH并设置策略为`随主机启动和停止`；使用ssh连接至ESXi主机。

进入目录`/etc/ssh/keys-root/`，命令：`cd /etc/ssh/keys-root/`，执行`echo "public key" >> authorized_keys`（命令中`public key`为客户端生成的公钥，自行替换）。

从SSH客户端（上文配置的）连接路由器，测试是否可以直接登录（命令`ssh root@serviceip`），出现欢迎界面则配置成功。

#### Windows(SSH服务端)

##### Windows 10

进入`设置-应用-应用和功能-可选功能`，添加`OpenSSH Server`；

进入`C:\ProgramData\ssh`，用记事本打开`sshd_config`，注释掉最后两行（前面加`#`），并取消`PubkeyAuthentication yes`的注释，效果：

    PubkeyAuthentication yes

    #Match Group administrators
    #       AuthorizedKeysFile __PROGRAMDATA__/ssh/administrators_authorized_keys

进入用户目录（`C:\Users\`下以用户名命名的文件夹，中文界面为`C:\用户\`），创建`.ssh`文件夹，进入，新建txt文档并重命名为`authorized_keys`（去掉txt后缀），在该文档中粘贴客户端生成的公钥，保存退出。

打开`计算机管理-服务和应用-服务`，找到`OpenSSH Authentication Agent`与`OpenSSH SSH Server`，启动服务并设置为自动启动

从SSH客户端（上文配置的）连接Windows 10，测试是否可以直接登录（命令`ssh username@pcip`），出现欢迎界面则配置成功。

##### 其他版本Windows（我测试了Windows 7 x64）

到[Github项目页](https://github.com/PowerShell/Win32-OpenSSH/releases)下载zip包，解压到`C:\Program Files\OpenSSH`，在当前目录打开命令行，执行`powershell.exe -ExecutionPolicy Bypass -File install-sshd.ps1`；前往`控制面板-防火墙`，添加允许`sshd`的规则

进入`C:\ProgramData\ssh`，用记事本打开`sshd_config`，注释掉最后两行（前面加`#`），并取消`PubkeyAuthentication yes`的注释，效果：

    PubkeyAuthentication yes

    #Match Group administrators
    #       AuthorizedKeysFile __PROGRAMDATA__/ssh/administrators_authorized_keys

进入用户目录（`C:\Users\`下以用户名命名的文件夹，中文界面为`C:\用户\`），创建`.ssh`文件夹，进入，新建txt文档并重命名为`authorized_keys`（去掉txt后缀），在该文档中粘贴客户端生成的公钥，保存退出。

打开`计算机管理-服务和应用-服务`，找到`OpenSSH Authentication Agent`与`OpenSSH SSH Server`，启动服务并设置为自动启动

从SSH客户端（上文配置的）连接Windows，测试是否可以直接登录（命令`ssh username@pcip`），出现欢迎界面则配置成功。

### 脚本测试

下载项目中的`ddns.sh`，新建`ddns.conf`文件（在Windows端要改换行模式为LF），填入如下配置（其中双引号内容需填入实际值），除`[common]`字段为必须外，其他为可选并可自定义名称（非common即可）

    [common]
    dynv6_server = dynv6.com
    zone = "你在dynv6拥有的zone全面，如example.dynv6.net"
    type = local
    use_ipv6 = true
    use_ipv4 = true
    command_type = "curl或者wget，根据你部署该脚本主机拥有的命令决定"
    devices = "需要获取ipv6的网络设备名，留空则取找到的第一个ipv6地址"

    [esxi]
    name = esxi
    use_ipv6 = true
    use_zone_ipv6 = false
    use_ipv4 = true
    use_zone_ipv4 = true
    type = esxi
    login_type = key
    ip = “你的ESXi主机的局域网ip”
    port = 22
    user = root

    [windows10]
    name = windows10
    use_ipv6 = true
    use_zone_ipv6 = false
    use_ipv4 = true
    use_zone_ipv4 = true
    type = windows
    command_type = curl
    login_type = key
    ip = “你的windows10主机的局域网ip”
    port = 22
    user = "你的windows10主机用户名"

    [windows7]
    name = windows7
    use_ipv6 = true
    use_zone_ipv6 = false
    use_ipv4 = true
    use_zone_ipv4 = true
    type = windows
    command_type = wget
    login_type = key
    ip = “你的windows7主机的局域网ip”
    port = 22
    user = "你的windows7主机用户名"

    [linux]
    name = linux
    use_ipv6 = true
    use_zone_ipv6 = false
    use_ipv4 = true
    use_zone_ipv4 = true
    type = linux
    command_type = wget
    login_type = key
    ip = “你的linux主机的局域网ip”
    port = 22
    user = "你的linux主机用户名"

    [merlin]
    name = merlin
    use_ipv6 = true
    use_zone_ipv6 = false
    use_ipv4 = true
    use_zone_ipv4 = true
    type = linux
    command_type = wget
    login_type = key
    ip = “你的merlin路由的局域网ip”
    port = 22
    user = "你的merlin路由用户名"

以上设置将设置`zone`的ip地址为部署该脚本设备的地址，`zone`下创建`esxi windows10 windows7 linux merlin`的a、aaaa记录，a记录（ipv4地址）使用部署脚本主机的公网ipv4，aaaa记录（ipv6地址）使用各个设备的地址，可以通过例如`esxi.example.dynv6.net`的方式通过ipv6访问各个主机；在路由设置好端口映射后可以通过ipv4访问。

### 第一次测试

将`ddns.sh`与`ddns.conf`放置到需要部署该脚本的主机中，（假设放置在用户家目录下），给`ddns.sh`运行权限（命令`chmod u+x ./ddns.sh`），运行脚本（命令`./ddns.sh`），观测其输出是否正常，是否有报错等情况；如果运行成功，到[dynv6](https://dynv6.com/zones)查看是否已经完成更新（连接到dynv6服务器较为缓慢，需耐心等待）；如果失败，检测配置文件是否错误、各主机ssh配置问题等；如果确定为脚本本身的问题，可以提交issues。

### 写入crontab

在主要Linux发行版与梅林路由上都有crond服务。也可使用其他定时方式实现。

输入命令`crontab -e`打开编辑器，到[Crontab Generator](https://crontab-generator.org/)可以方便生成参数，需要执行的命令是`/home/username/ddns.sh /home/username/ddns.conf`（根据实际情况修改）。

例如，每隔15分钟执行一次，不要输出的crontab内容为：

`*/15 * * * * /home/username/ddns.sh /home/username/ddns.conf >/dev/null 2>&1`

保存后，该脚本应该就能自动执行了。
