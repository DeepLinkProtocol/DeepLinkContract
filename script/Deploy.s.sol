// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {StakingV5} from "../src/Staking.sol";
import {Upgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";

contract Deploy is Script {
    function run() external returns (address) {
        string memory privateKeyString = vm.envString("PRIVATE_KEY");
        uint256 deployerPrivateKey;

        if (
            bytes(privateKeyString).length > 0 && bytes(privateKeyString)[0] == "0" && bytes(privateKeyString)[1] == "x"
        ) {
            deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        } else {
            deployerPrivateKey = uint256(vm.envBytes32("PRIVATE_KEY"));
        }

        vm.startBroadcast(deployerPrivateKey);

        address proxy = deploy();
        vm.stopBroadcast();
        return address(proxy);
    }

    function deploy() public returns (address) {
        address proxy = Upgrades.deployUUPSProxy(
            "Staking.sol:StakingV4",
            abi.encodeCall(
                StakingV5.initialize,
                (
                    msg.sender,
                    address(0xd6a0843e7c99357ca5bA3525A0dB92F8E5817c07),
                    address(0x2404d15504Bab74185C08f388E63cCC48a218a6A)
                )
            )
        );
        return address(proxy);
    }
}
