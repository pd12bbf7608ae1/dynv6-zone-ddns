# dynv6-zone-ddns

[English Version](https://github.com/pdxgf1208/dynv6-zone-ddns/blob/master/Readme_eng.md)

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

## 配置文件说明

以下内容为配置文件格式各字段的作用，可以实现高度的自定义。

### 配置文件格式

配置文件仿照Linux中常见配置文件的格式，其基本格式为

```bash
element = value
```

本脚本忽略空格与制表符，例如

```bash
host=test
    host = test
```

两行没有区别。

当一行以`#`开头时，表示该行内容为注释，例如

```bash
# 这是一行注释
    #这也是一行注释
```

配置文件以`[value]`为分割标志，其中`[common]`为必须且特有的标志，需出现在第一个，其余可自定义；此外，配置文件中空行无效。

### `[common]`字段

该字段内容主要负责设置与dynv6 api通信的细节以及对`zone`本身的ipv4/ipv6的设定

变量|定义域|说明
------------- | -------------|-------------
dynv6_server|`dynv6.com`、`ipv4.dynv6.com`、`ipv6.dynv6.com`|指定脚本使用`dynv6`的哪个域名，其中`dynv6.com`为自动选择`ipv4/ipv6`；`ipv4.dynv6.com`为强制走`ipv4`；`ipv6.dynv6.com`为强制走`ipv6`
dynv6_key|主机内文件位置|定义与`dynv6`建立ssh连接时使用的私钥，空或不存在为使用ssh默认秘钥
history_file|主机内文件位置|定义记录脚本历史ip记录的文件位置，空或不存在则记录在`$HOME/.iphistory.log`
zone|域名|指定需要更新的`zone`名称
type|`local`、`linux`、`windows`、`esxi`、`null`|指定使用哪种设备的ip更新`zone`的ip记录，其中`null`为不使用`zone`ip记录
use_ipv4|`true`、`false`|开启`zone`ipv4记录的开关
use_ipv6|`true`、`false`|开启`zone`ipv6记录的开关
command_type|`wget`、`curl`|指定获取ipv4地址使用的工具，不启用ipv4地址时可以为空
devices|设备名|指定获取哪个设备的ipv6地址，`linux`使用`ip`查看（例如设备`eth0`），`windows`到网络适配器中查看，建议使用中文（可重命名，例如设备`Enternet`），`esxi`在`网络-VMkernel`中查看（例如`vmk0`），为空则默认选取第一个可用的地址
ip|ip地址或域名|指定登录远程主机的ip或域名，支持v4/v6；在使用ipv6本地链路地址时需要加上使用的本机设备名，如`FE80::C800:EFF:FE74:8%eth0`
port|端口号|指定登录远程主机的端口号，空则默认使用22端口
login_type|`key`、`password`|指定登录远程主机使用的类型，无需登录时可以为空
key|主机内文件位置|定义登录远程主机时使用的私钥，空或不存在为使用ssh默认秘钥
user|用户名|定义登录远程主机时使用的用户名，空为使用当前用户名
password|密码|定义登录远程主机使用的密码，当使用`key`认证时无需此项

### 主机字段

该字段定义`zone`下各台主机的相关设置，可以重复

变量|定义域|说明
------------- | -------------|-------------
name|主机名|指定需要更新的`zone`下字段的名称，即主机名
use_ipv4|`true`、`false`|开启ipv4记录的开关
use_zone_ipv4|`true`、`false`|开启ipv4记录时是否直接使用`zone`的ipv4记录
use_ipv6|`true`、`false`|开启ipv6记录的开关
use_zone_ipv6|`true`、`false`|开启ipv6记录时是否直接使用`zone`的ipv6记录
type|`local`、`linux`、`windows`、`esxi`、`null`|指定使用哪种设备的ip更新`zone`的ip记录，其中`null`为不使用该主机名ip记录
command_type|`wget`、`curl`|指定获取ipv4地址使用的工具，不启用ipv4地址时可以为空
devices|设备名|指定获取哪个设备的ipv6地址，`linux`使用`ip`查看（例如设备`eth0`），`windows`到网络适配器中查看，建议使用中文（可重命名，例如设备`Enternet`），`esxi`在`网络-VMkernel`中查看（例如`vmk0`），为空则默认选取第一个可用的地址
ip|ip地址或域名|指定登录远程主机的ip或域名，支持v4/v6；在使用ipv6本地链路地址时需要加上使用的本机设备名，如`FE80::C800:EFF:FE74:8%eth0`
port|端口号|指定登录远程主机的端口号，空则默认使用22端口
login_type|`key`、`password`|指定登录远程主机使用的类型，无需登录时可以为空
key|主机内文件位置|定义登录远程主机时使用的私钥，空或不存在为使用ssh默认秘钥
user|用户名|定义登录远程主机时使用的用户名，空为使用当前用户名
password|密码|定义登录远程主机使用的密码，当使用`key`认证时无需此项

## 使用中的一些提示

+ 对于大多数应用，很多设备公用一个ipv4公网地址，此时`zone`下各`host`只需使用`zone`的ipv4地址即可（`use_zone_ipv4=true`），无需重复获取。

+ 脚本在获取Windows设备ip时默认获取的shell为cmd，当用户修改获取的shell为powershell时，需要自行更改脚本适配（将发送到Windows执行命令中的`&`更改为`;`）。

+ 建议对于各`host`，使用静态ipv4以便于脚本与之联系。当无法使用静态ipv4时（例如电信的光猫在路由状态无法设置静态DHCP分配），可以考虑使用ipv6本地链路地址（与网卡MAC唯一对应）进行通信。

+ 本脚本的主要应用场景是多台主机需要动态域名解析的环境（主要针对各台主机的ipv6），如果只有单台主机的动态域名解析需求，建议使用dynv6给出的[脚本](https://gist.github.com/corny/7a07f5ac901844bd20c9)，配置更加简洁。

+ 由于脚本的工作原理是登录各台主机获取信息，所以当部署本脚本的主机被攻破后，可能会导致黑客获取到登录其他主机的私钥，导致更大的损失。建议加强部署本脚本主机的安全设置，并在配置登录其他主机中使用独立账号，以降低安全风险。本人对使用此脚本造成的损失概不负责。

+ 由于dynv6服务器位于国外，直连的速度很慢，甚至失败，有梯子的用户可以考虑在本地部署一个socks5代理服务，连接到dynv6服务器时使用代理。作者使用[v2ray](https://www.v2ray.com)（需要翻墙）在本地开放socks端口，使用购买的机场连接到dynv6服务器，快很多。有需求的用户可以参考[此文](https://kanda.me/2019/07/01/ssh-over-http-or-socks/)，并更改脚本的函数`zone_ipv4_update`、`zone_ipv6_update`、`host_ipv4_update`、`host_ipv6_update`。

## 脚本尚存的不足

+ dynv6提供的ssh api似乎无法一次输入多个命令，因此在需要更新大量信息时，要建立很多次ssh连接。如果有方法可以一次执行多条命令，请提交issue或者fork。

+ 由于作者没有群晖、威联通等专业NAS设备，没有对此进行测试，估计这类设备可以归类到Linux中。如有测试成功的，欢迎反馈。

+ 由于作者没有macOS设备，本脚本没有获取macOS主机ip的功能，欢迎各位帮忙适配macOS。

## 下一步计划

+ 打算适配其他dns服务商提供的api。

## 致谢

1. 感谢[dynv6](https://dynv6.com/)提供的免费域名、解析服务和易用的[api](https://dynv6.com/docs/apis)；

1. 感谢[corny](https://gist.github.com/corny)提供的[脚本](https://gist.github.com/corny/7a07f5ac901844bd20c9)，本项目中获取ipv6的方式参考了corny的方法；

1. 感谢[ip api](https://ip-api.com)提供的免费查询ipv4地址的api；

1. 感谢[koolshare](https://koolshare.cn/)论坛各位大佬制作的梅林固件。

## 许可

这个项目是在MIT许可下进行的 - 查看 [LICENSE](https://github.com/pdxgf1208/dynv6-zone-ddns/blob/master/LICENSE) 文件获取更多详情。
