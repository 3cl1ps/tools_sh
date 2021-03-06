#!/bin/bash
cd "${BASH_SOURCE%/*}" || exit

# Optionally just split UTXOs for a single coin
# e.g "KMD"
coin=$1

target_utxo_count=50
split_threshold=20

date=$(date +%Y-%m-%d:%H:%M:%S)

calc() {
    awk "BEGIN { print "$*" }"
}

if [[ -z "${coin}" ]]; then
    /home/eclips/tools/listcoins.sh | while read coin; do
    /home/eclips/tools/utxosplitter.sh $coin &
done;
exit;
fi

cli=$(./listclis.sh ${coin})

unlocked_utxos=$(${cli} listunspent | grep 0.00010000 | wc -l) 
locked_utxos=$(${cli} listlockunspent | jq -r length)
utxo_count=$(calc ${unlocked_utxos}+${locked_utxos})

if [[ ${utxo_count} -le ${split_threshold} ]]; then
    utxo_required=$(calc ${target_utxo_count}-${utxo_count})
    echo "[${coin}] Splitting ${utxo_required} extra UTXOs"
    json=$(/home/eclips/tools/acsplit ${coin} ${utxo_required})
    txid=$(echo ${json} | jq -r '.txid')
    if [[ ${txid} != "null" ]]; then
        echo "[${coin}] Split TXID: ${txid}"
    else
        echo "[${coin}] Error: $(echo ${json} | jq -r '.error')"
    fi
fi
