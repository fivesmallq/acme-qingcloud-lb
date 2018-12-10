# acme-qingcloud-lb
set and renew ssl keys to qingcloud loadbalance with [acme.sh](https://github.com/Neilpang/acme.sh)
## Install

1. acme.sh and qingcloud-cli

```sh
curl  https://get.acme.sh | sh
sudo pip install qingcloud-cli
```
2. jq

Linux:

```sh
JQ=/usr/bin/jq
curl https://stedolan.github.io/jq/download/linux64/jq > $JQ && chmod +x $JQ
ls -la $JQ
```

Mac:
```sh
brew install jq
```


## Config

put your settings to config.json

```json
{
	"qy_access_key_id":"QINGCLOUDACCESSKEYID",
	"qy_secret_access_key":"QINGCLOUDSECRETACCESSKEYEXAMPLE",
	"zone":"pek3b",
	"loadbalance_id":"lb-xu9ckdzm",
	"loadbalance_listener_id":"lbl-7zk5p75d",
	"domains":[
		"*.example.com",
		"*.prod.example.com",
		"*.dev.example.com"
	],
	"dns_type":"dns_dp",
	"dns_env_shell":"export DP_Id=example; export DP_Key=example"
}
```

## Run


```sh
sh update.sh
```
