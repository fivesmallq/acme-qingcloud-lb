# set dns env
json=`cat config.json`
echo "$json"
# set dns env
`echo $json | jq -r .dns_env_shell`
echo $DP_Id
echo $DP_Key
dns_type=`echo $json |jq -r .dns_type `
echo $dns_type

for row in $(echo "${json}" | jq -r '.domains[]'); do
    _jq() {
     echo ${row}
    }
	domain=$(_jq '.[0]')
	echo "issue domain $domain"
	~/.acme.sh/acme.sh --issue --dns $dns_type -d $domain
	echo "issue $domain success"
done

