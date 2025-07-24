// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Script, console} from "forge-std/Script.sol";
import {BlockTenderID} from "../src/BlockTenderID.sol";
import {BlockTenderIDNFT} from "../src/BlockTenderIDNFT.sol";
import {BlockTenderIDTimelock} from "../src/BlockTenderIDTimelock.sol";
import {TokenRakyat} from "../src/TokenRakyat.sol";

contract BlockTenderIDScript is Script {
    address[] private i_proposers;
    address[] private i_executors;
    address private i_admin;

    function run() public {
        vm.startBroadcast();
        uint256 minDelay = 10 minutes;
        uint32 votingDelay = 150; // ~10 minutes
        uint32 votingPeriod = 150; // ~10 minutes
        uint256 quorum = 1;

        TokenRakyat token = new TokenRakyat();
        BlockTenderIDNFT nft = new BlockTenderIDNFT();
        BlockTenderIDTimelock timelock = new BlockTenderIDTimelock(
            minDelay,
            i_proposers,
            i_executors,
            i_admin
        );
        BlockTenderID tender = new BlockTenderID(
            token,
            timelock,
            nft,
            votingDelay,
            votingPeriod,
            quorum
        );
        token.setOwner(address(tender));
        timelock.grantRole(address(tender));
        vm.stopBroadcast();
    }
}
