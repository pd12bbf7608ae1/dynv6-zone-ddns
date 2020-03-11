# dynv6-zone-ddns

Invoke the ssh api provided by [dynv6](https://dynv6.com/) to dynamically update the IP address in a domain. The script configuration file has a wide range of options to suit different environments. This script is mainly used to report the IPv6 addresses of a large number of devices in the home LAN environment and can be deployed on any Linux host(including routers that can use shells, only Merlin has been tested).

## Principle

This script uses openssh to connect to the host in the configuration file to obtain the IP address, and then calls the dynv6 api to update the specified zone and the IP of the host in the zone (a and aaaa records).

The script was successfully tested on many Linux release including Ubuntu, CentOS, Raspbian, Merlin Routing, armbian. The hosts that obtained the IP include Linux, Windows, VMware ESXi, and the ssh server needs to be installed and enabled. Deploying the script on any host can update the IP of the host that can be connected to via ssh.

## Dependent installation

The script uses ssh for communication between various hosts. There are basically software repositories on the Linux. For the Windows, please refer to [this article](https://winscp.net/eng/docs/guide_windows_openssh_server#windows_older);

If you choose password for ssh login (not recommended), you need to use the sshpass command, which can be found in Ubuntu, Raspbian, and CentOS software repositories;

Other dependent commands are ip, curl, or wget, where curl or wget is used to obtain the public network ipv4 address; `ip` is used to obtain ipv6, which is basically built-in. When curl and wget are installed on the Windows platform, the installation directory needs to be added to the environment variable `Path`.

## The rough flow of using the script

1. Sign up for a [dynv6](https://dynv6.com/) account and create or import your own domain name (dynv6 provides free second-level domain names);

1. Generate an ssh key pair on the host where the script is deployed to communicate with dynv6 (most Linux platforms use ssh-keygen, Merlin routing platforms (after ssh logs in to the router) use the dropbearkey command), key types supported by dynv6 is ed25519 and ecdsa. Fill the public key [here](https://dynv6.com/keys/ssh/new) after generation;

1. Modify the configuration file according to personal needs and configure the ssh communication between the hosts;

1. Execute the script once to determine whether there is a configuration error;

1. Write the script to crontab or use another timing mechanism.

## Configuration file description

### Configuration file format

The basic format is

```bash
element = value
```

This script ignores spaces and tabs, such as

```bash
host=test
    host = test
```

They are same.

When a line starts with `#`, it means that the content of the line is a comment, for example

```bash
# This is a line of comments
    #This is a line of comments
```

The configuration file uses `[value]` as the split flag, of which `[common]` is a required and unique flag. It must appear in the first one, and the rest can be customized. In addition, blank lines in the configuration file are invalid.

### `[common]` field

The content of this field is mainly responsible for setting the details of communication with dynv6 api and the setting of ipv4 / ipv6 of the zone itself

Variable | Domain | Description
------------- | -------------|-------------
dynv6_server|`dynv6.com`、`ipv4.dynv6.com`、`ipv6.dynv6.com`|Specify which domain name of `dynv6` the script uses, where`dynv6.com` is automatically selected `ipv4 / ipv6`;`ipv4.dynv6.com` is forced to use `ipv4`;`ipv6.dynv6.com` is forced to use `ipv6`
dynv6_key|file location|Defines the private key used when establishing an ssh connection with `dynv6`, empty or does not exist as the default key used by ssh
history_file|file location|Defines the file location of the script history IP record. If it is empty or does not exist, it is recorded in `$ HOME/.iphistory.log`
zone|domain name|Specify the name of the zone that needs to be updated
type|`local`、`linux`、`windows`、`esxi`、`null`|Specify which device type is used to update the ip record of `zone`, where`null` is not to use `zone` ip record
use_ipv4|`true`、`false`|The switch of `zone` ipv4 recording
use_ipv6|`true`、`false`|The switch of `zone` ipv6 recording
command_type|`wget`、`curl`|Specifies the tool used to obtain the ipv4 address. It can be empty if the ipv4 address is not enabled
devices|Device name|Specify IPv6 address of which device
ip|ip address|Set the IP or domain name of the remote host to log in, support v4 / v6; when using ipv6 local link address, you need to add the local device name
port|The port number|ssh login port
login_type|`key`、`password`|use key or password to login
key|file location|Defines the private key used when logging in to the remote host, empty or does not exist as the default key used by ssh
user|username|Defines the user name to use when logging in to the remote host. Blank is to use the current user name.
password|password|Defines the password used to log in to the remote host. This is not required when using key authentication

### host field

This field defines the relevant settings of each host under `zone`, which can be repeated.

Variable | Domain | Description
------------- | -------------|-------------
name|hostname|Specifies the name of the field under the `zone` that needs to be updated, that is, the host name
use_ipv4|`true`、`false`|The switch of `zone` ipv4 recording
use_zone_ipv4|`true`、`false`|Whether to directly use the zone's ipv4 record when enabling ipv4 record
use_ipv6|`true`、`false`|The switch of `zone` ipv6 recording
use_zone_ipv6|`true`、`false`|Whether to directly use the zone's ipv6 record when enabling ipv6 record
type|`local`、`linux`、`windows`、`esxi`、`null`|Specify which device type is used to update the ip record of `zone`, where`null` is not to use `zone` ip record
command_type|`wget`、`curl`|Specifies the tool used to obtain the ipv4 address. It can be empty if the ipv4 address is not enabled
devices|Device name|Specify IPv6 address of which device
ip|ip address|Set the IP or domain name of the remote host to log in, support v4 / v6; when using ipv6 local link address, you need to add the local device name
port|The port number|ssh login port
login_type|`key`、`password`|use key or password to login
key|file location|Defines the private key used when logging in to the remote host, empty or does not exist as the default key used by ssh
user|username|Defines the user name to use when logging in to the remote host. Blank is to use the current user name.
password|password|Defines the password used to log in to the remote host. This is not required when using key authentication

## Acknowledgments

1. Thanks to [dynv6](https://dynv6.com/) for the free domain name, resolution service and easy-to-use [api](https://dynv6.com/docs/apis);

1. Thanks to [corny](https://gist.github.com/corny) for the [script](https://gist.github.com/corny/7a07f5ac901844bd20c9), the way to obtain ipv6 in this project refers to the corny's method;

1. Thanks to [ip api](https://ip-api.com) for the free API for querying ipv4 addresses.
