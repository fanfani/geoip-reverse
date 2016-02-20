#!/bin/bash

check_files_dload(){
    # download csv files from maxmind's website (geolite2 format)
    DB_URL="http://geolite.maxmind.com/download/geoip/database/GeoLite2-City-CSV.zip" # maxmind's geolite2
    DB_ZPF=$(echo $DB_URL | rev | cut -d '/' -f 1 | rev)
    [ -f $DB_ZPF ] || wget $DB_URL

    DB_LOC="GeoLite2-City-Locations-en.csv" # name of location file to extract from zip archive
    DB_LFP=$(unzip -l $DB_ZPF | grep $DB_LOC | awk '{print $4}')
    DB_LFN=$(echo $DB_LFP | cut -d '/' -f 2)
    [ -f $DB_LFN ] || unzip -j "$DB_ZPF" "$DB_LFP" -d "." && echo

    DB_BLC="GeoLite2-City-Blocks-IPv4.csv" # name of block file to extract from zip archive
    DB_BFP=$(unzip -l $DB_ZPF | grep $DB_BLC | awk '{print $4}')
    DB_BFN=$(echo $DB_BFP | cut -d '/' -f 2)
    [ -f $DB_BFN ] || unzip -j "$DB_ZPF" "$DB_BFP" -d "." && echo
}

# switch between administative levels
case $1 in

    city)
      check_files_dload
      echo "# City: $2"
      echo "#"
      COL=11
      ;;

    province)
      check_files_dload
      echo "# Province: $2"
      echo "#"
      COL=10
      ;;

    region)
      check_files_dload
      echo "# Region: $2"
      echo "#"
      COL=8
      ;;

    country)
      check_files_dload
      echo -e "# Country: $2"
      echo "#"
      COL=6
      ;;

    *)
      echo -e "Usage: $0 city|province|region|country placename \n\nExample: $0 city London\n"
      exit 1
      ;;

esac

# main loop

location_ids=($(awk  -F "," '{print $1" "$'$COL' }' $DB_LFN | grep -i " $2" | cut -d ' ' -f 1))

printf "# %19s %29s    %s\n" IP_CLASS PLACE_NAME NET_NAME
echo "# -------------------------------------------------------------------------"

for i in "${location_ids[@]}"
do
    curr_city=$(grep "$i" $DB_LFN | awk  -F "," '{print $11}' | sed -e 's/"//g')

    grep $i $DB_BFN | cut -d ',' -f 1 | while read curr_class
    do
        curr_netnam=$(whois $curr_class | grep "netname:" | awk '{print $2}')
        printf "%20s %30s    %s\n" "$curr_class" "$curr_city" "$curr_netnam"

        #~ curr_hosts=$(nmap -n -sP -T5 192.168.0/24 -oG - | grep seconds | cut -d '(' -f 2 | cut -d ')' -f 1)
        #~ printf "%20s    %10s %30s    %s\n" "$curr_class" "$curr_hosts" "$curr_city" "$curr_netnam"

    done
done

