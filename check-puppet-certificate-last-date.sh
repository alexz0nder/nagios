#!/bin/bash

function check_certificate {
	while [ -n "$1" ]
	do
	case "$1" in
		-c)
      if ! [ -z "$2" ]; then
        CRITICAL=$2
        shift
      else
        echo "ERROR: you didn't specify value for -c option"
        echo ""
        usage
        exit 3
      fi
			;;
    -w)
      if ! [ -z "$2" ]; then
        WARNING=$2
        shift
      else
        echo "ERROR: you didn't specify value for -w option"
        echo
				usage
				exit 3
			fi
			;; 
    *)
       usage 
       exit 3
       ;;
    esac
    shift
    done

    if [[ -z "$WARNING" ]] && ! [[ -z "$CRITICAL" ]]; then
    	WARNING=$(($CRITICAL*2))
    elif [[ -z "$CRITICAL" ]] && ! [[ -z "$WARNING" ]]; then
    	CRITICAL=$(($WARNING/2))
    fi

	today_unix_date=$(date +%s)

	DATE_OF_THE_END=$(openssl x509 -noout -dates -in /etc/puppetlabs/puppet/ssl/certs/ca.pem | grep notAfter | awk -F'=' '{print $NF}' | awk '{printf "%s%s%s", $2, $1, $4}')
	cert_unix_date=$(date -d $DATE_OF_THE_END +%s)

    days_to_the_end=$(($cert_unix_date-$today_unix_date))
    days_to_the_end=$(($days_to_the_end/86400))

    if [[ $days_to_the_end -ge $WARNING ]]; then
    	printf "OK - more than %s days to the end of the certificate" $WARNING
    	echo ""
    	exit 0
    elif [[ $days_to_the_end -ge $CRITICAL ]]; then
    	printf "WARNING - %s days to the end of the certificate" $days_to_the_end
    	echo ""
    	exit 1
    else
    	printf "CRITICAL - %s days to the end of the certificate" $days_to_the_end
    	echo ""
    	exit 2
    fi
}

function main {
	if [ $# -eq 0 ]; then
		usage
    else
        check_certificate "$@"
	fi
}

function usage {
 cat << EOF 
 Usage: $0 [OPTION]... 
 Checks if puppet certificate is up to date.
 
  -w, --warning   Days till the last day of the certificate and 
                  in case it's less - we get WARNING status
                  if it isn't specified, warning days is 30
  -c, --critical  Days till the last day of the certificate and
                  in case it's less - we get CRITICAL status
                  if it isn't specified, critical days is a half
                  of warning days
  
 Examples:
  $0 -c 90 -w 20
                  Checks the certificate on local host and if it's 
                  last day is less than 90 days from now it returns 
                  CRITICAL output with exit code 2. 
                  Although in case the last day is less then 20 days
                  it returns WARNING"
  
EOF
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
	main "$@"
fi
