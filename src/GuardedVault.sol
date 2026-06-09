// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

contract GuardedVault {
    address public guardian;
    address public owner;
    bool public paused;
    mapping(address => uint256) public balances;
    mapping(address => bool) public blacklisted;

    event Paused();
    event Blacklisted(address indexed who);

    modifier whenNotPaused() { require(!paused, "PAUSED"); _; }
    modifier onlyGuardian() { require(msg.sender == guardian, "NOT_GUARDIAN"); _; }

    constructor() { owner = msg.sender; guardian = msg.sender; }

    function setGuardian(address g) external { require(msg.sender == owner, "NOT_OWNER"); guardian = g; }

    function deposit() external payable whenNotPaused { balances[msg.sender] += msg.value; }

    // intentionally naive (the "vulnerable" surface your judges watch)
    function withdraw(uint256 amt) external whenNotPaused {
        require(!blacklisted[msg.sender], "BLACKLISTED");
        require(balances[msg.sender] >= amt, "INSUFFICIENT");
        (bool ok, ) = msg.sender.call{value: amt}("");   // <-- reentrancy seam
        require(ok, "XFER_FAIL");
        unchecked { balances[msg.sender] -= amt; } // naive: no overflow guard, reentrancy drains vault
    }

    function pause() external onlyGuardian { paused = true; emit Paused(); }
    function blacklist(address who) external onlyGuardian { blacklisted[who] = true; emit Blacklisted(who); }
}
