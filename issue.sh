sh dns_dp_conf.sh
file="domain.txt"
while IFS= read line
do
        # display $line or do somthing with $line
        echo "issue domain $line"
        domain=$line
		~/.acme.sh/acme.sh --issue --dns dns_dp -d $domain --force
        echo "issue $domain success"
done <"$file"
