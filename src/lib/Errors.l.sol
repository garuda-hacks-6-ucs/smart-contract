// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

library Errors {
    error UnexpectedVendorRegistrationStatus(address caller);

    error UnexpectedGovernmentRegistrationStatus(address caller);

    error UnexpectedCitizenRegistrationStatus(address caller);

    error VoteNotAvailable(address sender, uint256 balanceRequired, uint256 actualBalance);

    error OfferingNotAvailable(address vendor, string uuid);

    error InvalidDeliveryState(uint8 expected, uint8 actual);

    error InvalidProposalState(uint8 expected, uint8 actual);

    error TransferFailed();

    error AlreadyGranted();
}
