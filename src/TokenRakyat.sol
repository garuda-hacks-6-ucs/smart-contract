// SPDX-License-Identifier: MIT

pragma solidity ^0.8.28;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ERC20Votes} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";
import {ERC20Permit} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {Nonces} from "@openzeppelin/contracts/utils/Nonces.sol";
import {BlockTenderID} from "../src/BlockTenderID.sol";
import {Errors} from "../src/lib/Errors.l.sol";
import {Events} from "../src/lib/Events.l.sol";
import {console} from "forge-std/console.sol";

contract TokenRakyat is ERC20, ERC20Votes, ERC20Permit, ReentrancyGuard {
    address private s_owner;

    uint256 private constant DELEGATE_REWARD = 1 * 10 ** 18;

    constructor() ERC20("TokenRakyat", "TR") ERC20Permit("TokenRakyat") {}

    function delegate(string memory _hash) external nonReentrant {
        BlockTenderID(payable(s_owner)).registerCitizen(msg.sender, _hash);
        super.delegate(msg.sender);
        _mint(msg.sender, DELEGATE_REWARD);

        // emit Events.Delegated(msg.sender);
    }

    function setOwner(address _contract) external {
        s_owner = _contract;
    }

    function _update(
        address _from,
        address _to,
        uint256 _amount
    ) internal override(ERC20, ERC20Votes) {
        super._update(_from, _to, _amount);
    }

    function nonces(
        address _owner
    ) public view override(ERC20Permit, Nonces) returns (uint256) {
        return super.nonces(_owner);
    }
}
