// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {Staking} from "../src/StakingOld.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../src/interface/IPrecompileContract.sol";
import {Deploy} from "../script/Deploy2.s.sol";

contract StakingTest is Test {
    Staking public staking;
    address public rewardTokenAddr = address(0x0);
    address public precompileContractAddr = address(0x1);

    function setUp() public {
        Deploy deploy = new Deploy();
        address proxy = deploy.deploy();
        staking = Staking(proxy);
        assertEq(staking.owner(), address(this));

        staking.setRewardToken(rewardTokenAddr);
        staking.setRegisterContract(precompileContractAddr);

        vm.mockCall(
            precompileContractAddr,
            abi.encodeWithSelector(IPrecompileContract.reportDlcStaking.selector),
            abi.encode(true)
        );

        vm.mockCall(
            precompileContractAddr, abi.encodeWithSelector(IPrecompileContract.isSlashed.selector), abi.encode(false)
        );

        vm.mockCall(
            precompileContractAddr,
            abi.encodeWithSelector(IPrecompileContract.getMachineCalcPoint.selector),
            abi.encode(100)
        );
    }

    function test_mock_contract() public {
        vm.mockCall(rewardTokenAddr, abi.encodeWithSelector(IERC20.balanceOf.selector), abi.encode(100000 * 10 ** 18));
        assertEq(staking.rewardToken().balanceOf(msg.sender), 100000 * 10 ** 18);

        vm.mockCall(
            precompileContractAddr,
            abi.encodeWithSelector(IPrecompileContract.getMachineCalcPoint.selector),
            abi.encode(100)
        );
        assertEq(staking.precompileContract().getMachineCalcPoint("111"), 100);
    }

    function test_stake() public {
        string memory machineId = "machineId";
        address stakeHolder = address(0x1);
        vm.prank(stakeHolder);
        staking.stake("abc", "sig", "pubkey", machineId, 0);
        assertTrue(staking.isStaking(machineId));

        {
            // other user stake the same machine should fail
            address stakeHolder2 = address(0x2);
            vm.prank(stakeHolder2);
            vm.expectRevert("machine already staked");
            staking.stake("abc", "sig", "pubkey", "machineId", 0);
            assertTrue(staking.isStaking(machineId));
        }

        {
            // after some time the staking can get reward
            uint256 current_ts = vm.getBlockTimestamp();
            vm.warp(current_ts + 1000000);
            vm.mockCall(
                precompileContractAddr,
                abi.encodeWithSelector(IPrecompileContract.getRentDuration.selector),
                abi.encode(1000000)
            );

            vm.mockCall(
                precompileContractAddr,
                abi.encodeWithSelector(IPrecompileContract.getDlcMachineRentDuration.selector),
                abi.encode(60)
            );

            assertGt(staking.getReward("abc", "sig", "pubkey", machineId), 0);
            assertEq(
                staking.getReward("abc", "sig", "pubkey", machineId),
                staking.getRewardAmountCanClaim("abc", "sig", "pubkey", machineId)
            );
        }
    }
}
