// SPDX-License-Identifier: MIT

pragma solidity ^0.8.28;

library Events {
    event VendorRegistered(
        address indexed vendor,
        string name,
        string nib,
        string npwp
    );

    event GovernmentRegistered(
        address indexed government,
        string agency,
        string code
    );

    event CitizenRegistered(address indexed citizen, string hash);

    event OfferingUpserted(
        address indexed vendor,
        string uuid,
        string name,
        uint256 price,
        uint256 stock
    );

    event OfferingDeleted(address indexed vendor, string uuid);

    event OfferingPurchased(
        address indexed vendor,
        string uuid,
        uint256 amount
    );

    // event Received(address caller, uint256 value);

    event Granted(address proposer, address canceller, address executor);
}
