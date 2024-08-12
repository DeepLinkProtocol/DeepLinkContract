// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface IPrecompileContract {
    function getMachineCalcPoint(string memory machineId) external view returns (uint256 calcPoint);
    function getRentDuration(string memory msgToSign,string memory substrateSig,string memory substratePubKey,uint256 lastClaimAt,uint256 slashClaimAt, string memory machineId) external view returns (uint256 rentDuration);

    function isBothMachineRenterAndOwner(string memory msgToSign,string memory substrateSig,string memory substratePubKey,string memory machineId) external view returns(bool);
    function reportStaking(string memory msgToSign,string memory substrateSig,string memory substratePubKey,string memory machineId) external view returns(bool);
    function getSlashedAt(string memory machineId) external view returns(uint256);
    function getSlashedReportId(string memory machineId) external view returns(uint256);
    function getSlashedReporter(string memory machineId) external view returns(address);
}