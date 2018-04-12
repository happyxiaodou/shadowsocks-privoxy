#!/bin/sh

#------------------------------------------------------------------------------
# Configure the service:
#------------------------------------------------------------------------------

echo "start sslocal...."
env sslocal -s $SERVER_ADDR -p $SERVER_PORT -k $PASSWORD \
  -b 0.0.0.0 -l ${LOCAL_PORT:-7070} -m ${METHOD:-'aes-256-cfb'} \
  -d start --fast-open -q


echo "rebuild gfwlist...."

env touch /etc/privoxy/gfwlist.action

env gfwlist2privoxy -f /etc/privoxy/gfwlist.action -p 127.0.0.1:${LOCAL_PORT:-7070}  -t socks5

echo "start privoxy...."

env /usr/sbin/privoxy --no-daemon /etc/privoxy/config