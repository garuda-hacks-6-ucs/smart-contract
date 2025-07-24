// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {BlockTenderID} from "../src/BlockTenderID.sol";
import {BlockTenderIDNFT} from "../src/BlockTenderIDNFT.sol";
import {BlockTenderIDTimelock} from "../src/BlockTenderIDTimelock.sol";
import {TokenRakyat} from "../src/TokenRakyat.sol";

contract BlockTenderIDTest is Test {
    BlockTenderID private _tender;

    function setUp() public {
        // _tender = new BlockTenderID();
    }
}
