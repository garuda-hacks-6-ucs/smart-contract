// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {BlockTenderID} from "../src/BlockTenderID.sol";

contract BlockTenderIDScript is Script {
    BlockTenderID private _tender;

    function setUp() public {}

    function run() public {
        vm.startBroadcast();

        vm.stopBroadcast();
    }
}
