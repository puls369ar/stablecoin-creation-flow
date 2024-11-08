
// SPDX-License-Identifier: MIT LICENSE



pragma solidity ^0.8.27;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract A4USDReserves is Ownable, ReentrancyGuard, AccessControl {
    using SafeERC20 for IERC20;

    uint256 public currentReserveId;

    struct ReserveVault {
        IERC20 collateral;
        uint256 amount;
    }

    mapping(uint256 => ReserveVault) public _rsvVault;

    event Withdraw (uint256 indexed vid, uint256 amount);
    event Deposit (uint256 indexed vid, uint256 amount);

    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");

    constructor() Ownable(_msgSender()) {
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _grantRole(MANAGER_ROLE, _msgSender());
    }

    modifier checkReserveContract(IERC20 _collateral) {
        for(uint256 i; i < currentReserveId; i++){
            require(_rsvVault[i].collateral != _collateral, "Collateral Address Already Added");
        }
        _;
    }

    function addReserveVault(IERC20 _collateral) onlyRole(MANAGER_ROLE) checkReserveContract(_collateral) external {
        _rsvVault[currentReserveId].collateral = _collateral;
        currentReserveId++;
    }

    function depositCollateral(uint256 vid, uint256 amount) onlyRole(MANAGER_ROLE) external {
        IERC20 reserves = _rsvVault[vid].collateral;
        reserves.safeTransferFrom(address(msg.sender), address(this), amount);
        uint256 currentVaultBalance = _rsvVault[vid].amount;
        _rsvVault[vid].amount = currentVaultBalance + amount;
        emit Deposit(vid, amount);
    }

    function withdrawCollateral(uint256 vid, uint256 amount) onlyRole(MANAGER_ROLE) external {
        IERC20 reserves = _rsvVault[vid].collateral;
        uint256 currentVaultBalance = _rsvVault[vid].amount;
        if (currentVaultBalance >= amount) {
            reserves.safeTransfer(address(msg.sender), amount);
            _rsvVault[vid].amount = currentVaultBalance - amount;
            emit Withdraw(vid, amount);
        }
    }
}
