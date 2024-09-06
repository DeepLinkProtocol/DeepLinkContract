compile:
	npx hardhat compile

deploy:
	npx hardhat run scripts/deploy.ts --network dbcTestnet

upgrade:
	npx hardhat run scripts/upgrade.ts --network dbcTestnet

verify:
	npx hardhat verify --network dbcTestnet  0xd99B9dDD026D13886dbcc1bfBe7e8bb2195B1185







