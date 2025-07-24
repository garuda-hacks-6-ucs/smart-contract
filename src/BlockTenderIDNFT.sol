// SPDX-License-Identifier: MIT

pragma solidity ^0.8.28;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {ERC721URIStorage} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";

contract BlockTenderIDNFT is ERC721URIStorage {
    constructor() ERC721("ProjectRakyat", "PRT") {}

    function mint(
        uint256 _tokenId,
        address _recipient,
        string memory _uri
    ) external {
        _safeMint(_recipient, _tokenId);
        _setTokenURI(_tokenId, _uri);
    }
}
