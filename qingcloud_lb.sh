#!/bin/bash
POSITIONAL=()
while [[ $# -gt 0 ]]
do
key="$1"

case $key in
    -lb|--loadbalance)
    LB="$2"
    shift # past argument
    shift # past value
    ;;
    -lbl|--listener)
    LBL="$2"
    shift # past argument
    shift # past value
    ;;
    -f|--config)
    QINGCLOUD_CONFIG="$2"
    shift # past argument
    shift # past value
    ;;
   *)    # unknown option
    POSITIONAL+=("$1") # save it in an array for later
    shift # past argument
    ;;
esac
done
set -- "${POSITIONAL[@]}" # restore positional parameters

echo LB = "${LB}"
echo LBL = "${LBL}"
echo CLEAR_ALL = "${CLEAR_ALL}"
echo QINGCLOUD_CONFIG = "${QINGCLOUD_CONFIG}"

if [[ -z $LB ]]; then
    echo "loadbalance id is Required:"
    exit 0 
fi
if [[ -z $LBL ]]; then
    echo "loadbalance listener id is Required:"
    exit 0
fi
file="domain.txt"
sslIds=''
while IFS= read line
do
        echo "create ssl key for domain $line"
        domain=$line
        keyFile=~/.acme.sh/$domain/$domain.key
        fullchainFile=~/.acme.sh/$domain/fullchain.cer
        DATE=`date +%Y%m%d`
        # 创建https证书，记录id
        json=`qingcloud iaas create-server-certificate -N $domain-$DATE -C "$fullchainFile" -K "$keyFile" -f $QINGCLOUD_CONFIG`
        echo $json
		sslId=`echo $json | jq -r .server_certificate_id`
        sslIds="${sslIds},$sslId"
        echo "create ssl key success for $domain"
done <"$file"
sslIds=`echo $sslIds | cut -c 2-`
old_ssl_id=`qingcloud iaas describe-loadbalancer-listeners -l $LB -s $LBL -f qingcloud_config.yaml | jq -r '.loadbalancer_listener_set[0].server_certificate_id | join(",")'`
echo "set server_certificate_id $sslIds to loadbalance $LB with loadbalance listener $LBL"
## 更新lb监听器设置, 应用设置
qingcloud iaas modify-loadbalancer-listener-attributes -s $LBL -S $sslIds -f $QINGCLOUD_CONFIG
qingcloud iaas update-loadbalancers -l $LB -f $QINGCLOUD_CONFIG
echo "old ssl id:$old_ssl_id"
echo "waitting for change"

lb_status=`qingcloud iaas describe-loadbalancers -l $LB -f $QINGCLOUD_CONFIG | jq -r '.loadbalancer_set[0].status'`
while true ; do
	echo "loadbalancer status:$lb_status"
    if [ "$lb_status" != "active" ]; then
        sleep 5
		lb_status=`qingcloud iaas describe-loadbalancers -l $LB -f $QINGCLOUD_CONFIG | jq -r '.loadbalancer_set[0].status'`
    else
        break;
    fi
done
echo "delete old ssl id:$old_ssl_id"
qingcloud iaas delete-server-certificates -s $old_ssl_id -f $QINGCLOUD_CONFIG
