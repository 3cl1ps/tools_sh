#!/bin/bash
cd "${BASH_SOURCE%/*}" || exit

coin="VRSC"
daemon="/home/eclips/VerusCoin/src/komodod -ac_name=VRSC -ac_algo=verushash -ac_cc=1 -ac_supply=0 -ac_eras=3 -ac_reward=0,38400000000,2400000000 -ac_halving=1,43200,1051920 -ac_decay=100000000,0,0 -ac_end=10080,226080,0 -ac_timelockgte=19200000000 -ac_timeunlockfrom=129600 -ac_timeunlockto=1180800 -ac_veruspos=50 -addnode=95.216.13.66"
daemon_process_regex="verusd.*\-pubkey"
cli="komodo-cli -ac_name=VRSC"
wallet_file="${HOME}/.komodo/VRSC/wallet.dat"
nn_address=$KMDADDRESS

./walletreset.sh \
  "${coin}" \
  "${daemon}" \
  "${daemon_process_regex}" \
  "${cli}" \
  "${wallet_file}" \
  "${nn_address}"
