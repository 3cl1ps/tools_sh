#!/bin/bash
source /home/eclips/tools/main
TIMEFORMAT=%R
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Coloir
isNumber='^[+-]?([0-9]+\.?|[0-9]*\.[0-9]+)$'
#isNumber='^[-+]?[0-9]+\.?[0-9]*$'
btcntrzaddr=1P3rU1Nk1pmc2BiWC8dEy9bZa1ZbMp5jfg
kmdntrzaddr=RXL3YXG2ceaB6C5hfJcN4fvmLH2C34knhA
txscanamount=2000
if ps aux | grep -v grep | grep iguana | grep -v force >/dev/null
then 
    printf "${GREEN}%-9s${NC}" "iguana"
else
    printf "${RED}%-20s${NC}" "iguana Not Running"
    /home/eclips/tools/force_dpow.sh &
fi
printf "\n"

if ps aux | grep -v grep | grep DPOW >/dev/null
then 
    printf "${GREEN}%-9s${NC}" "DPOW"
else
    printf "${RED}%-20s${NC}" "DPOW Not Running"
fi
printf "\n

if ps aux | grep -v grep | grep "komodod" | grep notary | grep -v walletreset >/dev/null; then
    balance="$(komodo-cli -rpcclienttimeout=15 getbalance 2>&1)"
    if [[ $balance =~ $isNumber ]]; then
        printf "${GREEN}%-9s${NC}" "komodo"
        if (( $(echo "$balance > 0.1" | bc -l) )); then
            printf " - Funds: ${GREEN}%10.2f${NC}" $balance
        else
            printf " - Funds: ${RED}%10.2f${NC}" $balance
        fi
        listunspent=$(komodo-cli listunspent | grep .00010000 | wc -l)
        # Check if we have actual results next two lines check for valid number.
        if [[ $listunspent =~ $isNumber ]]; then
            if [[ "$listunspent" -lt "5" ]] || [[ "$listunspent" -gt "50" ]]; then
                printf  " - UTXOs: ${RED}%3s${NC}" $listunspent
            else
                printf  " - UTXOs: ${GREEN}%3s${NC}" $listunspent
            fi
        fi
        countunspent="$(komodo-cli -rpcclienttimeout=15 listunspent 2>&1|grep amount |awk '{print $2}'|sed s/.$//|awk '$1 < 0.0001'|wc -l)"
        if [[ $countunspent =~ $isNumber ]]; then
            if [ "$countunspent" -gt "0" ]
            then
                printf  " - Dust: ${RED}%3s${NC}" $countunspent
            else
                printf  " - Dust: ${GREEN}%3s${NC}" $countunspent
            fi
        fi
        SIZE=$(stat --printf="%s" /home/eclips/.komodo/wallet.dat)
        OUTSTR=$(echo $SIZE | numfmt --to=si --suffix=B)
        if [ "$SIZE" -gt "4000000" ]; then
            printf " - WSize: ${RED}%5s${NC}" $OUTSTR           
        else
            printf " - WSize: ${GREEN}%5s${NC}" $OUTSTR
        fi
        TIME=$((time komodo-cli listunspent) 2>&1 >/dev/null)
        if [[ "$TIME" > "0.05" ]]; then
            printf " - Time: ${RED}%3ss${NC}" $TIME          
        else
            printf " - Time: ${GREEN}%3ss${NC}" $TIME
        fi
        txinfo=$(komodo-cli listtransactions "" $txscanamount 2>&1)
        lastntrztime=$(echo $txinfo | jq -r --arg address "$kmdntrzaddr" '[.[] | select(.address==$address)] | sort_by(.time) | last | "\(.time)"') 
        printf " - LastN: ${GREEN}%6s${NC}" $(timeSince $lastntrztime)
        #speed
        now=$(date +%s)
        window=$(echo "$now - 3600" | bc -l)
        speed=$(echo $txinfo | jq -r --arg address "$kmdntrzaddr" --argjson window "$window" '[.[] | select(.address==$address and .time > $window)] | length')
        if (( $speed < 10 )); then
            printf " - Speed1: ${RED}%2s${NC}" $speed  
        else
            printf " - Speed1: ${GREEN}%2s${NC}" $speed
        fi
        #graph
        if [ $(</tmp/graph wc -l) -gt 3000 ]; then 
            sed -i '1d' /tmp/graph
        fi
        echo "$(date +%T)" ";" "$listunspent" ";" "$SIZE" ";" "$TIME" ";" "$speed" >> /tmp/graph
    else
        printf "${YELLOW}Komodo Loading${NC}"
    fi
    balance=""
    listunspent=""
    countunspent=""
    balance=""
    TIME=""
    SIZE=""
    OUTSTR=""
    txinfo=""
    lastntrztime=""
