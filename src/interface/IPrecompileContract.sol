// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IPrecompileContract {
    function getMachineCalcPoint(string memory machineId) external view returns (uint256 calcPoint);
    function getRentDuration(
        string memory msgToSign,
        string memory substrateSig,
        string memory substratePubKey,
        uint256 lastClaimAt,
        uint256 slashClaimAt,
        string memory machineId
    ) external view returns (uint256 rentDuration);
    function getDlcMachineRentDuration(uint256 lastClaimAt, uint256 slashAt, string memory machineId)
        external
        view
        returns (uint256 rentDuration);

    //    function isBothMachineRenterAndOwner(string memory msgToSign,string memory substrateSig,string memory substratePubKey,string memory machineId) external view returns(bool);
    function reportDlcStaking(
        string memory msgToSign,
        string memory substrateSig,
        string memory substratePubKey,
        string memory machineId
    ) external returns (bool success);
    function reportDlcEndStaking(
        string memory msgToSign,
        string memory substrateSig,
        string memory substratePubKey,
        string memory machineId
    ) external returns (bool success);

    function getDlcMachineSlashedAt(string memory machineId) external view returns (uint256);
    function getDlcMachineSlashedReportId(string memory machineId) external view returns (uint256);
    function getDlcMachineSlashedReporter(string memory machineId) external view returns (address);
    function isSlashed(string memory machineId) external view returns (bool slashed);
}
