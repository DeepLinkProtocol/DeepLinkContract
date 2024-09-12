build:
	forge build

test:
	forge test

fmt:
	forge fmt

deploy:
	forge script script/Deploy.s.sol:Deploy --rpc-url dbc-testnet --private-key $(PRIVATE_KEY) --broadcast -g 200 --verify --verifier blockscout --verifier-url $(VERIFIER_URL) --force

upgrade:
	forge script script/Upgrade.s.sol:Upgrade --rpc-url dbc-testnet --broadcast -g 2000 --verify --verifier blockscout --verifier-url $(VERIFIER_URL) --force

remapping:
	forge remappings > remappings.txt