else
    printf "${RED}Komodo Not Running${NC}"
fi
printf "\n"

if ps aux | grep -v grep | grep bitcoind >/dev/null; then
    balance="$(bitcoin-cli -rpcclienttimeout=15 getbalance 2>&1)"
    if [[ $balance =~ $isNumber ]]; then
        printf "${GREEN}%-9s${NC}" "bitcoind"
        if (( $(echo "$balance > 0.1" | bc -l) )); then
            printf " - Funds: ${GREEN}%10.2f${NC}" $balance
        else
            printf " - Funds: ${RED}%10.2f${NC}" $balance
        fi
        listunspent="$(bitcoin-cli -rpcclienttimeout=15 listunspent | grep .00010000 | wc -l)"
        if [[ $listunspent =~ $isNumber ]]; then
            if [[ "$listunspent" -lt "5" ]] || [[ "$listunspent" -gt "50" ]]; then
                printf  " - UTXOs: ${RED}%3s${NC}" $listunspent
            else
                printf  " - UTXOs: ${GREEN}%3s${NC}" $listunspent
            fi
        fi
        countunspent="$(bitcoin-cli -rpcclienttimeout=15  listunspent|grep amount|awk '{print $2}'|sed s/.$//|awk '$1 < 0.0001'|wc -l)"
        if [[ $countunspent =~ $isNumber ]]; then
            if [ "$countunspent" -gt "0" ]
            then
                printf  " - Dust: ${RED}%3s${NC}" $countunspent
            else
                printf  " - Dust: ${GREEN}%3s${NC}" $countunspent
            fi
        fi

        if [ -e /home/eclips/.bitcoin/wallet.dat ]; then
            SIZE=$(stat --printf="%s" /home/eclips/.bitcoin/wallet.dat)
        fi
        if [ -e /bitcoin/wallet.dat ]; then
            SIZE=$(stat --printf="%s" /bitcoin/wallet.dat)
        fi
        OUTSTR=$(echo $SIZE | numfmt --to=si --suffix=B)
        if [ "$SIZE" -gt "4000000" ]; then
            printf " - WSize: ${RED}%5s${NC}" $OUTSTR           
        else
            printf " - WSize: ${GREEN}%5s${NC}" $OUTSTR
        fi
        TIME=$((time bitcoin-cli listunspent) 2>&1 >/dev/null)
        if [[ "$TIME" > "0.05" ]]; then
            printf " - Time: ${RED}%3ss${NC}" $TIME          
        else
            printf " - Time: ${GREEN}%3ss${NC}" $TIME
        fi
        txinfo=$(bitcoin-cli listtransactions "" $txscanamount)
        lastntrztime=$(echo $txinfo | jq -r --arg address "$btcntrzaddr" '[.[] | select(.address==$address)] | sort_by(.time) | last | "\(.time)"')
        printf " - LastN: ${GREEN}%6s${NC}" $(timeSince $lastntrztime)
        #speed
        now=$(date +%s)
        window=$(echo "$now - 3*3600" | bc -l)
        speed=$(echo $txinfo | jq -r --arg address "$btcntrzaddr" --argjson window "$window" '[.[] | select(.address==$address and .time > $window)] | length')
        if (( $speed < 10 )); then
            printf " - Speed3: ${RED}%2s${NC}" $speed  
        else
            printf " - Speed3: ${GREEN}%2s${NC}" $speed
        fi
    else
        printf "${YELLOW}Bitcoin Loading${NC}"
    fi
    balance=""
    listunspent=""
    countunspent=""
    balance=""
    TIME=""
    SIZE=""
    OUTSTR=""
    txinfo=""
    lastntrztime=""
