// SPDX-License-Identifier: MIT LICENSE



pragma solidity ^0.8.27;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
import "./A4USD.sol";
import "./A4USDReserves.sol";

contract A4USDGovernance is Ownable, ReentrancyGuard, AccessControl { 
    using SafeERC20 for IERC20;

    struct SupChange {    // logging change in stablecoin's supply
        string method;
        uint256 amount;
        uint256 timestamp;
        uint256 blocknum;
    }

    struct ReserveList {  // Instances of collateral tokens
        IERC20 colToken;
    }

    

    mapping (uint256 => ReserveList) public rsvList;  // mapping connecting id to the collateral token
    AggregatorV3Interface private priceOracle;
    A4USD private a4usd;
    //
    address private reserveContract;
    uint256 public a4usdsupply;             
    uint256 public supplyChangeCount;       

    uint256 public stableColatPrice; // Obtained by oracle using feeding `datafeed` value to the `AggregatorV3Interface` interface 
    uint256 public stableColatAmount;
    address public datafeed;



    uint256 private constant COL_PRICE_TO_WEI = 1e10;
    uint256 private constant WEI_VALUE = 1e18;
    
    uint256 public reserveCount;

    mapping (uint256 => SupChange) public _supplyChanges;

    bytes32 public constant GOVERN_ROLE = keccak256("GOVERN_ROLE");

    event RepegAction(uint256 time, uint256 amount);
    event Withdraw(uint256 time, uint256 amount);

    constructor(A4USD _a4usd) Ownable(_msgSender()) {
        a4usd = _a4usd;
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _grantRole(GOVERN_ROLE, _msgSender());
    }

    function setDataFeedAddress(address contractaddress) external onlyRole(GOVERN_ROLE) {
        datafeed = contractaddress;
        priceOracle = AggregatorV3Interface(datafeed);
    }

    function fetchColPrice() external nonReentrant onlyRole(GOVERN_ROLE) {
        ( , uint256 price, , , ) = priceOracle.latestRoundData();
        uint256 value = (price)*COL_PRICE_TO_WEI;
        stableColatPrice = value;
    }

    

    function setReserveContract(address reserve) external nonReentrant onlyRole(GOVERN_ROLE) {
        reserveContract = reserve;
    }

    function colateralRebalancing() internal onlyRole(GOVERN_ROLE) returns (bool) {
        uint256 stableBalance = rsvList[0].colToken.balanceOf(reserveContract);
        if (stableBalance != stableColatAmount) {
            stableColatAmount = stableBalance;
        }
       
        return true;
    }

    function seta4USDSupply(uint256 totalSupply) external onlyRole(GOVERN_ROLE) {
         a4usdsupply = totalSupply;
    }

    function validatePeg() external nonReentrant onlyRole(GOVERN_ROLE) {
        bool result = colateralRebalancing();
        if (result = true) {
            uint256 rawcolvalue = (stableColatAmount*WEI_VALUE);
            uint256 colvalue = rawcolvalue/WEI_VALUE;
            if (colvalue < a4usdsupply) {
                uint256 supplyChange = a4usdsupply-colvalue;
                A4USDReserves(reserveContract).withdrawCollateral(0, supplyChange);
                _supplyChanges[supplyChangeCount].method = "Burn";
                _supplyChanges[supplyChangeCount].amount = supplyChange;
            }
            if (colvalue > a4usdsupply) {
                uint256 supplyChange = colvalue-a4usdsupply;
                A4USDReserves(reserveContract).depositCollateral(0, supplyChange);
                _supplyChanges[supplyChangeCount].method = "Mint";
                _supplyChanges[supplyChangeCount].amount = supplyChange;
            }
        a4usdsupply = colvalue;
        _supplyChanges[supplyChangeCount].blocknum = block.number;
        _supplyChanges[supplyChangeCount].timestamp = block.timestamp;
        supplyChangeCount++;
        emit RepegAction(block.timestamp, colvalue);
        }
    }

    function withdraw(uint256 _amount) external nonReentrant onlyRole(GOVERN_ROLE) {
        a4usd.transfer(address(msg.sender), _amount);
        emit Withdraw(block.timestamp, _amount);
    }
}

