# directions for use

## directions for use of minter
testnet call function endpoint:
https://blockscout-testnet.dbcscan.io/address/0xd99B9dDD026D13886dbcc1bfBe7e8bb2195B1185?tab=write_proxy
testnet DLC staking contract address：0x5F953D181ED266a925245d26Cc252Ad937001815，
testnet DLC token contract address：0x82b1a3d719dDbFDa07AD1312c3063a829e1e66F1
### Staking
    1. Rent your own machine in the DBC Mainnet/Testnet wallet
    2. Call stake(..) function in the DLC staking contract on DBC mainnet evm/testnet evm
### Claim reward
    1. Call claim(..) function in the DLC staking contract on DBC mainnet evm/testnet evm
### End staking
    1. Call unStakeAndClaim(..) function in the DLC staking contract on DBC mainnet evm/testnet evm
### Find out how much you have been slashed for being reported
    1. Call getLeftSlashedAmount(..) function in the DLC staking contract on DBC mainnet evm/testnet evm
### Find out how much you can claim your reward
    1. Call getRewardAmountCanClaim(..) function in the DLC staking contract on DBC mainnet evm/testnet evm
### Find out if a machine is staking
    1. Call isStaking(..) function in the DLC staking contract on DBC mainnet evm/testnet evm
### Find out how much you reserved for staking
    1. Call stakeholder2Reserved(..) function in the DLC staking contract on DBC mainnet evm/testnet evm

## ## directions for use of renter
### rent
    1. Check the id of the machine that can be rented in the dlcMachineIdsInStaking function of the dlcMachine module of the DBC Mainnet/Testnet wallet
![img.png](img.png)

    2. Rent a machine by calling the rentDlcMachine function of the rentDLCMachine module and fill in the relevant parameters
![img_1.png](img_1.png)

### report fault machine
    1. report by calling the reportDlcMachineFault function of the maintainCommittee module of the DBC mainnet/testnet wallet, fill in the relevant parameters, and two days after the report is approved, the evm wallet address provided by the reporter will be transferred to the report reward
