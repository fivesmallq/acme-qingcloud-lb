# set dns env
json=`cat config.json`
#echo "$json"
# set dns env
`echo $json | jq -r .dns_env_shell`
dns_type=`echo $json |jq -r .dns_type `

for row in $(echo "${json}" | jq -r '.domains[]'); do
    _jq() {
     echo ${row}
    }
	domain=$(_jq '.[0]')
	echo "issue $domain"
	~/.acme.sh/acme.sh --issue --dns $dns_type -d $domain
	echo "issue $domain success"
done

QINGCLOUD_CONFIG=qingcloud_config.yaml

qy_access_key_id=`echo $json |jq -r .qy_access_key_id `
qy_secret_access_key=`echo $json |jq -r .qy_secret_access_key `
zone=`echo $json |jq -r .zone `

# create qingcloud config file
echo "create qingcloud config file $QINGCLOUD_CONFIG"

echo "qy_access_key_id: '$qy_access_key_id'" >> $QINGCLOUD_CONFIG
echo "qy_secret_access_key: '$qy_secret_access_key'" >> $QINGCLOUD_CONFIG
echo "zone: '$zone'" >> $QINGCLOUD_CONFIG

lb=`echo $json |jq -r .loadbalance_id `
lbl=`echo $json |jq -r .loadbalance_listener_id `

certificate_id_list=""

for row in $(echo "${json}" | jq -r '.domains[]'); do
    _jq() {
     echo ${row}
    }
	domain=$(_jq '.[0]')
	echo $domain
	echo "create ssl key for domain $line"
    keyFile=~/.acme.sh/$domain/$domain.key
    fullchainFile=~/.acme.sh/$domain/fullchain.cer
    name=`date +%Y%m%d`
    # create server certificate, remeber id
    response=`qingcloud iaas create-server-certificate -N $domain-$name -C "$fullchainFile" -K "$keyFile" -f $QINGCLOUD_CONFIG`
    echo $response
	certificate_id=`echo $response | jq -r .server_certificate_id`
    certificate_id_list="${certificate_id_list},$certificate_id"
    echo "create ssl key success for $domain"
done

certificate_id_list=`echo $certificate_id_list | cut -c 2-`

old_ssl_id=`qingcloud iaas describe-loadbalancer-listeners -l $lb -s $lbl -f $QINGCLOUD_CONFIG | jq -r '.loadbalancer_listener_set[0].server_certificate_id | join(",")'`

echo "set server_certificate_id $certificate_id_list to loadbalance $lb with loadbalance listener $lbl"
## update loadbalancer listener setting, apply setting
qingcloud iaas modify-loadbalancer-listener-attributes -s $lbl -S $certificate_id_list -f $QINGCLOUD_CONFIG
qingcloud iaas update-loadbalancers -l $lb -f $QINGCLOUD_CONFIG

echo "old ssl id:$old_ssl_id"
echo "waiting for change..."
lb_status=`qingcloud iaas describe-loadbalancers -l $lb -f $QINGCLOUD_CONFIG | jq -r '.loadbalancer_set[0].status'`
while true ; do
	echo "loadbalancer status:$lb_status"
    if [ "$lb_status" != "active" ]; then
		sleep 5
		lb_status=`qingcloud iaas describe-loadbalancers -l $lb -f $QINGCLOUD_CONFIG | jq -r '.loadbalancer_set[0].status'`
    else
        break;
    fi
done

echo "delete old ssl id:$old_ssl_id"
qingcloud iaas delete-server-certificates -s $old_ssl_id -f $QINGCLOUD_CONFIG

# delete qingcloud config file
echo "delete qingcloud config file $QINGCLOUD_CONFIG"
rm -fr $QINGCLOUD_CONFIG