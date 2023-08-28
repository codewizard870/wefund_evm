// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/draft-ERC721Votes.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./CentaurusBase.sol";

contract CentaurusNftToken is ERC721, Ownable, EIP712, ERC721Votes, ERC721Enumerable, BaseContract {
    using Counters for Counters.Counter;
    mapping(uint256 => OnChainMetadata) public metadatas;

    Counters.Counter private _tokenIdCounter;

    constructor() ERC721("CentaurusNftToken", "MTK") EIP712("CentaurusNftToken", "1") {}

    function safeMint(address to, string memory category, string memory subCategory) public onlyOwner {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);

        OnChainMetadata storage _metadata = metadatas[tokenId];
        _metadata.category = category;
        _metadata.subCategory = subCategory;
    }

    function metadata(uint256 tokenId) public view returns(OnChainMetadata memory){
        return metadatas[tokenId];
    }
    function metadatasOfOwner(address _owner) public view returns(OnChainMetadata[] memory){
        uint256 tokenNum = balanceOf(_owner);
        OnChainMetadata[] memory _metadatas = new OnChainMetadata[](tokenNum);
        for (uint256 i = 0; i < tokenNum; i++) {
            _metadatas[i] = metadata(tokenOfOwnerByIndex(_owner, i));
        }
        return _metadatas;
    }
    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Votes) {
        super._afterTokenTransfer(from, to, tokenId);
    }

    function _getVotingUnits(address account) internal pure override returns (uint256) {
        return 1;
    }
}
