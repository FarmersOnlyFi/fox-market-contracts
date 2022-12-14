// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IFoxMarketCommon.sol";

interface IFoxMarketCore is IFoxMarketCommon {
    event OfferCreated(
        address tokenOffer,
        address indexed seller,
        address indexed offerToken,
        uint256 offerTokenId,
        address saleToken,
        uint256 saleAmount,
        TokenType offerTokenType
    );
    event OfferFilled(
        address tokenOffer,
        address indexed seller,
        address indexed buyer,
        address indexed offerToken,
        uint256 offerTokenId,
        address saleToken,
        uint256 offerAmount,
        uint256 saleAmount,
        TokenType offerTokenType
    );
    event OfferCancelled(
        address tokenOffer,
        address indexed seller,
        address indexed offerToken,
        uint256 offerTokenId,
        address saleToken,
        uint256 offerAmount,
        uint256 saleAmount,
        TokenType offerTokenType
    );

    event SaleTokenSupportAdded(address indexed by, address indexed token);
    event SaleTokenSupportRemoved(address indexed by, address indexed token);
    event OfferTokenSupportAdded(address indexed by, address indexed token);
    event OfferTokenSupportRemoved(address indexed by, address indexed token);

    event EscrowFeeAddressUpdate(address newAddress, address caller);
    event DevAddressUpdate(address newAddress, address caller);

    function maxFee() external view returns(uint256);
    function fee() external view returns(uint256);


    function addSupportedSaleToken(address token) external;
    function removeSupportedSaleToken(address token) external;
    function addSupportedOfferToken(address token) external;
    function removeSupportedOfferToken(address token) external;

    function setFee(uint256 _fee) external;
    function setFeeShare(address destination, uint256 share) external;
    function removeFeeShare(address destination) external;
    function getFeeShares() external view returns (FeeDistribution memory feeDistribution);

    function pause() external;
    function unpause() external;
}