else
    printf "${RED}Bitcoin Not Running${NC}"
fi
printf "\n"

if ps aux | grep -v grep | grep verusd >/dev/null; then
    balance="$(komodo-cli -ac_name=VRSC -rpcclienttimeout=15 getbalance 2>&1)"
    if [[ $balance =~ $isNumber ]]; then
        printf "${GREEN}%-9s${NC}" "VRSC"
        if (( $(echo "$balance > 0.1" | bc -l) )); then
            printf " - Funds: ${GREEN}%10.2f${NC}" $balance
        else
            printf " - Funds: ${RED}%10.2f${NC}" $balance
        fi
        listunspent="$(komodo-cli -ac_name=VRSC -rpcclienttimeout=15 listunspent | grep .00010000 | wc -l)"
        if [[ $listunspent =~ $isNumber ]]; then
            if [[ "$listunspent" -lt "5" ]] || [[ "$listunspent" -gt "50" ]]; then
                printf  " - UTXOs: ${RED}%3s${NC}" $listunspent
            else
                printf  " - UTXOs: ${GREEN}%3s${NC}" $listunspent
            fi
        fi
        countunspent="$(komodo-cli -ac_name=VRSC -rpcclienttimeout=15 listunspent|grep amount |awk '{print $2}'|sed s/.$//|awk '$1 < 0.0001'|wc -l)"
        if [[ $countunspent =~ $isNumber ]]; then
            if [ "$countunspent" -gt "0" ]
            then
                printf  " - Dust: ${RED}%3s${NC}" $countunspent
            else
                printf  " - Dust: ${GREEN}%3s${NC}" $countunspent
            fi
        fi
        SIZE=$(stat --printf="%s" /home/eclips/.komodo/VRSC/wallet.dat)
        OUTSTR=$(echo $SIZE | numfmt --to=si --suffix=B)
        if [ "$SIZE" -gt "4000000" ]; then
            printf " - WSize: ${RED}%5s${NC}" $OUTSTR           
        else
            printf " - WSize: ${GREEN}%5s${NC}" $OUTSTR
        fi
        TIME=$((time komodo-cli -ac_name=VRSC listunspent) 2>&1 >/dev/null)
        if [[ "$TIME" > "0.05" ]]; then
            printf " - Time: ${RED}%3ss${NC}" $TIME          
        else
            printf " - Time: ${GREEN}%3ss${NC}" $TIME
        fi
        txinfo=$(komodo-cli -ac_name=VRSC listtransactions "" $txscanamount)
        lastntrztime=$(echo $txinfo | jq -r --arg address "$kmdntrzaddr" '[.[] | select(.address==$address)] | sort_by(.time) | last | "\(.time)"') 
        printf " - LastN: ${GREEN}%6s${NC}" $(timeSince $lastntrztime)
        #speed
        now=$(date +%s)
        window=$(echo "$now - 3*3600" | bc -l)
        speed=$(echo $txinfo | jq -r --arg address "$kmdntrzaddr" --argjson window "$window" '[.[] | select(.address==$address and .time > $window)] | length')
        if (( $speed < 1 )); then
            printf " - Speed3: ${RED}%2s${NC}" $speed  
        else
            printf " - Speed3: ${GREEN}%2s${NC}" $speed
        fi
    else
        printf "${YELLOW}Verus Loading${NC}"
    fi
    balance=""
    listunspent=""
    countunspent=""
    balance=""
    TIME=""
    SIZE=""
    OUTSTR=""
    txinfo=""
    lastntrztime=""
