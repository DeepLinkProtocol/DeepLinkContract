compile:
	npx hardhat compile

deploy:
	npx hardhat run scripts/deploy.ts --network dbcTestnet

upgrade:
	npx hardhat run scripts/upgrade.ts --network dbcTestnet

verify:
	npx hardhat verify --network dbcTestnet  0x5F953D181ED266a925245d26Cc252Ad937001815







