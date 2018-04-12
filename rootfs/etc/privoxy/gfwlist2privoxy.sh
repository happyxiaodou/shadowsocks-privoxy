#!/bin/bash

gfwlist_action='gfwlist.action'

socks5_proxy=$1
if [[ ! "${socks5_proxy}" =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}:[0-9]{1,5}$ ]]; then
    echo -e "\e[35minvalid address:\e[0m \"${socks5_proxy}\"" 1>&2
    echo -e "\e[37mUsage:\e[0m \e[32m$0\e[0m \e[36m'address:port'\e[0m" 1>&2
    exit 1
else
    echo "{+forward-override{forward-socks5 ${socks5_proxy} .}}" > ${gfwlist_action}
fi

gfwlist_txt=$(mktemp)
gfwlist_regex=$(mktemp)
gfwlist_scheme=$(mktemp)
gfwlist_begin=$(mktemp)
gfwlist_main=$(mktemp)
gfwlist_temp=$(mktemp)

curl -skL https://raw.github.com/gfwlist/gfwlist/master/gfwlist.txt | base64 -d | egrep -v '^$|^!|^@@|^\[AutoProxy' > ${gfwlist_txt}


cat ${gfwlist_txt} | egrep '^/' > ${gfwlist_regex}                  # '/regex/' 正则
cat ${gfwlist_txt} | egrep '^\|\|' > ${gfwlist_scheme}              # '||pattern' 协议符
cat ${gfwlist_txt} | egrep '^\|[^\|]' > ${gfwlist_begin}            # '|pattern' 边界符
cat ${gfwlist_txt} | egrep -v '^/|^\|\||^\|[^\|]' > ${gfwlist_main} # 与 privoxy.action 语法接近的部分

 echo '.google.' >> ${gfwlist_main}
echo '.blogspot.' >> ${gfwlist_main}
echo '.twimg.edgesuite.net' >> ${gfwlist_main}

cat ${gfwlist_scheme} | sed -r 's@^\|\|(.*)$@\1@g' >> ${gfwlist_main}

cat ${gfwlist_begin} | sed -r 's@^\|(.*)$@\1@g' | sed -r '\@^https?://@ s@^https?://(.*)$@\1@g' >> ${gfwlist_main}

cat ${gfwlist_main} | sed -r '\@/@ s@^([^/]*).*$@\1@g' | sort | uniq -i > ${gfwlist_temp}

cat ${gfwlist_temp} | grep -P '^\d+\.\d+\.\d+\.\d+(?::\d+)?$' >> ${gfwlist_action}

cat ${gfwlist_temp} | grep -Pv '^\d+\.\d+\.\d+\.\d+(?::\d+)?$' | sed -r '\@^\.@! s@^(.*)$@.\1@g' | sort | uniq -i >> ${gfwlist_action}

rm -fr ${gfwlist_txt} ${gfwlist_regex} ${gfwlist_scheme} ${gfwlist_begin} ${gfwlist_main} ${gfwlist_temp}

echo -e "\e[37m# Please execute the following command:\e[0m"
echo -e "\e[36mcp -af ${gfwlist_action} /etc/privoxy/\e[0m"
echo -e "\e[36mecho \"actionsfile ${gfwlist_action}\" >> /etc/privoxy/config\e[0m"

