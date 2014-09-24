#!/bin/bash
set -e

# Tunable settings
SSL_DIR=${SSL_DIR:-/etc/ssl/nginx}
WWW_DIR=${WWW_DIR:-/data/www}
CSR_C=${CSR_C:-US}
CSR_ST=${CSR_ST:-CA}
CSR_L=${CSR_L:-Los Angeles}
CSR_O=${CSR_O:-myorg}
CSR_OU=${CSR_OU:-department}
CSR_CN=${CSR_CN:-myorg.com}
ENABLE=${ENABLE:-static_serv}

# Misc settings
ERR_LOG=/log/$HOSTNAME/nginx_stderr.log


restart_message() {
    echo "Container restart on $(date)."
    echo -e "\nContainer restart on $(date)." | tee -a $ERR_LOG
}

enable_sites() {
    rm -f /config/nginx/sites-enabled/*

    listLength=$(echo "$ENABLE" | wc -w)

    get_site() {
        echo "$ENABLE" | awk -v i=${i} -F ' ' '{print $i}'
    }

    i=1
    while [ $i -le $((listLength)) ]; do
        site=$(get_site $i)
        if [ -f /config/nginx/sites-available/${site}.conf ]; then
            ln -s /config/nginx/sites-available/${site}.conf /config/nginx/sites-enabled/${site}.conf
        else
            echo -e "Error: Can't enable site \"$site\". Not found." | tee -a $ERR_LOG
            exit 1
        fi
        i=$((i + 1))
    done
}

# create dirs if needed
mkdir -p $SSL_DIR
mkdir -p -m 700 $WWW_DIR
chown www-data:www-data $WWW_DIR
mkdir -p /config/nginx/sites-enabled

# initialize folders if needed
if [ ! "`ls -A $SSL_DIR`" ] ; then
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout $SSL_DIR/nginx.key -out $SSL_DIR/nginx.crt -subj "/C=${CSR_C}/ST=${CSR_ST}/L=${CSR_L}/O=${CSR_O}/OU=${CSR_OU}/CN=${CSR_CN}"
    echo "Certificate generated on $(date)."
else
    restart_message
fi

enable_sites

exec /usr/sbin/nginx \
    -c /config/nginx/nginx.conf
