# acme-qingcloud-lb
set and renew ssl keys to qingcloud loadbalance with [acme.sh](https://github.com/Neilpang/acme.sh)

## 1. Config

update your settings to config.json

```sh
curl -O https://raw.githubusercontent.com/fivesmallq/acme-qingcloud-lb/master/config.json
# update your settings to config.json

```

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

## 2. Run

```sh
curl https://raw.githubusercontent.com/fivesmallq/acme-qingcloud-lb/master/acme-qingcloud-lb.sh | sh
```

or

```sh
curl -O https://raw.githubusercontent.com/fivesmallq/acme-qingcloud-lb/master/acme-qingcloud-lb.sh
sh acme-qingcloud-lb.sh
```

you can use other config file also

```sh
sh acme-qingcloud-lb.sh -c other_config.json
```

## 3. Acknowledgments

acme.sh https://github.com/Neilpang/acme.sh

jq https://github.com/stedolan/jq
