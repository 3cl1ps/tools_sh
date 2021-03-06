#!/bin/bash
source /home/eclips/tools/main
cd "${BASH_SOURCE%/*}" || exit

coin="VERUS"
daemon="verusd -pubkey=${PUBKEY}"
daemon_process_regex="verusd.*\-pubkey"
cli="komodo-cli -ac_name=VRSC"
wallet_file="${HOME}/.komodo/VRSC/wallet.dat"

/home/eclips/install/walletreset2.sh \
    "${coin}" \
    "${daemon}" \
    "${daemon_process_regex}" \
    "${cli}" \
    "${wallet_file}" \
    "${KMDADDRESS}"
