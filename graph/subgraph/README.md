# Setup
`npm install`

`sudo npm i -g @graphprotocol/graph-cli`

Possible Errors:
```
npm ERR! code 128
npm ERR! An unknown git error occurred
npm ERR! command git --no-replace-objects ls-remote ssh://git@github.com/hugomrdias/concat-stream.git
npm ERR! Warning: Permanently added 'github.com' (ED25519) to the list of known hosts.
npm ERR! git@github.com: Permission denied (publickey).
npm ERR! fatal: Could not read from remote repository.
npm ERR! 
npm ERR! Please make sure you have the correct access rights
npm ERR! and the repository exists.

npm ERR! A complete log of this run can be found in: /Users/alexa/.npm/_logs/2024-01-27T20_12_45_985Z-debug-0.log
```

https://docs.alchemy.com/docs/how-to-build-and-deploy-a-subgraph-using-alchemy-subgraphs

`graph init`

Paste the registrar address where needed

Then

graph deploy denota \
  --version-label v0.0.1-new-version \
  --node https://subgraphs.alchemy.com/api/subgraphs/deploy \
  --deploy-key 6p8qbBkMeCbi1 \
  --ipfs https://ipfs.satsuma.xyz

You may need to change the subgraph.yaml specVersion to 0.0.8 for it to work