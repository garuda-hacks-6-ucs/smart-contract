// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Governor} from "@openzeppelin/contracts/governance/Governor.sol";
import {GovernorCountingSimple} from "@openzeppelin/contracts/governance/extensions/GovernorCountingSimple.sol";
import {GovernorSettings} from "@openzeppelin/contracts/governance/extensions/GovernorSettings.sol";
import {GovernorTimelockControl} from "@openzeppelin/contracts/governance/extensions/GovernorTimelockControl.sol";
import {GovernorVotes} from "@openzeppelin/contracts/governance/extensions/GovernorVotes.sol";
import {GovernorVotesQuorumFraction} from "@openzeppelin/contracts/governance/extensions/GovernorVotesQuorumFraction.sol";
import {TimelockController} from "@openzeppelin/contracts/governance/TimelockController.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {TokenRakyat} from "./TokenRakyat.sol";
import {BlockTenderIDNFT} from "./BlockTenderIDNFT.sol";
import {BlockTenderIDTimelock} from "./BlockTenderIDTimelock.sol";
import {Events} from "./lib/Events.l.sol";
import {Errors} from "./lib/Errors.l.sol";

contract BlockTenderID is
    Governor,
    GovernorSettings,
    GovernorCountingSimple,
    GovernorVotes,
    GovernorVotesQuorumFraction,
    GovernorTimelockControl,
    ReentrancyGuard
{
    struct Vendor {
        string name;
        string nib;
        string npwp;
        bool registered;
    }

    struct Government {
        string agency;
        string code;
        bool registered;
    }

    struct Citizen {
        string ktpHash;
        bool registered;
    }

    struct GovernmentProposal {
        address government;
        uint256 tokenId;
        string uri;
        uint256 budget;
        uint256 vendorSubmissionStart;
        // uint256 vendorSubmissionPeriod;
        uint256 voteStart;
        uint256 voteEnd;
    }

    struct VendorProposal {
        address vendor;
        uint256 tokenId;
        string uri;
        uint256 fee;
        uint256 totalVotes;
    }

    struct DeliveredWorkVoteHistory {
        uint256 workId;
        uint8 support;
    }

    struct VendorSelectionVoteHistory {
        string governmentProposalUUID;
        string vendorProposalUUID;
    }

    enum GovernmentProposalState {
        Pending,
        AcceptingVendor,
        Voting,
        End
    }

    mapping(address => Vendor) s_vendor;

    mapping(address => Government) s_government;

    mapping(address => Citizen) s_citizen;

    mapping(string => GovernmentProposal) s_governmentProposal;

    mapping(string => mapping(string => VendorProposal)) s_vendorProposal;

    mapping(string => string) s_winnerVendor;

    mapping(address => VendorSelectionVoteHistory[]) s_vendorSelectionVoteHistory;

    mapping(address => DeliveredWorkVoteHistory[])
        private s_deliveredWorkVoteHistory;

    TokenRakyat i_token;
    BlockTenderIDTimelock i_timelock;
    BlockTenderIDNFT i_nft;

    // uint256[] private workIds;

    uint256 private constant GOVERNMENT_PROPOSAL_VENDOR_SUBMISSION_DELAY =
        1 minutes;
    uint256 private constant GOVERNMENT_PROPOSAL_VENDOR_SUBMISSION_DURATION =
        5 minutes;
    uint256 private constant GOVERNMENT_PROPOSAL_VOTING_DELAY = 1 minutes;
    uint256 private constant GOVERNMENT_PROPOSAL_VOTE_DURATION = 5 minutes;

    modifier checkRegisteredVendor(bool _expected) {
        require(
            s_vendor[msg.sender].registered == _expected,
            Errors.UnexpectedVendorRegistrationStatus(msg.sender)
        );
        _;
    }

    modifier checkRegisteredGovernment(bool _expected) {
        require(
            s_government[msg.sender].registered == _expected,
            Errors.UnexpectedGovernmentRegistrationStatus(msg.sender)
        );
        _;
    }

    modifier checkRegisteredCitizen(bool _expected) {
        require(
            s_citizen[msg.sender].registered == _expected,
            Errors.UnexpectedCitizenRegistrationStatus(msg.sender)
        );
        _;
    }

    modifier checkVoteAvailability() {
        require(
            i_token.balanceOf(msg.sender) == 1 * 10 ** 18,
            Errors.VoteNotAvailable(
                msg.sender,
                1,
                i_token.balanceOf(msg.sender)
            )
        );
        _;
    }

    modifier checkVendorFee(
        uint256 _fee,
        string memory _governmentProposalUUID
    ) {
        require(
            _fee <= s_governmentProposal[_governmentProposalUUID].budget,
            Errors.FeeExceedsBudget(
                _fee,
                s_governmentProposal[_governmentProposalUUID].budget
            )
        );
        _;
    }

    modifier checkGovernmentProposalState(
        string memory _governmentProposalUUID,
        uint8 _expectedState
    ) {
        uint8 actualState = governmentProposalState(_governmentProposalUUID);
        require(
            actualState == _expectedState,
            Errors.InvalidProposalState(_expectedState, actualState)
        );
        _;
    }

    constructor(
        TokenRakyat _token,
        BlockTenderIDTimelock _timelock,
        BlockTenderIDNFT _nft,
        uint48 _votingDelay,
        uint32 _votingPeriod,
        uint256 _quorum
    )
        Governor("BlockTenderIDDAO")
        GovernorSettings(_votingDelay, _votingPeriod, 0)
        GovernorVotes(_token)
        GovernorVotesQuorumFraction(_quorum)
        GovernorTimelockControl(_timelock)
    {
        i_token = _token;
        i_nft = _nft;
        i_timelock = _timelock;
    }

    function registerVendor(
        string memory _name,
        string memory _nib,
        string memory _npwp
    )
        external
        checkRegisteredVendor(false)
        checkRegisteredCitizen(false)
        checkRegisteredGovernment(false)
    {
        s_vendor[msg.sender] = Vendor(_name, _nib, _npwp, true);

        emit Events.VendorRegistered(msg.sender, _name, _nib, _npwp);
    }

    function registerGovernment(
        string memory _agency,
        string memory _code
    )
        external
        checkRegisteredVendor(false)
        checkRegisteredCitizen(false)
        checkRegisteredGovernment(false)
    {
        s_government[msg.sender] = Government(_agency, _code, true);

        emit Events.GovernmentRegistered(msg.sender, _agency, _code);
    }

    function registerCitizen(
        address _citizen,
        string memory _hash
    )
        external
        checkRegisteredVendor(false)
        checkRegisteredCitizen(false)
        checkRegisteredGovernment(false)
    {
        s_citizen[_citizen] = Citizen(_hash, true);

        emit Events.CitizenRegistered(_citizen, _hash);
    }

    function proposeGovernmentProposal(
        string memory _governmentProposalUUID,
        uint256 _tokenId,
        string memory _uri
    ) external payable checkRegisteredGovernment(true) nonReentrant {
        uint256 vendorSubmissionStart = block.timestamp +
            GOVERNMENT_PROPOSAL_VENDOR_SUBMISSION_DELAY;
        // uint256 vendorSubmissionPeriod = vendorSubmissionStart +
        //     GOVERNMENT_PROPOSAL_VENDOR_SUBMISSION_DURATION;
        uint256 voteStart = vendorSubmissionStart +
            GOVERNMENT_PROPOSAL_VOTING_DELAY;
        uint256 voteDuration = voteStart + GOVERNMENT_PROPOSAL_VOTE_DURATION;

        s_governmentProposal[_governmentProposalUUID] = GovernmentProposal(
            msg.sender,
            _tokenId,
            _uri,
            msg.value,
            vendorSubmissionStart,
            // vendorSubmissionPeriod,
            voteStart,
            voteDuration
        );
        i_nft.mint(_tokenId, msg.sender, _uri);
        _transferETH(address(i_timelock), msg.value);
    }

    function proposeVendorProposal(
        string memory _governmentProposalUUID,
        string memory _vendorProposalUUID,
        uint256 _tokenId,
        string memory _uri,
        uint256 _fee
    )
        external
        checkRegisteredVendor(true)
        checkGovernmentProposalState(
            _governmentProposalUUID,
            uint8(GovernmentProposalState.AcceptingVendor)
        )
        checkVendorFee(_fee, _governmentProposalUUID)
    {
        s_vendorProposal[_governmentProposalUUID][
            _vendorProposalUUID
        ] = VendorProposal(msg.sender, _tokenId, _uri, _fee, 0);
        i_nft.mint(_tokenId, msg.sender, _uri);
    }

    function voteVendorProposal(
        string memory _governmentProposalUUID,
        string memory _vendorProposalUUID
    )
        external
        checkVoteAvailability
        checkRegisteredCitizen(true)
        checkGovernmentProposalState(
            _governmentProposalUUID,
            uint8(GovernmentProposalState.Voting)
        )
    {
        s_vendorProposal[_governmentProposalUUID][_vendorProposalUUID]
            .totalVotes += 1;
        s_vendorSelectionVoteHistory[msg.sender].push(
            VendorSelectionVoteHistory(
                _governmentProposalUUID,
                _vendorProposalUUID
            )
        );
        uint256 vendorTotalVotes = s_vendorProposal[_governmentProposalUUID][
            _vendorProposalUUID
        ].totalVotes;

        string memory _winnerVendor = s_winnerVendor[_governmentProposalUUID];

        if (bytes(_winnerVendor).length == 0) {
            s_winnerVendor[_governmentProposalUUID] = _vendorProposalUUID;
        }

        uint256 highestTotalVotes = s_vendorProposal[_governmentProposalUUID][
            s_winnerVendor[_governmentProposalUUID]
        ].totalVotes;

        if (vendorTotalVotes > highestTotalVotes) {
            s_winnerVendor[_governmentProposalUUID] = _vendorProposalUUID;
        }
    }

    function withdrawInitialPayment(
        // uint256 _workId,
        string memory _governmentProposalUUID,
        string memory _vendorProposalUUID
    )
        external
        checkRegisteredVendor(true)
        checkGovernmentProposalState(
            _governmentProposalUUID,
            uint8(GovernmentProposalState.End)
        )
        nonReentrant
    {
        uint256 governmentBudget = s_governmentProposal[_governmentProposalUUID]
            .budget;
        uint256 vendorFee = s_vendorProposal[_governmentProposalUUID][
            _vendorProposalUUID
        ].fee;

        if (governmentBudget > vendorFee) {
            i_timelock.transferETH(
                s_governmentProposal[_governmentProposalUUID].government,
                governmentBudget - vendorFee
            );
        }

        i_timelock.transferETH(
            msg.sender,
            s_vendorProposal[_governmentProposalUUID][_vendorProposalUUID].fee /
                2
        );
    }

    function governmentProposalState(
        string memory _governmentProposalUUID
    ) public view returns (uint8) {
        GovernmentProposal memory _proposal = s_governmentProposal[
            _governmentProposalUUID
        ];
        if (block.timestamp < _proposal.vendorSubmissionStart) {
            return uint8(GovernmentProposalState.Pending);
        } else if (
            block.timestamp >= _proposal.vendorSubmissionStart &&
            block.timestamp < _proposal.voteStart
        ) {
            return uint8(GovernmentProposalState.AcceptingVendor);
        } else if (
            block.timestamp >= _proposal.voteStart &&
            block.timestamp < _proposal.voteEnd
        ) {
            return uint8(GovernmentProposalState.Voting);
        } else {
            return uint8(GovernmentProposalState.End);
        }
    }

    function deliverWork(
        address[] memory _targets,
        uint256[] memory _values,
        bytes[] memory _calldatas,
        string memory _description,
        uint256 _tokenId,
        string memory _uri,
        string memory _governmentProposalUUID
    )
        external
        checkRegisteredVendor(true)
        checkGovernmentProposalState(
            _governmentProposalUUID,
            uint8(GovernmentProposalState.End)
        )
        returns (uint256)
    {
        i_nft.mint(_tokenId, msg.sender, _uri);
        return super.propose(_targets, _values, _calldatas, _description);
    }

    function withdrawRemainingPayment(
        string memory _governmentProposalUUID,
        string memory _vendorProposalUUID
    ) external payable onlyGovernance nonReentrant {
        VendorProposal memory _vendor = s_vendorProposal[
            _governmentProposalUUID
        ][_vendorProposalUUID];

        _transferETH(_vendor.vendor, msg.value);
    }

    function voteDeliveredWork(
        uint256 _workId,
        uint8 _support,
        string calldata _reason
    )
        external
        checkRegisteredCitizen(true)
        checkVoteAvailability
        returns (uint256)
    {
        s_deliveredWorkVoteHistory[msg.sender].push(
            DeliveredWorkVoteHistory(_workId, _support)
        );

        return super.castVoteWithReason(_workId, _support, _reason);
    }

    function _transferETH(address _recipient, uint256 _value) private {
        (bool success, ) = payable(_recipient).call{value: _value}("");
        require(success, Errors.TransferFailed());
    }

    function vendor(address _user) external view returns (Vendor memory) {
        return s_vendor[_user];
    }

    function government(
        address _user
    ) external view returns (Government memory) {
        return s_government[_user];
    }

    function citizen(address _user) external view returns (Citizen memory) {
        return s_citizen[_user];
    }

    function blockTenderIDTimelock() external view returns (address) {
        return address(i_timelock);
    }

    function governmentProposal(
        string memory _governmentProposalUUID
    ) external view returns (GovernmentProposal memory) {
        return s_governmentProposal[_governmentProposalUUID];
    }

    function vendorProposal(
        string memory _governmentProposalUUID,
        string memory _vendorProposalUUID
    ) external view returns (VendorProposal memory) {
        return s_vendorProposal[_governmentProposalUUID][_vendorProposalUUID];
    }

    function vendorSelectionVoteHistory(
        address _user
    ) external view returns (VendorSelectionVoteHistory[] memory) {
        return s_vendorSelectionVoteHistory[_user];
    }

    function deliveredWorkVoteHistory(
        address _user
    ) external view returns (DeliveredWorkVoteHistory[] memory) {
        return s_deliveredWorkVoteHistory[_user];
    }

    function winnerVendor(
        string memory _governmentProposalUUID
    ) external view returns (string memory) {
        return s_winnerVendor[_governmentProposalUUID];
    }

    function state(
        uint256 proposalId
    )
        public
        view
        override(Governor, GovernorTimelockControl)
        returns (ProposalState)
    {
        return super.state(proposalId);
    }

    function proposalNeedsQueuing(
        uint256 proposalId
    ) public view override(Governor, GovernorTimelockControl) returns (bool) {
        return super.proposalNeedsQueuing(proposalId);
    }

    function proposalThreshold()
        public
        view
        override(Governor, GovernorSettings)
        returns (uint256)
    {
        return super.proposalThreshold();
    }

    function _queueOperations(
        uint256 proposalId,
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        bytes32 descriptionHash
    ) internal override(Governor, GovernorTimelockControl) returns (uint48) {
        return
            super._queueOperations(
                proposalId,
                targets,
                values,
                calldatas,
                descriptionHash
            );
    }

    function _executeOperations(
        uint256 proposalId,
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        bytes32 descriptionHash
    ) internal override(Governor, GovernorTimelockControl) {
        super._executeOperations(
            proposalId,
            targets,
            values,
            calldatas,
            descriptionHash
        );
    }

    function _cancel(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        bytes32 descriptionHash
    ) internal override(Governor, GovernorTimelockControl) returns (uint256) {
        return super._cancel(targets, values, calldatas, descriptionHash);
    }

    function _executor()
        internal
        view
        override(Governor, GovernorTimelockControl)
        returns (address)
    {
        return super._executor();
    }
}
