#!/bin/bash
#
# Script to join utxos into one without going over tx size limit
#
# Usage: consolidate <coinname> <exclude_amount (optional - consolidate all but this value)
#
# If exclude_amount is specified, it will ignore these values
#
# @author webworker01
#
scriptpath="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source $scriptpath/main
txfeeperkb=0.000035

if [[ -z $1 ]]; then
    echo "consolidate <coinname> <exclude_amount (optional - consolidate all but this value)"
    exit 0
fi

number_regex='^[0-9]+([.][0-9]+)?$'

if [[ -z $2 ]]; then
    filter_amount=0
    #check amount is a number
elif [[ ! -z $2 ]] && ! [[ $2 =~ $number_regex ]] ; then
    echo "exclude_amount must be a number"
    exit 0
else
    filter_amount=1
    exclude_amount=$2
fi

if [[ ${1^^} != "KMD" ]]; then
    coin=${1^^}
    asset=" -ac_name=${1}"
    txfeeperkb=0
else
    coin="KMD"
    asset=""
    txfeeperkb=$txfeeperkb
fi

unspent=$(komodo-cli $asset listunspent)
if (( ${filter_amount} > 0 )); then
    consolidateutxo=$(jq --arg checkaddr $KMDADDRESS --arg exclude_amount $exclude_amount '[.[] | select (.amount!=($exclude_amount|tonumber) and .address==$checkaddr and .spendable==true)] | sort_by(-.amount)[0:399]' <<< $unspent)
else
    consolidateutxo=$(jq --arg checkaddr $KMDADDRESS '[.[] | select (.address==$checkaddr and .spendable==true)] | sort_by(-.amount)[0:399]' <<< $unspent)
fi
consolidatethese=$(jq -r '[.[] | {"txid":.txid, "vout":.vout}] | tostring' <<< $consolidateutxo)
consolidatetheselength=$(jq -r '. | length' <<< $consolidateutxo)
consolidateamount=$(jq -r '[.[].amount] | add' <<< $consolidateutxo)

txfee=$(calcFee ${consolidatetheselength} 1 "p2pkh" "p2pkh")
if [[ "$consolidateamount" != "null" ]]; then
    consolidateamountfixed=$( printf "%.8f" $(bc -l <<< "(${consolidateamount}-${txfee})") )
    if (( $(echo "$consolidateamountfixed > 0" | bc -l) )); then

        rawtxresult=$(komodo-cli $asset createrawtransaction "${consolidatethese}" '''{ "'$KMDADDRESS'": '$consolidateamountfixed' }''')
        rawtxid=$(sendRaw ${rawtxresult} ${coin})

        echo "consolidate" "${coin} - Sent $consolidateamount to $KMDADDRESS TXID: $rawtxid" "green" "file"
    fi
fi
