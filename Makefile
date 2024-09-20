-include .env

# Clean the repo
clean  :; forge clean

# Run tests
test-anvil  :; forge test --rpc-url  http://127.0.0.1:8545  -vvvv

# Run tests on sepolia
test-sepolia  :; forge test --fork-url ${SEPOLIA_RPC_URL} -vvvv 

	# Run tests on base
test-base  :; forge test --fork-url ${BASE_RPC_URL} -vvvv 

# Build
build :; forge build

# Deploy locally
deploy-anvil  :; forge script script/DeployFundMeFactory.s.sol:DeployFundMeFactory --rpc-url  http://127.0.0.1:8545 --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80  --broadcast -vvvv

# Deploy on sepolia
deploy-sepolia  :; forge script script/DeployFundMeFactory.s.sol:DeployFundMeFactory --rpc-url ${SEPOLIA_RPC_URL} --private-key ${PRIVATE_KEY} --verify --etherscan-api-key ${ETHERSCAN_API_KEY} -vvvv --broadcast

# Deploy on base
deploy-base  :; forge script script/DeployFundMeFactory.s.sol:DeployFundMeFactory --rpc-url ${BASE_RPC_URL} --private-key ${PRIVATE_KEY} --verify --etherscan-api-key ${BASESCAN_API_KEY} -vvvv --broadcast