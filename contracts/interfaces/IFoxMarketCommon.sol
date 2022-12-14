// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IFoxMarketCommon {

    enum TokenType { ERC20Locked, ERC20, ERC1155 }

    struct Offer {
        TokenType offerTokenType;
        address escrow;
        address market;
        address seller;
        address offerToken;
        uint256 offerTokenId;
        address saleToken;
        uint256 offerAmount;
        uint256 saleAmount;
        uint256 fee;
        uint256 cooldown;
    }

    struct FeeDistribution {
        address[] destinations;
        uint256[] shares;
        uint256 total;
    }
}