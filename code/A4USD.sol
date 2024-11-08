
// SPDX-License-Identifier: MIT LICENSE


pragma solidity ^0.8.27;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";


contract A4USD is ERC20, ERC20Burnable, Ownable, AccessControl {

    using SafeERC20 for ERC20;

    mapping (address => uint256) private _balances;

    uint256 private _totalSupply;

    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");

    constructor () ERC20("A4USD Stable", "A4USD") Ownable(_msgSender()) {
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _grantRole(MANAGER_ROLE, _msgSender());
    }

    function mint(uint256 amount) external onlyRole(MANAGER_ROLE) {
        _totalSupply = _totalSupply + amount;
        _balances[msg.sender] = _balances[msg.sender] + amount;
        _mint(msg.sender, amount);
    }
}
