// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20PermitUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/extensions/AccessControlDefaultAdminRulesUpgradeable.sol";
import "abdk-libraries-solidity/ABDKMath64x64.sol";
import "./lib/MachineRoles.sol";
import "./lib/Roles.sol";
import "./interface/IPrecompileContract.sol";
import "./rolesManager/ReportRoleManger.sol";
import "./slashMachineReporter/SlashMachineReporter.sol";

contract Staking is Initializable, OwnableUpgradeable,ReporterRoleManager,SlashMachineReporter{
//    using Math for uint256;
    IPrecompileContract public precompileContract;
    uint256 public constant secondsPerBlock = 30;
    IERC20 public rewardToken;
    uint256 public rewardAmountPerSecond;
    uint256 public constant baseReserveAmount = 10_000 * 10**18;

    uint256 public totalStakedMachineMultiCalcPoint;
    uint256 public nonlinearCoefficient;

    mapping(address => uint256) public stakeholder2Reserved;
    mapping(string => address) public machineId2Address;
    uint256  public startAt;
    uint256 constant public oneYearSeconds =365*24*60*60;
    uint256 slashAmountOfReport;

    struct StakeInfo {
        uint256 startAtBlockNumber;
        uint256 lastClaimAtBlockNumber;
        uint256 endAtBlockNumber;
        uint256 calcPoint;
        uint256 reservedAmount;
    }

    struct SlashPayedDetail{
        uint256 fromReservedAmount;
        uint256 fromRewardAmount;
        uint256 totalPayedAmount;
        uint256 at;
    }

    struct SlashPayedInfo{
        uint256 totalPayedAmount;
        SlashPayedDetail[] details;
    }

    mapping(uint256 => SlashPayedInfo) public slashReportId2SlashPaidInfo;

    enum ReportType{
        Timeout,
        Offline
    }

    mapping(address => mapping(string => StakeInfo)) public address2StakeInfos;


    event baseRewardAmountPerSecondChanged(uint256 baseRewardAmountPerSecond);
    event nonlinearCoefficientChanged(uint256 nonlinearCoefficient);


    event staked(address indexed stakeholder, string machineId,uint256 stakeAtBlockNumber);
    event unStaked(address indexed stakeholder, string machineId, uint256 unStakeAtBlockNumber);
    event claimed(address indexed stakeholder, string machineId, uint256 rewardAmount,uint256 slashAmount, uint256 claimAtBlockNumber);
    event claimedAll(address indexed stakeholder, uint256 claimAtBlockNumber);

    function initialize(address _initialOwner, address _rewardToken, uint256 _rewardAmountPerSecond,address _registerContract) public initializer {
        __Ownable_init(_initialOwner);
        rewardToken = IERC20(_rewardToken);
        rewardAmountPerSecond = _rewardAmountPerSecond;
        precompileContract = IPrecompileContract(_registerContract);
        startAt = block.number;
        slashAmountOfReport = 10000*10**18;
    }

    function setRegisterContract(address _registerContract) onlyOwner external {
        precompileContract = IPrecompileContract(_registerContract);
    }


    function claimLeftRewardTokens() external onlyOwner {
        uint256 balance = rewardToken.balanceOf(address(this));
        rewardToken.transfer(msg.sender, balance);
    }

    function rewardTokenBalance() public onlyOwner view returns (uint256) {
        return rewardToken.balanceOf(address(this));
    }

    function setRewardToken(address token) onlyOwner external  {
        rewardToken = IERC20(token);
    }

    function setBaseRewardAmountPerSecond(
        uint256 _rewardAmountPerSecond
    ) public onlyOwner {
        rewardAmountPerSecond = _rewardAmountPerSecond;
        emit baseRewardAmountPerSecondChanged(_rewardAmountPerSecond);
    }

    function setNonlinearCoefficient(uint256 value) public onlyOwner {
        nonlinearCoefficient = value;
        emit nonlinearCoefficientChanged(value);
    }

    function rewardPerSecond() public view returns(uint256) {
        uint currentTime = block.number;
        uint256 result = (currentTime-startAt)*secondsPerBlock / oneYearSeconds;
        return  rewardAmountPerSecond/(result+1);
    }

    function stake(string memory msgToSign,string memory substrateSig,string memory substratePubKey,string memory machineId,uint256 amount) external {

        address stakeholder = msg.sender;
        require(stakeholder != address(0), "invalid stakeholder address");
        require(isBothMachineRenterAndOwner(msgToSign,substrateSig,substratePubKey,machineId), "not the renter of the machine");

        StakeInfo storage stakeInfo = address2StakeInfos[stakeholder][machineId];
        if (getSlashedAt(machineId) > 0){
            uint256 shouldSlashAmount = getLeftSlashedAmount(machineId);
            require(amount >= shouldSlashAmount,"should pay slash amount before stake");
            address reporter = getSlashedReporter(machineId);
            require(reporter != address(0), "reporter not found");
            rewardToken.transferFrom(stakeholder, reporter, shouldSlashAmount);
            amount -= shouldSlashAmount;
            setSlashedPayedDetail(machineId, shouldSlashAmount, 0);
        } else {
            require(stakeInfo.startAtBlockNumber == 0, "machine already staked");
            require(stakeInfo.endAtBlockNumber == 0, "machine staked not end");
        }

        stakeholder2Reserved[stakeholder] += amount;
        if (amount > 0) {
            rewardToken.transferFrom(stakeholder, address(this), amount);
        }

        uint256 calcPoint = getMachineCalcPoint(machineId);
        uint256 currentTime = block.number;
        address2StakeInfos[stakeholder][machineId] = StakeInfo({
            startAtBlockNumber: currentTime,
            lastClaimAtBlockNumber: currentTime,
            endAtBlockNumber: 0,
            calcPoint: calcPoint,
            reservedAmount: amount
        });

        machineId2Address[machineId] = stakeholder;
        totalStakedMachineMultiCalcPoint+= calcPoint;
        emit staked(stakeholder, machineId, block.number);
    }

    function getMachineCalcPoint(string memory machineId) internal view returns (uint256) {
        return precompileContract.getMachineCalcPoint(machineId);
    }


    function getRentDuration(string memory msgToSign,string memory substrateSig,string memory substratePubKey,uint256 lastClaimAt,uint256 slashAt, string memory machineId) public view returns (uint256) {
        return precompileContract.getRentDuration(msgToSign,substrateSig,substratePubKey,lastClaimAt,slashAt,machineId);
    }

    function isBothMachineRenterAndOwner(string memory msgToSign,string memory substrateSig,string memory substratePubKey,string memory machineId) public view returns(bool){
        return precompileContract.isBothMachineRenterAndOwner(msgToSign,substrateSig,substratePubKey,machineId);
    }

    function reportStaking(string memory msgToSign,string memory substrateSig,string memory substratePubKey,string memory machineId) public view returns(bool){
        return precompileContract.reportStaking(msgToSign,substrateSig,substratePubKey,machineId);
    }

    function getSlashedAt(string memory machineId) public view returns(uint256){
        uint256 slashReportId =  precompileContract.getSlashedReportId(machineId);
        if (slashReportId == 0){
            return 0;
        }
        SlashPayedInfo storage slashPayedInfo = slashReportId2SlashPaidInfo[slashReportId];
        if (slashPayedInfo.totalPayedAmount == slashAmountOfReport){
            return 0;
        }
        return precompileContract.getSlashedAt(machineId);
    }

    function getLeftSlashedAmount(string memory machineId) public view returns(uint256){
        uint256 slashReportId =  precompileContract.getSlashedReportId(machineId);
        SlashPayedInfo storage slashPayedInfo = slashReportId2SlashPaidInfo[slashReportId];
        return slashAmountOfReport - slashPayedInfo.totalPayedAmount;
    }

    function setSlashedPayedDetail(string memory machineId, uint256 fromReservedAmount, uint256 fromRewardAmount) internal {
        uint256 total = fromReservedAmount+fromRewardAmount;
        uint256 slashReportId =  precompileContract.getSlashedReportId(machineId);
        SlashPayedInfo storage slashPayedInfo = slashReportId2SlashPaidInfo[slashReportId];
        slashPayedInfo.details.push(SlashPayedDetail({
            fromReservedAmount: fromReservedAmount,
            fromRewardAmount: fromRewardAmount,
            totalPayedAmount: slashPayedInfo.totalPayedAmount + total,
            at: block.number
        }));
        slashPayedInfo.totalPayedAmount += total;
        slashReportId2SlashPaidInfo[slashReportId] = slashPayedInfo;
    }

    function getSlashedReportId(string memory machineId) external view returns(uint256){
        return precompileContract.getSlashedReportId(machineId);
    }

    function getSlashedReporter(string memory machineId) public view returns(address){
        return precompileContract.getSlashedReporter(machineId);
    }


    function _getTotalRewardAmount(string memory msgToSign,string memory substrateSig,string memory substratePubKey,string memory machineId, StakeInfo storage stakeInfo) internal view returns (uint256) {
        if (stakeInfo.lastClaimAtBlockNumber == 0){
            return 0;
        }
        uint256 slashedAt = getSlashedAt(machineId);
        uint256 totalRewardDuration = _getStakeHolderRentDuration(msgToSign,substrateSig,substratePubKey,stakeInfo.lastClaimAtBlockNumber,slashedAt,machineId);

        uint256 rewardPerSecond = rewardPerSecond();
        uint256 rentDuration = _getDLCUserRentDuration(msgToSign,substrateSig,substratePubKey,stakeInfo.lastClaimAtBlockNumber,slashedAt,machineId);
        uint256 totalBaseReward = rewardPerSecond * (totalRewardDuration-rentDuration) + rewardPerSecond* 13/10 *rentDuration;

        uint256 _totalStakedMachineMultiCalcPoint = totalStakedMachineMultiCalcPoint;
        if (slashedAt  > 0){
            _totalStakedMachineMultiCalcPoint += stakeInfo.calcPoint;
        }
        uint256 baseRewardAmount = totalBaseReward * stakeInfo.calcPoint / _totalStakedMachineMultiCalcPoint;
        uint256 value = 0;
        if (stakeInfo.reservedAmount > baseReserveAmount) {
            value = stakeInfo.reservedAmount - baseReserveAmount;
        }
        uint256 tmp = 1 + value/baseReserveAmount;
        int128 ln = ABDKMath64x64.fromUInt(tmp);
        uint256 totalRewardAmount = baseRewardAmount* (1+nonlinearCoefficient *ABDKMath64x64.toUInt(ln));

        return totalRewardAmount;
    }

    function getRewardAmountCanClaim(string memory msgToSign,string memory substrateSig,string memory substratePubKey,string memory machineId) public view returns (uint256) {
        address stakeholder = machineId2Address[machineId];
        StakeInfo storage stakeInfo = address2StakeInfos[stakeholder][machineId];

        uint256 totalRewardAmount = _getTotalRewardAmount(msgToSign,substrateSig,substratePubKey,machineId,stakeInfo);
        uint256 slashAmount = getLeftSlashedAmount(machineId);
        if (slashAmount > 0){
            if ( totalRewardAmount >= slashAmount){
                return totalRewardAmount - slashAmount;
            }else{
                return 0;
            }
        }
        return totalRewardAmount;
    }

    function _getStakeHolderRentDuration(string memory msgToSign,string memory substrateSig,string memory substratePubKey,uint256 lastClaimAt,uint256 slashAt, string memory machineId) internal view returns(uint256) {
        return getRentDuration(msgToSign,substrateSig,substratePubKey, lastClaimAt,slashAt,machineId);
    }

    function _getDLCUserRentDuration(string memory msgToSign,string memory substrateSig,string memory substratePubKey,uint256 lastClaimAt,uint256 slashAt, string memory machineId) internal view returns(uint256) {
        // todo
        return getRentDuration(msgToSign,substrateSig,substratePubKey, lastClaimAt,slashAt,machineId);
    }

    function getReward(string memory msgToSign, string memory substrateSig,string memory substratePubKey,string memory machineId) external view returns (uint256) {
        address stakeholder = machineId2Address[machineId];
        StakeInfo storage stakeInfo = address2StakeInfos[stakeholder][machineId];
        return _getTotalRewardAmount(msgToSign,substrateSig,substratePubKey,machineId, stakeInfo);
    }

    function claim(string memory msgToSign,string memory substrateSig,string memory substratePubKey,string memory machineId) public canClaim(machineId) {
        address stakeholder = msg.sender;
        StakeInfo storage stakeInfo = address2StakeInfos[stakeholder][machineId];

        uint256 rewardAmount = _getTotalRewardAmount(msgToSign,substrateSig,substratePubKey,machineId,stakeInfo);
        uint256 leftSlashAmount = getLeftSlashedAmount(machineId);

        if (getSlashedAt(machineId) > 0){
            if (rewardAmount >=  leftSlashAmount) {
                rewardAmount = rewardAmount - leftSlashAmount;
                address reporter = getSlashedReporter(machineId);
                require(reporter != address(0), "reporter not found");
                rewardToken.transfer(reporter, leftSlashAmount);
                setSlashedPayedDetail(machineId, 0, leftSlashAmount);
            }else {
                rewardAmount = 0;
                uint256 leftSlashAmountAfterPayedReward = leftSlashAmount-rewardAmount;
                uint256 reservedAmount = stakeholder2Reserved[stakeholder];
                uint256 paidSlashAmountFromReserved = 0;
                if (reservedAmount >= leftSlashAmountAfterPayedReward){
                    paidSlashAmountFromReserved = leftSlashAmountAfterPayedReward;
                    stakeholder2Reserved[stakeholder] = reservedAmount-leftSlashAmountAfterPayedReward;
                }else{
                    leftSlashAmountAfterPayedReward = reservedAmount;
                    stakeholder2Reserved[stakeholder] = 0;
                }
                address reporter = getSlashedReporter(machineId);
                require(reporter != address(0), "reporter not found");
                rewardToken.transfer(reporter, paidSlashAmountFromReserved + rewardAmount);
                setSlashedPayedDetail(machineId, paidSlashAmountFromReserved, rewardAmount);
            }
        }

        if (rewardAmount > 0){
            rewardToken.transfer(stakeholder, rewardAmount);
        }
        stakeInfo.lastClaimAtBlockNumber = block.number;

        emit claimed(stakeholder, machineId, rewardAmount, leftSlashAmount, block.number);
    }

    modifier canClaim(string memory machineId) {
        address stakeholder = machineId2Address[machineId];
        require(stakeholder != address(0), "Invalid stakeholder address");
        require(
            address2StakeInfos[stakeholder][machineId].startAtBlockNumber > 0,
            "staking not found"
        );

        require(machineId2Address[machineId]!= address(0), "machine not found");
        _;
    }

    function unStakeAndClaim(string memory msgToSign,string memory substrateSig,string memory substratePubKey,string calldata machineId) public {
        address stakeholder = msg.sender;
        require(
            address2StakeInfos[stakeholder][machineId].startAtBlockNumber > 0,
            "staking not found"
        );

        require(machineId2Address[machineId]!= address(0), "machine not found");
        if (getSlashedAt(machineId)){
            require((block.number - address2StakeInfos[stakeholder][machineId].startAtBlockNumber)*secondsPerBlock >= 30*24*60*60, "staking period must more than 30 days");
        }
        _unStakeAndClaim(msgToSign,substrateSig,substratePubKey,machineId,stakeholder);
    }

    function _unStakeAndClaim(string memory msgToSign,string memory substrateSig,string memory substratePubKey,string calldata machineId,address stakeholder) internal {
        claim(msgToSign,substrateSig,substratePubKey,machineId);
        uint256 reservedAmount = stakeholder2Reserved[stakeholder];
        if (reservedAmount > 0) {
            stakeholder2Reserved[stakeholder] = 0;
            rewardToken.transfer(stakeholder, reservedAmount);
        }

        uint256 currentTime = block.number;
        StakeInfo storage stakeInfo =  address2StakeInfos[stakeholder][machineId];
        stakeInfo .endAtBlockNumber = currentTime;
        machineId2Address[machineId]= address(0);
        totalStakedMachineMultiCalcPoint -= stakeInfo .calcPoint;
        emit unStaked(msg.sender,machineId, currentTime);
    }

    function getStakeHolder(string calldata machineId) external view returns(address)  {
        return machineId2Address[machineId];
    }

    function isStaking(string calldata machineId) public view returns(bool)  {
        address stakeholder = machineId2Address[machineId];
        StakeInfo storage stakeInfo = address2StakeInfos[stakeholder][machineId];
        return stakeholder != address(0) && stakeInfo.startAtBlockNumber > 0 && stakeInfo.endAtBlockNumber == 0 &&getSlashedAt(machineId) == 0;
    }
}