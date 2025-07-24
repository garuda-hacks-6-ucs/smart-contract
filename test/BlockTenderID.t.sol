// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Test, console} from "forge-std/Test.sol";
import {BlockTenderID} from "../src/BlockTenderID.sol";
import {BlockTenderIDNFT} from "../src/BlockTenderIDNFT.sol";
import {BlockTenderIDTimelock} from "../src/BlockTenderIDTimelock.sol";
import {TokenRakyat} from "../src/TokenRakyat.sol";

contract BlockTenderIDTest is Test {
    BlockTenderID private tender;
    TokenRakyat private token;
    BlockTenderIDNFT private nft;
    BlockTenderIDTimelock private timelock;

    address private constant BOB = address(1);
    address private constant ALICE = address(2);
    address private constant CHARLIE = address(3);

    address[] private _targets = new address[](1);
    uint256[] private _values = new uint256[](1);
    bytes[] private _calldatas = new bytes[](1);
    string private _description = "lorem ipsum dolor sit amet";

    string private _hash = "0xsdia";

    string private _vendorName = "Warung Sederhana";
    string private _vendorNIB = "8123456789012";
    string private _vendorNPWP = "12.345.678.9-012.345";

    string private _governmentAgency = "Kementerian Pendidikan dan Kebudayaan";
    string private _governmentCode = "KEMDIKBUD-001";

    string private _governmentProposalUUID = "GOV-2025-001";
    uint256 private _governmentProposalTokenId = 101;

    string private _vendorProposalUUID = "VENDOR6789-SURABAYA";
    uint256 _vendorProposalTokenId = 102;
    uint256 _fee = 4 ether;

    uint256 _deliverWorkTokenId = 103;

    string private _uri = "ipfs://QmXyz123abc456.../proposal.json";

    uint8 private _support = 1;
    string private _reason = "Nice.";

    address[] private i_proposers;
    address[] private i_executors;
    address private i_admin;

    function setUp() public {
        vm.startBroadcast();
        uint256 minDelay = 10 minutes;
        uint32 votingDelay = 150; // ~10 minutes
        uint32 votingPeriod = 150; // ~10 minutes
        uint256 quorum = 1;

        token = new TokenRakyat();
        nft = new BlockTenderIDNFT();
        timelock = new BlockTenderIDTimelock(
            minDelay,
            i_proposers,
            i_executors,
            i_admin
        );
        tender = new BlockTenderID(
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

    function testSuccessfullyRegisterCitizen() public {
        vm.startPrank(BOB);
        token.delegate(_hash);
        vm.stopPrank();

        uint256 expectedBalance = 1 * 10 ** 18;
        uint256 actualBalance = token.balanceOf(BOB);
        bool expectedRegistrationStatus = true;
        bool actualRegistrationStatus = tender.citizen(BOB).registered;

        assertEq(expectedBalance, actualBalance);
        assert(expectedRegistrationStatus == actualRegistrationStatus);
    }

    function testSuccessfullyRegisterVendor() public {
        vm.startPrank(ALICE);
        tender.registerVendor(_vendorName, _vendorNIB, _vendorNPWP);
        vm.stopPrank();

        bool expectedRegistrationStatus = true;
        bool actualRegistrationStatus = tender.vendor(ALICE).registered;

        assert(expectedRegistrationStatus == actualRegistrationStatus);
    }

    function testSuccessfullyRegisterGovernment() public {
        vm.startPrank(CHARLIE);
        tender.registerGovernment(_governmentAgency, _governmentCode);
        vm.stopPrank();

        bool expectedRegistrationStatus = true;
        bool actualRegistrationStatus = tender.government(CHARLIE).registered;

        assert(expectedRegistrationStatus == actualRegistrationStatus);
    }

    function testSuccessfullyWorksOnIntegrationTesting() public {
        vm.startPrank(BOB);
        token.delegate(_hash);
        vm.stopPrank();

        vm.startPrank(ALICE);
        tender.registerVendor(_vendorName, _vendorNIB, _vendorNPWP);
        vm.stopPrank();

        vm.startPrank(CHARLIE);
        deal(CHARLIE, 10 ether);
        tender.registerGovernment(_governmentAgency, _governmentCode);
        tender.proposeGovernmentProposal{value: 2 ether}(
            _governmentProposalUUID,
            _governmentProposalTokenId,
            _uri
        );
        vm.stopPrank();

        uint256 expectedCharlieBalance = 8 ether;
        uint256 actualCharlieBalance = CHARLIE.balance;
        uint256 expectedTimelockBalance = 2 ether;
        uint256 actualTimelockBalance = tender.blockTenderIDTimelock().balance;

        assertEq(expectedCharlieBalance, actualCharlieBalance);
        assertEq(expectedTimelockBalance, actualTimelockBalance);
        assertEq(0, tender.governmentProposalState(_governmentProposalUUID));
        // console.log(block.timestamp);
        // console.log(
        //     tender
        //         .governmentProposal(_governmentProposalUUID)
        //         .vendorSubmissionStart
        // );

        vm.warp(
            tender
                .governmentProposal(_governmentProposalUUID)
                .vendorSubmissionStart
        );
        // console.log(block.timestamp);

        vm.startPrank(ALICE);
        tender.proposeVendorProposal(
            _governmentProposalUUID,
            _vendorProposalUUID,
            _vendorProposalTokenId,
            _uri,
            2 ether
        );
        vm.stopPrank();

        vm.warp(tender.governmentProposal(_governmentProposalUUID).voteStart);

        vm.startPrank(BOB);
        tender.voteVendorProposal(_governmentProposalUUID, _vendorProposalUUID);
        vm.stopPrank();

        string memory expectedCurrentWinnerVendor = _vendorProposalUUID;
        string memory actualCurrentWinnerVendor = tender.winnerVendor(
            _governmentProposalUUID
        );

        uint256 votesAmount = 1;
        uint256 actualVendorVotes = tender
            .vendorProposal(_governmentProposalUUID, _vendorProposalUUID)
            .totalVotes;
        uint256 actualBobTotalVotes = tender
            .vendorSelectionVoteHistory(BOB)
            .length;

        assertEq(expectedCurrentWinnerVendor, actualCurrentWinnerVendor);
        assertEq(actualVendorVotes, votesAmount);
        assertEq(actualBobTotalVotes, votesAmount);

        vm.warp(tender.governmentProposal(_governmentProposalUUID).voteEnd);

        vm.startPrank(ALICE);
        tender.withdrawInitialPayment(
            _governmentProposalUUID,
            _vendorProposalUUID
        );
        vm.stopPrank();

        uint256 expectedAliceBalanceAfterFirstWithdraw = 1 ether;
        uint256 actualAliceBalanceAfterFirstWithdraw = ALICE.balance;
        uint256 expectedTimelockBalanceAfterFirstWithdraw = 1 ether;
        uint256 actualTimelockBalanceAfterFirstWithdraw = tender
            .blockTenderIDTimelock()
            .balance;

        assertEq(
            expectedAliceBalanceAfterFirstWithdraw,
            actualAliceBalanceAfterFirstWithdraw
        );
        assertEq(
            expectedTimelockBalanceAfterFirstWithdraw,
            actualTimelockBalanceAfterFirstWithdraw
        );

        _targets.push(address(tender));
        _values.push(
            tender
                .vendorProposal(_governmentProposalUUID, _vendorProposalUUID)
                .fee / 2
        );
        _calldatas.push(
            abi.encodeWithSignature(
                "withdrawRemainingPayment(string,string)",
                _governmentProposalUUID,
                _vendorProposalUUID
            )
        );

        vm.startPrank(ALICE);
        tender.deliverWork(
            _targets,
            _values,
            _calldatas,
            _description,
            _deliverWorkTokenId,
            _uri,
            _governmentProposalUUID
        );
        vm.stopPrank();

        uint256 workId = tender.getProposalId(
            _targets,
            _values,
            _calldatas,
            keccak256(bytes(_description))
        );
        uint256 voteStart = tender.proposalSnapshot(workId);

        vm.roll(voteStart + 1);

        vm.startPrank(BOB);
        tender.voteDeliveredWork(workId, _support, _reason);
        vm.stopPrank();

        uint8 activeState = uint8(tender.state(workId));
        assertEq(activeState, 1);

        vm.roll(block.number + tender.votingPeriod() + 1);

        uint8 succeededState = uint8(tender.state(workId));
        assertEq(succeededState, 4);

        vm.startPrank(ALICE);
        tender.queue(
            _targets,
            _values,
            _calldatas,
            keccak256(bytes(_description))
        );
        vm.stopPrank();

        uint8 queuedState = uint8(tender.state(workId));
        assertEq(queuedState, 5);

        vm.warp(block.timestamp + tender.proposalEta(workId) + 1);
        tender.execute(
            _targets,
            _values,
            _calldatas,
            keccak256(bytes(_description))
        );

        uint256 actualAliceBalanceAfterSecondWithdraw = ALICE.balance;
        uint256 expectedAliceBalanceAfterSecondWithdraw = 2 ether;
        uint256 actualTimelockBalanceAfterSecondWithdraw = tender
            .blockTenderIDTimelock()
            .balance;
        uint256 expectedTimelockBalanceAfterSecondWithdraw = 0 ether;

        assertEq(
            expectedAliceBalanceAfterSecondWithdraw,
            actualAliceBalanceAfterSecondWithdraw
        );
        assertEq(
            expectedTimelockBalanceAfterSecondWithdraw,
            actualTimelockBalanceAfterSecondWithdraw
        );
    }
}
