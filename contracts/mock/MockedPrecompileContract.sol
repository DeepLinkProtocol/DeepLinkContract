
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "../interface/IPrecompileContract.sol";

// Uncomment this line to use console.log
// import "hardhat/console.sol";

contract MockedAIProjectRegister is IPrecompileContract {



    function getMachineCalcPoint(string memory machineId) public pure returns (uint256){
        return 1000;
    }

    function getRentDuration(string memory msgToSign,string memory substrateSig,string memory substratePubKey,uint256 lastClaimAt, uint256 slashAt,string memory machineId) external pure returns (uint256 rentDuration){
        return 1000;
    }

    function isBothMachineRenterAndOwner(string memory msgToSign,string memory substrateSig,string memory substratePubKey,string memory machineId) external pure returns(bool){
        return true;
    }

    function reportStaking(string memory msgToSign,string memory substrateSig,string memory substratePubKey,string memory machineId) external view returns(bool){
        return true;
    }


    function getSlashedAt(string memory machineId) external pure returns(uint256){
        return 0;
    }

    function getSlashedReportId(string memory machineId) external pure returns(uint256){
        return 0;
    }
    function getSlashedReporter(string memory _machineId) external pure returns(address){
        return address(0);
    }
}
