trap "exit" INT

__red() {
  if [ "${__INTERACTIVE}${ACME_NO_COLOR:-0}" = "10" -o "${ACME_FORCE_COLOR}" = "1" ]; then
    printf '\033[1;31;40m%b\033[0m' "$1"
    return
  fi
  printf -- "%b" "$1"
}
_usage() {
  __red "$@" >&2
  printf "\n" >&2
}


_exists() {
  cmd="$1"
  if [ -z "$cmd" ]; then
    _usage "Usage: _exists cmd"
    return 1
  fi

  if eval type type >/dev/null 2>&1; then
    eval type "$cmd" >/dev/null 2>&1
  elif command >/dev/null 2>&1; then
    command -v "$cmd" >/dev/null 2>&1
  else
    which "$cmd" >/dev/null 2>&1
  fi
  ret="$?"
  return $ret
}

_check_deps() {
if ! _exists ~/.acme.sh/acme.sh; then
  echo "installing acme.sh..."
  curl  https://get.acme.sh | sh
fi

if ! _exists qingcloud; then
  if ! _exists pip; then
    echo "installing pip..."
    curl --show-error --retry 5 https://bootstrap.pypa.io/get-pip.py | sudo python
  fi
  echo "installing qingcloud-cli..."
  sudo pip install qingcloud-cli
fi

if ! _exists jq; then
  echo "installing jq..."
  if _exists apt-get; then
    sudo apt-get install jq -y
  elif _exists brew; then
    brew install jq
  else
    JQ=/usr/bin/jq
    curl https://stedolan.github.io/jq/download/linux64/jq > $JQ && chmod +x $JQ
    ls -la $JQ
  fi
fi
}

_issue() {
  json="$1"
  echo $json
  if [ -z "$json" ]; then
    _usage "Usage: _issue json"
    return 1
  fi
  # set dns env
  `echo $json | jq -r .dns_env_shell`
  dns_type=`echo $json |jq -r .dns_type `
 
  if [ -z "$dns_type" ]; then
    _usage "dns_type is Required"
    return 1
  fi

  for row in $(echo "${json}" | jq -r '.domains[]'); do
      _jq() {
       echo ${row}
      }
    domain=$(_jq '.[0]')
    echo "issue $domain"
    ~/.acme.sh/acme.sh --issue --dns $dns_type -d $domain
    echo "issue $domain success"
  done
}

_update_qingcloud_lb() {
  json="$1"
  echo $json
  if [ -z "$json" ]; then
    _usage "Usage: _issue json"
    return 1
  fi
  # delete qingcloud config file
  echo "clear qingcloud config file $QINGCLOUD_CONFIG"
  rm -fr $QINGCLOUD_CONFIG

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
  # update loadbalancer listener setting, apply setting
  qingcloud iaas modify-loadbalancer-listener-attributes -s $lbl -S $certificate_id_list -f $QINGCLOUD_CONFIG
  qingcloud iaas update-loadbalancers -l $lb -f $QINGCLOUD_CONFIG

  echo "old ssl id:$old_ssl_id"
  echo "waiting for change..."
  lb_status=`qingcloud iaas describe-loadbalancers -l $lb -f $QINGCLOUD_CONFIG | jq -r '.loadbalancer_set[0].status'`
  timeout=0
  while true ; do
      timeout=$(($timeout+1))
      if [ "$timeout" -gt 5 ]
      then
        break
      fi
      echo "loadbalancer status:$lb_status"
      if [ "$lb_status" != "active" ]; then
      sleep 3
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
}

main() {
config_file=""
ignoreissue=""
while [ ${#} -gt 0 ]; do
  case "${1}" in
    --help | -h)
      showhelp
      return
      ;;
    --version | -v)
      version
      return
      ;;
    --ignoreissue | -igi)
      ignoreissue="true"
      shift
      ;;
    --config | -c)
      config_file="$2"
      shift
      ;;
    *)
      _err "Unknown parameter : $1"
      showhelp
      return 1
      ;;
  esac
  shift 1
done

# check deps
_check_deps

if [ -z "$config_file" ]; then
  echo "use default config: config.json"
  config_file="config.json"
else
  echo "use custom config: $config_file"
fi

# load config
json=`cat $config_file`

if [ -z "$ignoreissue" ]; then
  # issue domain
  _issue "$json"
else
  echo "ignore issue domain certificate"
fi


# update qingcloud loadbalancer settings
QINGCLOUD_CONFIG=qingcloud_config.yaml
export QINGCLOUD_CONFIG
_update_qingcloud_lb "$json"

}

version() {
  echo "acme-qingcloud-lb"
  echo "v0.9.1"
}

showhelp() {
  version
  echo "Usage: $PROJECT_ENTRY  command ...[parameters]....
Commands:
  --help, -h               Show this help message.
  --version, -v            Show version info.
  --config, -c             the config file will be read from this path.
  --ignoreissue, -igi        ignore issue domain certificates.
  "
}





main "$@"
