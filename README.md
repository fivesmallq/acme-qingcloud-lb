# acme-qingcloud-lb
set and renew ssl keys to qingcloud lb with acme

## issue domain

put your domain to domain.txt, then 

```sh
./issue.sh
```

## update qingcloud lb

set your Qingcloud API Key to qingcloud_config.yaml, then 

```sh
./qingcloud_lb.sh -lb $lb_id -lbl $lbl_id  -f ./qingcloud_config.yaml
```
