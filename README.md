# acme-qingcloud-lb
set and renew ssl keys to qingcloud lb with acme

## Config

put your set to config.json like example

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
