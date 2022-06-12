// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IERC2981.sol";
import "./RoyaltzNFT.sol";

contract Marketplace {
    struct SellOffer {
        address seller;
        uint256 minPrice;
    }

    struct BuyOffer {
        address buyer;
        uint256 price;
        uint256 createTime;
    }

    bytes4 private constant INTERFACE_ID_ERC2981 = 0x2a55205a;

    /* 
    Store the address of the contract of the NFT to trade. 
    Can be changed in constructor or with a call to setTokenContractAddress.
    */
    address public tokenContractAddress = address(0);

    // Store all active sell offers  and maps them to their respective token ids
    mapping(uint256 => SellOffer) public activeSellOffers;

    // Store all active buy offers and maps them to their respective token ids
    mapping(uint256 => BuyOffer) public activeBuyOffers;

    // Token contract
    RoyaltzNFT token;

    // Escrow for buy offers
    mapping(address => mapping(uint256 => uint256)) public buyOffersEscrow;

    // Events
    event NewSellOffer(uint256 tokenId, address seller, uint256 value);
    event NewBuyOffer(uint256 tokenId, address buyer, uint256 value);
    event SellOfferWithdrawn(uint256 tokenId, address seller);
    event BuyOfferWithdrawn(uint256 tokenId, address buyer);
    event RoyaltiesPaid(uint256 tokenId, uint256 value);
    event Sale(uint256 tokenId, address seller, address buyer, uint256 value);

    modifier isMarketable(uint256 _tokenId) {
        require(token.getApproved(_tokenId) == address(this), "Not approved");
        _;
    }

    modifier tokenOwnerOnly(uint256 _tokenId) {
        require(token.ownerOf(_tokenId) == msg.sender, "Not token owner");
        _;
    }

    modifier tokenOwnerForbidden(uint256 _tokenId) {
        require(
            token.ownerOf(_tokenId) != msg.sender,
            "Token owner not allowed"
        );
        _;
    }

    modifier lastBuyOfferExpired(uint256 _tokenId) {
        require(
            activeBuyOffers[_tokenId].createTime < (block.timestamp - 1 days),
            "Buy offer not expired"
        );
        _;
    }

    constructor(address _tokenContractAddress) {
        tokenContractAddress = _tokenContractAddress;
        token = RoyaltzNFT(tokenContractAddress);
    }

    /// @notice Checks if NFT contract implements the ERC-2981 interface
    /// @param _contract - the address of the NFT contract to query
    /// @return true if ERC-2981 interface is supported, false otherwise
    function _checkRoyalties(address _contract) internal view returns (bool) {
        bool success = IERC2981(_contract).supportsInterface(
            INTERFACE_ID_ERC2981
        );
        return success;
    }

    function makeSellOffer(uint256 _tokenId, uint256 _minPrice)
        external
        isMarketable(_tokenId)
        tokenOwnerOnly(_tokenId)
    {
        // Create sell offer
        activeSellOffers[_tokenId] = SellOffer({
            seller: msg.sender,
            minPrice: _minPrice
        });

        emit NewSellOffer(_tokenId, msg.sender, _minPrice);
    }

    /// @notice Withdraw a sell offer
    /// @param _tokenId - id of the token whose sell order needs to be cancelled
    function withdrawSellOffer(uint256 _tokenId)
        external
        isMarketable(_tokenId)
    {
        require(
            activeSellOffers[_tokenId].seller != address(0),
            "No sale offer"
        );
        require(activeSellOffers[_tokenId].seller == msg.sender, "Not Seller");

        delete (activeSellOffers[_tokenId]);

        emit SellOfferWithdrawn(_tokenId, msg.sender);
    }

    /// @notice Transfers royalties to the rightsowner if applicable
    /// @param _tokenId - the NFT assed queried for royalties
    /// @param _grossSaleValue - the price at which the asset will be sold
    /// @return netSaleAmount - the value that will go to the seller after
    ///         deducting royalties
    function _deduceRoyalties(uint256 _tokenId, uint256 _grossSaleValue)
        internal
        returns (uint256 netSaleAmount)
    {
        (address royaltiesReceiver, uint256 royaltiesAmount) = token
            .royaltyInfo(_tokenId, _grossSaleValue);

        uint256 netSaleValue = _grossSaleValue - royaltiesAmount;

        if (royaltiesAmount > 0) {
            royaltiesReceiver.call{value: royaltiesAmount}("");
        }

        emit RoyaltiesPaid(_tokenId, royaltiesAmount);
        return netSaleValue;
    }

    /// @notice Purchases a token and transfers royalties if applicable
    /// @param _tokenId - id of the token to sell
    function purchase(uint256 _tokenId)
        external
        payable
        tokenOwnerForbidden(_tokenId)
    {
        address seller = activeSellOffers[_tokenId].seller;

        require(seller != address(0), "No active sell offer");

        // If, for some reason, the token is not approved anymore (transfer or
        // sale on another market place for instance), we remove the sell order
        // and throw
        if (token.getApproved(_tokenId) != address(this)) {
            delete (activeSellOffers[_tokenId]);
            // Broadcast offer withdrawal
            emit SellOfferWithdrawn(_tokenId, seller);
            // Revert
            revert("Invalid sell offer");
        }

        require(
            msg.value >= activeSellOffers[_tokenId].minPrice,
            "Amount sent too low"
        );
        uint256 saleValue = msg.value;
        // Pay royalties if applicable
        if (_checkRoyalties(tokenContractAddress)) {
            saleValue = _deduceRoyalties(_tokenId, saleValue);
        }
        // Transfer funds to the seller
        activeSellOffers[_tokenId].seller.call{value: saleValue}("");
        // And token to the buyer
        token.safeTransferFrom(seller, msg.sender, _tokenId);
        // Remove all sell and buy offers
        delete (activeSellOffers[_tokenId]);
        delete (activeBuyOffers[_tokenId]);
        // Broadcast the sale
        emit Sale(_tokenId, seller, msg.sender, msg.value);
    }

    /// @notice Makes a buy offer for a token. The token does not need to have
    ///         been put up for sale. A buy offer can not be withdrawn or
    ///         replaced for 24 hours. Amount of the offer is put in escrow
    ///         until the offer is withdrawn or superceded
    /// @param _tokenId - id of the token to buy
    function makeBuyOffer(uint256 _tokenId)
        external
        payable
        tokenOwnerForbidden(_tokenId)
    {
        // Reject the offer if item is already available for purchase at a
        // lower or identical price
        if (activeSellOffers[_tokenId].minPrice != 0) {
            require(
                (msg.value > activeSellOffers[_tokenId].minPrice),
                "Sell order at this price or lower exists"
            );
        }
        // Only process the offer if it is higher than the previous one or the
        // previous one has expired
        require(
            activeBuyOffers[_tokenId].createTime < (block.timestamp - 1 days) ||
                msg.value > activeBuyOffers[_tokenId].price,
            "Previous buy offer higher or not expired"
        );
        address previousBuyOfferOwner = activeBuyOffers[_tokenId].buyer;
        uint256 refundBuyOfferAmount = buyOffersEscrow[previousBuyOfferOwner][
            _tokenId
        ];
        // Refund the owner of the previous buy offer
        buyOffersEscrow[previousBuyOfferOwner][_tokenId] = 0;
        if (refundBuyOfferAmount > 0) {
            payable(previousBuyOfferOwner).call{value: refundBuyOfferAmount}(
                ""
            );
        }
        // Create a new buy offer
        activeBuyOffers[_tokenId] = BuyOffer({
            buyer: msg.sender,
            price: msg.value,
            createTime: block.timestamp
        });
        // Create record of funds deposited for this offer
        buyOffersEscrow[msg.sender][_tokenId] = msg.value;
        // Broadcast the buy offer
        emit NewBuyOffer(_tokenId, msg.sender, msg.value);
    }

    /// @notice Withdraws a buy offer. Can only be withdrawn a day after being
    ///         posted
    /// @param _tokenId - id of the token whose buy order to remove
    function withdrawBuyOffer(uint256 _tokenId)
        external
        lastBuyOfferExpired(_tokenId)
    {
        require(activeBuyOffers[_tokenId].buyer == msg.sender, "Not buyer");
        uint256 refundBuyOfferAmount = buyOffersEscrow[msg.sender][_tokenId];

        // Set the buyer balance to 0 before refund
        buyOffersEscrow[msg.sender][_tokenId] = 0;

        // Remove the current buy offer
        delete (activeBuyOffers[_tokenId]);

        // Refund the current buy offer if it is non-zero
        if (refundBuyOfferAmount > 0) {
            msg.sender.call{value: refundBuyOfferAmount}("");
        }

        emit BuyOfferWithdrawn(_tokenId, msg.sender);
    }

    /// @notice Lets a token owner accept the current buy offer
    ///         (even without a sell offer)
    /// @param _tokenId - id of the token whose buy order to accept
    function acceptBuyOffer(uint256 _tokenId)
        external
        isMarketable(_tokenId)
        tokenOwnerOnly(_tokenId)
    {
        address currentBuyer = activeBuyOffers[_tokenId].buyer;
        require(currentBuyer != address(0), "No buy offer");
        uint256 saleValue = activeBuyOffers[_tokenId].price;
        uint256 netSaleValue = saleValue;
        // Pay royalties if applicable
        if (_checkRoyalties(tokenContractAddress)) {
            netSaleValue = _deduceRoyalties(_tokenId, saleValue);
        }

        // Delete the current sell offer whether it exists or not
        delete (activeSellOffers[_tokenId]);
        // Delete the buy offer that was accepted
        delete (activeBuyOffers[_tokenId]);
        
        // Withdraw buyer's balance
        buyOffersEscrow[currentBuyer][_tokenId] = 0;
        
        // Transfer funds to the seller
        msg.sender.call{value: netSaleValue}("");
        
        // And token to the buyer
        token.safeTransferFrom(msg.sender, currentBuyer, _tokenId);
        
        emit Sale(_tokenId, msg.sender, currentBuyer, saleValue);
    }
}
