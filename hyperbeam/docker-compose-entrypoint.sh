#!/bin/bash
set -e

rebar3 as genesis_wasm shell --eval "
  hb:start_mainnet(#{
    port => 10000,
    mode => debug,
    priv_key_location => <<\"/app/wallet.json\">>,
    http_extra_opts =>
      #{
        force_message => true,
        store => [{hb_store_fs, #{ prefix => \"local-cache\" }}, {hb_store_gateway, #{}}],
        cache_control => [<<\"always\">>]
      }
  }).
"
