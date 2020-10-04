#!/bin/bash
set -eox trace


#
# Global Variables
#
SITE=""         # Hostname or TCIP address to extract from
ENDCERT=0       # Flag to extract the end-certificate
CHAINCERTS=1    # Flag to extract the intermediate and root cert authority certs
FULL=1          # Flag to build the full PEM
AUTHCHAIN=1     # Flag to build the root CA

validate_source() {
  local ValidIpAddressRegex="^(([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])\.){3}([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])$"
  local ValidHostnameRegex="^(([a-zA-Z0-9]|[a-zA-Z0-9][a-zA-Z0-9\-]*[a-zA-Z0-9])\.)*([A-Za-z0-9]|[A-Za-z0-9][A-Za-z0-9\-]*[A-Za-z0-9])$"
  local Site=$1
  
  if [[ ! "$Site" ]]; then 
    echo "validate_ip should be called with a value"
    return 1 
  fi
  if  [[ $Site =~ $ValidIpAddressRegex ]] | [[ $Site =~ $ValidHostnameRegex ]]; then
    # Make sure it points to a something that can be reach
    if [[ $(ping -c 1 $SITE &> /dev/null ; echo $?) -gt 0 ]]; then
      return 1
    else
        return 0
    fi
  else 
     return 1
  fi
}

#
# Show help
#
show_help() {
cat << EOF
usage: extract-certs --site {hostname} [--all] | [--end-cert] [--chain-certs] [--full] [--auth-chain] | [-?|-h|--help]
  options:
    --site {hostname}                   Hostname or IP/Address to extract from
    --all                               Extract all certificates, build full PEM and Auth Chain PEM
    --end-cert                          Extract the end certificate only
    --chain-certs                       Extract the intermediate and root cert authority certs
    --full                              Extract end-cert, intermediates and root certificates into a PEM
    --auth-chain                        Extract the root and intermediates into a PEM named rootCA.pem
    -?, -h, --help                      Show this help
EOF
exit 0
}

#
# Process Command line Arguments
#
for arg in "$@"
do
    case $arg in
        --site)      
          CAPTURE_SITE="$2"
          if [[ ! "$CAPTURE_SITE" ]]; then 
            echo "$1 should be called with a value"
            exit 1 
          fi
          SITE=$2
          isValid=$(validate_source "$SITE"; echo $?)
          echo "isValid: $isValid"
          if [[ "$isValid" -gt 0 ]]; then 
            echo "'$SITE' does not appear to be valid.  If an TCP-IP Address is given, it should be resolvable in DNS"
            exit 1
          fi
          shift # Remove key from processing
          shift # Remove value from processing
        ;;
        --end-cert)      
          $ENDCERT=1
          shift # Remove key from processing
        ;;
        --auth-chain)
          $AUTHCHAIN=1
          shift # Remove key from processing
        ;;
        --full)      
          $FULL=1
          shift # Remove key from processing
        ;;
        --chain-certs)      
          $CHAINCERTS=1
          shift # Remove key from processing
        ;;
        --all)      
          $ENDCERT=1
          $AUTHCHAIN=1
          $FULL=1
          $CHAINCERTS=1
          shift # Remove key from processing
        ;;
        -h|--help|-?)
          show_help
        ;;
    esac
done


echo "Stopping here"
exit 0

echo "Working in $TMPDIR"
cd $TMPDIR

openssl s_client -showcerts -verify 5 -connect vrli8.lab.mccannical.net:443 < /dev/null | awk '/BEGIN/,/END/{ if(/BEGIN/){a++}; out=a"-cert.crt"; print >out}' 

for cert in *.crt; do   
        CERT_NUMBER=$(echo "$cert" | cut -c1-1)
        CERT_NAME=$(openssl x509 -noout -subject -in $cert | sed -n 's/^.*CN=\(.*\)$/\1/; s/[ ,.*]/_/g; s/__/_/g; s/^_//g;p').crt
        FILE_NAME="$CERT_NUMBER-$CERT_NAME"
        mv $cert $FILE_NAME
done

CERT_LIST=($(ls -1 *.crt))
NUM_CERTS=${#CERT_LIST[@]}

echo "THere are $NUM_CERTS certificates extracted"

# Build the full pem
PEM_NAME=""
for cert in *.crt; do
        CERT_NUMBER=$(echo "$cert" | cut -c 1-1)
        if [[ "$CERT_NUMBER" -eq 1 ]]; then
                PEM_NAME=$( echo "$cert"| cut -c 3- | cut -d'.' -f1)
        fi
        cat $cert >> "$PEM_NAME.pem"
done

# Build CA PEM
CAPEM_NAME="rootCA.pem"
for cert in *.crt; do
        CERT_NUMBER=$(echo "$cert" | cut -c1-1)
        if [[ "$CERT_NUMBER" -eq 1 ]]; then continue; fi # Skip 1st line
        cat $cert >> $CAPEM_NAME
done

if [[ "$ENDCERT" -eq "1" ]]

          $ENDCERT=1
          $AUTHCHAIN=1
          $FULL=1
          $CHAINCERTS=1
fi