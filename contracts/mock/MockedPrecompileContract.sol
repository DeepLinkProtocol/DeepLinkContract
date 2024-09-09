
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

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


    function reportDlcStaking(string memory msgToSign,string memory substrateSig,string memory substratePubKey,string memory machineId) external view returns(bool){
        return true;
    }

    function reportDlcEndStaking(string memory msgToSign,string memory substrateSig,string memory substratePubKey,string memory machineId) external view returns(bool){
        return true;
    }


    function getDlcMachineSlashedAt(string memory machineId) external pure returns(uint256){
        return 1;
    }

    function getDlcMachineSlashedReportId(string memory machineId) external pure returns(uint256){
        return 1;
    }
    function getDlcMachineSlashedReporter(string memory _machineId) external pure returns(address){
        return address(0);
    }

    function getDlcMachineRentDuration(uint256 lastClaimAt,uint256 slashAt, string memory machineId) external view returns (uint256 rentDuration){
        return 500;
    }

    function isSlashed(string memory machineId) external view returns (bool slashed){
        return false;
    }
}
