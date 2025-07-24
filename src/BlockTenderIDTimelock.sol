// SPDX-License-Identifier: MIT

pragma solidity ^0.8.28;

import {TimelockController} from "@openzeppelin/contracts/governance/TimelockController.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {Errors} from "../src/lib/Errors.l.sol";
import {Events} from "../src/lib/Events.l.sol";

contract BlockTenderIDTimelock is TimelockController, ReentrancyGuard {
    bool private _isInit;

    modifier onlyOnce() {
        require(!_isInit, Errors.AlreadyGranted());
        _;
    }

    constructor(
        uint256 _minDelay,
        address[] memory _proposers,
        address[] memory _executors,
        address _admin
    ) TimelockController(_minDelay, _proposers, _executors, _admin) {}

    function transferETH(address _recipient, uint256 _value) external payable nonReentrant {
        (bool success, ) = _recipient.call{value: _value}("");
        require(success, Errors.TransferFailed());
    }

    function grantRole(address _admin) external onlyOnce {
        _grantRole(PROPOSER_ROLE, _admin);
        _grantRole(CANCELLER_ROLE, _admin);
        _grantRole(EXECUTOR_ROLE, _admin);
        _isInit = true;

        emit Events.Granted(_admin, _admin, _admin);
    }
}
