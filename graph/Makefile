graph-start:
	# Requires docker to be running
	npm run clean # If node has run before remove the old subgraph
	npm run start  # (re)start the node [postgres & ipfs & blockchain ingester]
	# npm run codegen

graph-deploy-polygon: 
	GRAPH_CHAIN=polygon npm run prepare
	GRAPH_CHAIN=polygon GQL_HOST=${GQL_HOST_PROD} npm run create-remote
	GRAPH_CHAIN=polygon GQL_HOST=${GQL_HOST_PROD} npm run deploy-remote	