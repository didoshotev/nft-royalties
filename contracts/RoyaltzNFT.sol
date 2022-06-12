// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract RoyaltzNFT is ERC721, ERC721Enumerable, ERC721URIStorage, Ownable {
    // Keep a mapping of token ids and corresponding IPFS hashes
    mapping(string => uint8) hashes;
    // Maximum amounts of mintable tokens
    uint256 public constant MAX_SUPPLY = 9999;
    // Address of the royalties recipient
    address private royaltyReceiver;
    // Percentage of each sale to pay as royalties
    uint8 public royaltiesPercentage = 5;

    // Events
    event Mint(uint256 tokenId, address recipient);

    constructor(address _initialRoyaltiesReceiver)
        ERC721("RoyaltzNFT", "RNFT")
    {
        royaltyReceiver = _initialRoyaltiesReceiver;
    }

    function _baseURI() internal pure override returns (string memory) {
        return "ipfs://";
    }

    function safeMint(
        address to,
        uint256 tokenId,
        string memory uri
    ) public onlyOwner {
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);
    }

    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _burn(uint256 tokenId)
        internal
        override(ERC721, ERC721URIStorage)
    {
        super._burn(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    /// @notice Getter function for _royaltiesReceiver
    /// @return the address of the royalties recipient
    function getRoyaltyReceiver() external view returns (address) {
        return royaltyReceiver;
    }

    /// @notice Changes the royalties' recipient address (in case rights are
    ///         transferred for instance)
    /// @param newReceiver - address of the new royalties recipient
    function setRoyaltyReceiver(address newReceiver) external onlyOwner {
        require(royaltyReceiver != newReceiver, "Same receiver");
        royaltyReceiver = newReceiver;
    }

    /// @notice Returns a token's URI
    /// @dev See {IERC721Metadata-tokenURI}.
    /// @param tokenId - the id of the token whose URI to return
    /// @return a string containing an URI pointing to the token's ressource
    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    /// @notice Returns all the tokens owned by an address
    /// @param _owner - the address to query
    /// @return ownerTokens - an array containing the ids of all tokens
    ///         owned by the address
    function tokensOfOwner(address _owner)
        external
        view
        returns (uint256[] memory ownerTokens)
    {
        uint256 tokenCount = balanceOf(_owner);
        uint256[] memory result = new uint256[](tokenCount);

        if (tokenCount == 0) {
            return new uint256[](0);
        }

        for (uint256 i = 0; i < tokenCount; i++) {
            result[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return result;
    }

    /// @notice Called with the sale price to determine how much royalty
    ///         is owed and to whom.
    /// @param _tokenId - the NFT asset queried for royalty information
    /// @param _salePrice - sale price of the NFT asset specified by _tokenId
    /// @return receiver - address of who should be sent the royalty payment
    /// @return royaltyAmount - the royalty payment amount for _value sale price
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount)
    {
        uint256 _royalties = (_salePrice * royaltiesPercentage) / 100;
        return (royaltyReceiver, _royalties);
    }

    /// @notice Mints tokens
    /// @param recipient - the address to which the token will be transfered
    /// @param hash - the IPFS hash of the token's resource
    /// @return tokenId - the id of the token
    function mint(address recipient, string memory hash)
        external
        onlyOwner
        returns (uint256 tokenId)
    {
        require(totalSupply() <= MAX_SUPPLY, "All tokens minted");
        require(bytes(hash).length > 0); // dev: Hash can not be empty!
        require(hashes[hash] != 1); // dev: Can't use the same hash twice
        hashes[hash] = 1;
        uint256 newItemId = totalSupply() + 1;
        _safeMint(recipient, newItemId);
        _setTokenURI(newItemId, hash);
        emit Mint(newItemId, recipient);
        return newItemId;
    }
}
