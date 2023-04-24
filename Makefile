# include .env file and export its env vars
# (-include to ignore error if it does not exist)
-include .env

# Remove modules
remove :; rm -rf .gitmodules && rm -rf .git/modules/* && rm -rf lib && touch .gitmodules && git add . && git commit -m "modules"