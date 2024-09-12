// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
//
//import {Script} from "forge-std/Script.sol";
//import {Staking} from "../src/StakingOld.sol";
//import {Staking} from "../src/Staking.sol";
//import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
//import {DevOpsTools} from "lib/foundry-devops/src/DevOpsTools.sol";
//
//contract Upgrade is Script {
//    function run() external returns (address) {
//        address mostRecentlyDeployedProxy = DevOpsTools.get_most_recent_deployment("ERC1967Proxy", 198508181);
//
//        vm.startBroadcast();
//        StakingV2 stakingV2 = new StakingV2();
//        vm.stopBroadcast();
//        address proxy = upgrade(mostRecentlyDeployedProxy, address(stakingV2));
//        return proxy;
//    }
//
//    function upgrade(address proxyAddress, address newStaking) public returns (address) {
//        vm.startBroadcast();
//        StakingV2 proxy = StakingV2(payable(proxyAddress));
//        proxy.upgradeToAndCall(address(newStaking), new bytes(0));
//        vm.stopBroadcast();
//        return address(proxy);
//    }
//}