else
    printf "${RED}VRSC Not Running${NC}"
fi
printf "\n"

/home/eclips/komodo/src/listassetchains | while read list; do
if [[ ! ${ignoreacs[*]} =~ ${list} ]]; then
    if ps aux | grep -v grep | grep ${list} >/dev/null
    then
        balance="$(komodo-cli -rpcclienttimeout=15 -ac_name=${list} getbalance 2>&1)"
        if [[ $balance =~ $isNumber ]]; then
            printf "${GREEN}%-9s${NC}" "${list}"
            if (( $(echo "$balance > 0.1" | bc -l) )); then
                printf " - Funds: ${GREEN}%10.2f${NC}" $balance
            else
                printf " - Funds: ${RED}%10.2f${NC}" $balance
            fi
            listunspent="$(komodo-cli -rpcclienttimeout=15 -ac_name=${list} listunspent 2>&1 | grep .00010000 | wc -l)"
            if [[ $listunspent =~ $isNumber ]]; then
                if [[ "$listunspent" -lt "5" ]] || [[ "$listunspent" -gt "110" ]]; then
                    printf  " - UTXOs: ${RED}%3s${NC}" $listunspent
                else
                    printf  " - UTXOs: ${GREEN}%3s${NC}" $listunspent
                fi
            fi
            countunspent="$(komodo-cli -ac_name=${list} -rpcclienttimeout=15 listunspent 2>&1 |grep amount |awk '{print $2}'|sed s/.$//|awk '$1 < 0.0001'|wc -l)"
            if [[ $countunspent =~ $isNumber ]]; then
                if [ "$countunspent" -gt "0" ]; then
                    printf  " - Dust: ${RED}%3s${NC}" $countunspent
                else
                    printf  " - Dust: ${GREEN}%3s${NC}" $countunspent
                fi
            fi
            SIZE=$(stat --printf="%s" ~/.komodo/${list}/wallet.dat)
            OUTSTR=$(echo $SIZE | numfmt --to=si --suffix=B)
            if [ "$SIZE" -gt "4000000" ]; then
                printf " - WSize: ${RED}%5s${NC}" $OUTSTR 
            else
                printf " - WSize: ${GREEN}%5s${NC}" $OUTSTR
            fi
            TIME=$((time komodo-cli -ac_name=${list} listunspent) 2>&1 >/dev/null)
            if [[ "$TIME" > "0.05" ]]; then
                printf " - Time: ${RED}%5ss${NC}" $TIME          
            else
                printf " - Time: ${GREEN}%5ss${NC}" $TIME
            fi
            txinfo=$(komodo-cli -ac_name=${list} listtransactions "" $txscanamount 2>&1)
            lastntrztime=$(echo $txinfo | jq -r --arg address "$kmdntrzaddr" '[.[] | select(.address==$address)] | sort_by(.time) | last | "\(.time)"')
            printf " - LastN: ${GREEN}%6s${NC}" $(timeSince $lastntrztime)
            #speed
            now=$(date +%s)
            window=$(echo "$now - 3*3600" | bc -l)
            speed=$(echo $txinfo | jq -r --arg address "$kmdntrzaddr" --argjson window "$window" '[.[] | select(.address==$address and .time > $window)] | length')
            if (( $speed < 1 )); then
                printf " - Speed3: ${RED}%2s${NC}" $speed  
            else
                printf " - Speed3: ${GREEN}%2s${NC}" $speed
            fi
        else
            printf "${YELLOW}${list} Loading${NC}\n"
            continue
        fi
        balance=""
        listunspent=""
        countunspent=""
        balance=""
        TIME=""
        SIZE=""
        OUTSTR=""
        txinfo=""
        lastntrztime=""
    else
        printf "${RED}${list} Not Running${NC}"
    fi
    printf "\n"
fi
done
