// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {Staking} from "../src/StakingOld.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract Deploy is Script {
    function run() external returns (address) {
        address proxy = deploy();
        return proxy;
    }

    function deploy() public returns (address) {
        vm.startBroadcast();
        Staking staking = new Staking();
        ERC1967Proxy proxy = new ERC1967Proxy(address(staking), "");
        Staking(address(proxy)).initialize(
            msg.sender,
            address(0xd6a0843e7c99357ca5bA3525A0dB92F8E5817c07),
            address(0x2404d15504Bab74185C08f388E63cCC48a218a6A)
        );
        vm.stopBroadcast();
        return address(proxy);
    }
}
