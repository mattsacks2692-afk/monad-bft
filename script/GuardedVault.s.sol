// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import "../src/GuardedVault.sol";

contract DeployGuardedVault is Script {
    function run() external {
        vm.startBroadcast();
        GuardedVault vault = new GuardedVault();
        console.log("GuardedVault deployed at:", address(vault));
        vm.stopBroadcast();
    }
}
