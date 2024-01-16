graph-start:
	# Requires docker to be running
	npm run clean # If node has run before remove the old subgraph
	npm run start  # (re)start the node [postgres & ipfs & blockchain ingester]
	# npm run codegen

graph-deploy-local-mumbai:
	GRAPH_CHAIN=mumbai npm run prepare  
	GRAPH_CHAIN=mumbai npm run create-local
	GRAPH_CHAIN=mumbai npm run deploy-local  # Send the subgraph to the node (May need delay before this command if graphNode not ready to receive subgraph)

graph-deploy-local-alfajores:
	GRAPH_CHAIN=alfajores npm run prepare
	GRAPH_CHAIN=alfajores npm run create-local
	GRAPH_CHAIN=alfajores npm run deploy-local

graph-deploy-mumbai-test:
	GRAPH_CHAIN=mumbai npm run prepare
	GRAPH_CHAIN=mumbai GQL_HOST=${GQL_HOST_TEST} npm run create-remote
	GRAPH_CHAIN=mumbai GQL_HOST=${GQL_HOST_TEST} npm run deploy-remote

graph-deploy-mumbai-prod:
	GRAPH_CHAIN=mumbai npm run prepare
	GRAPH_CHAIN=mumbai GQL_HOST=${GQL_HOST_PROD} npm run create-remote
	GRAPH_CHAIN=mumbai GQL_HOST=${GQL_HOST_PROD} npm run deploy-remote

graph-deploy-alfajores-test:
	GRAPH_CHAIN=alfajores npm run prepare
	GRAPH_CHAIN=alfajores GQL_HOST=${GQL_HOST_TEST} npm run create-remote
	GRAPH_CHAIN=alfajores GQL_HOST=${GQL_HOST_TEST} npm run deploy-remote

graph-deploy-alfajores-prod:
	GRAPH_CHAIN=alfajores npm run prepare
	GRAPH_CHAIN=alfajores GQL_HOST=${GQL_HOST_PROD} npm run create-remote
	GRAPH_CHAIN=alfajores GQL_HOST=${GQL_HOST_PROD} npm run deploy-remote