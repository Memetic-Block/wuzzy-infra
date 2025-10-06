docker run \
  -v $(pwd)/data/indexed-xyz:/var/opt/indexed-xyz \
  -it \
  goldsky/indexed.xyz:latest \
  goldsky \
  indexed sync \
  raw-transactions \
  --network=arweave \
  --data-version=1.0.0