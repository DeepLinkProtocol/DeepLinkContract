const { ethers, upgrades } = require("hardhat");

async function main() {
    const contract = await ethers.getContractFactory("Staking");

    const r = await upgrades.upgradeProxy(
        process.env.PROXY_CONTRACT,
        contract,
        {txOverrides: {gasLimit: 3000000}}
    );
    r.waitForDeployment();
    console.log("contract upgraded",process.env.PROXY_CONTRACT);
}

main();