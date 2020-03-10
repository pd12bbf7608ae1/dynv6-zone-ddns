# dynv6-zone-ddns

[English Version](https://github.com/pdxgf1208/)

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

以上设置将设置`zone`的ip地址为部署该脚本设备的地址，`zone`下创建`esxi windows10 windows7 linux merlin`的a、aaaa记录，a记录（ipv4地址）使用部署脚本主机的公网ipv4，aaaa记录（ipv6地址）使用各个设备的地址，可以通过例如`esxi.example.dynv6.net`的方式访问各个主机。

### 修改脚本的参数

在脚本文件前有一系列的参数设置，后面有详细说明，至少需要修改：
- picturepath (截图保存目录)
- logpath (信息保存目录)

这两个选项，以便脚本保存相关信息，默认两个目录均为：

`$HOME/Pictures/VedioCapture`

请按照个人的习惯进行修改，并保证脚本使用者对该目录有写入的权限。

### 将脚本保存位置添加到 PATH 变量中并增加执行权限

这有利于从任何文件夹方便调用本脚本。

### 去 sm.ms 图床注册个账号

虽然使用匿名上传也是可行的，但上传后会难以对图片进行管理（需要查看相关日志）。
注册完毕后在 https://sm.ms/home/apitoken 中生成 token 填入 token 变量中以便将文件保存在你的账户下。

## 用法

假定脚本文件放入`$PATH`目录下并命名为`videotools.sh`

`videotools.sh <video file path> [options...]`

或者

`videotools.sh [options...] <video file path>`

第二种用法在一些系统中会失效（脚本无法获取最后一个参数）。

### 参数列表

|选项|描述|
| ------------ | ------------ |
|`-h`|打印帮助信息|
|`-j`|将输出的 png 图像转换为 jpg 格式（无该选项则仅输出 png ）|
|`-m <横向数量>x<纵向数量>`|指定将多个截图合并到一张图片的排列格式（不指定则不输出）|
|`-M <时间>`|指定手动截图的时间参数,格式同 `ffmpeg` 时间格式|
|`-n <图片数量>`|指定输出单独截图的数目（不指定则不输出）|
|`-s`|屏蔽视频信息输出（仅截图）|
|`-u`|将截图上传至 sm.ms 图床（`-j`存在时上传 jpg 格式，否则为 png 格式）|
|`-w <像素数量>`|指定`-m`参数中单张截图的宽度，不指定则使用视频原始分辨率|
|`-W <像素数量>`|指定`-M`与`-n`参数中单张截图的宽度，不指定则使用视频原始分辨率|

### 例子

`videotools.sh <video file path>`

输出视频文件的信息并保存。

`videotools.sh <video file path> -M 00:10:10 -sjuW 1280`

屏蔽视频文件的信息输出，在时间`00:10:00`处以`1280`宽的分辨率截图，转换为 jpg 格式并上传 sm.ms 图床。

`videotools.sh <video file path> -m 4x4 -suw 500`

屏蔽视频文件的信息输出，以`4x4`的格式生成缩略图，单张截图宽`500`，并将生成图片上传 sm.ms 图床。

`videotools.sh <video file path> -n 3 -m 3x3 -ujw 500`

输出视频文件的信息并保存，以视频分辨率生成3张独立的截图，以`3x3`的格式生成缩略图，单张截图宽`500`，并将生成图片上传 sm.ms 图床。

### 常数列表

脚本执行前有一些常数的设置，以下为它们的作用。

|选项|描述|
| ------------ | ------------ |
|`picturepath`|截图保存位置|
|`logpath`|视频信息和截图上传信息保存位置|
|`randomshift_flag`|自动选取时间时是否加入随机偏移，为`0`或不存在使用固定值，影响`-n`与`-m`参数生成的截图|
|`logofile`|缩略图中的logo文件位置，留空为不使用logo|
|`gap`|缩略图中的间隙参数，单位像素|
|`comment`|缩略图中的Comment字段|
|`font`|缩略图中顶端说明文字字体|
|`fontsize`|缩略图中顶端说明文字字号|
|`fontcolor`|缩略图中顶端说明文字颜色|
|`font_shadowcolor`|缩略图中顶端说明文字阴影颜色|
|`font_shadowx`|缩略图中顶端说明文字阴影x偏移|
|`font_shadowy`|缩略图中顶端说明文字阴影y偏移|
|`require_timestamp`|缩略图中时间戳开关，非`1`或者不存在为不生成|
|`timestamp_fontcolor`|缩略图中时间戳文字颜色|
|`timestamp_shadowcolor`|缩略图中时间戳文字阴影颜色|
|`timestamp_font`|缩略图中时间戳文字字体|
|`timestamp_fontsize`|缩略图中时间戳文字字号|
|`timestamp_shadowx`|缩略图中时间戳文字阴影x偏移|
|`timestamp_shadowy`|缩略图中时间戳文字阴影y偏移|
|`timestamp_x`|缩略图中时间戳文字位于该截图x位置的比例，如`0.5`在截图中央|
|`timestamp_y`|缩略图中时间戳文字位于该截图y位置的比例，如`0.5`在截图中央|
|`backgroundcolor`|缩略图背景颜色|
|`token`|`sm.ms`图床`apikey`,留空使用匿名上传|

其中有关颜色的定义请参考[FFmpeg颜色定义](https://www.ffmpeg.org/ffmpeg-all.html#Color "FFmpeg颜色定义")，有关字体相关参数具体说明请参考[FFmpeg drawtext参数列表](https://www.ffmpeg.org/ffmpeg-all.html#drawtext-1 "FFmpeg drawtext参数列表")。

## 使用注意事项

1. 使用`-m`参数需注意，生成缩略图分辨率过大容易导致内存不足而失败；
1. 使用过旧版本`FFmpeg`可能导致脚本部分功能失效；
1. 使用上传功能时建议搭配`-j`参数使用，以免因生成`png`格式图片过大，超过`sm.ms`图床上传限制而失败；
1. 使用上传功能时请遵守`sm.ms`[使用协议](https://sm.ms/about "使用协议")。

## 致谢

1. 感谢[FFmpeg](https://www.ffmpeg.org/ "FFmpeg")提供的强大视频处理工具和详尽的[Wiki](https://trac.ffmpeg.org/wiki "Wiki")文档；
1. 感谢[MediaInfo](https://mediaarea.net/en/MediaInfo "MediaInfo")提供的视频信息提取工具;
1. 感谢[sm.ms图床](https://sm.ms/ "sm.ms图床")提供的免费、可靠服务和易用的[API](https://doc.sm.ms/ "API")；
1. 感谢[中国科学技术大学开源软件镜像站](https://mirrors.ustc.edu.cn/ "中国科学技术大学开源软件镜像站")提供的软件镜像服务和帮助文档。

## 许可

这个项目是在MIT许可下进行的 - 查看 [LICENSE](https://github.com/pdxgf1208/ffmpeg-videotools/blob/master/LICENSE "LICENSE") 文件获取更多详情。

