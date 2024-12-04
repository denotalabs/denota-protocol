-include .env

# Remove modules
remove :; rm -rf .gitmodules && rm -rf .git/modules/* && rm -rf lib && touch .gitmodules && git add . && git commit -m "modules"

all: clean remove install update solc build

fresh-install:
	curl -L https://foundry.paradigm.xyz | bash  # Need to reload PATH before foundryup
	foundryup

solc:; nix-env -f https://github.com/dapphub/dapptools/archive/master.tar.gz -iA solc-static-versions.solc_0_8_10

build  :; forge clean && forge build --optimizer-runs 1000000

install :; 
	forge install foundry-rs/forge-std
	forge install OpenZeppelin/openzeppelin-contracts --no-commit