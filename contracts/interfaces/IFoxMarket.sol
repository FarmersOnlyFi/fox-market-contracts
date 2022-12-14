// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IFoxMarketCore.sol";

interface IFoxMarket is IFoxMarketCore {

    function createERC20LockedOffer(address offerToken, address saleToken, uint256 saleAmount) external;
    function createERC20Offer(address offerToken, address saleToken, uint256 offerAmount, uint256 saleAmount) external;
    function createERC1155Offer(
        address offerToken,
        uint256 offerTokenId,
        address saleToken,
        uint256 offerAmount,
        uint256 saleAmount
    ) external;

    function fillOffer(address offerEscrow) external;
    function cancelOffer(address offerEscrow) external;

    function getOffers() external view returns (Offer[] memory offers);
    function getActiveOffers() external view returns (Offer[] memory offers);
    function getOffersOf(address wallet) external view returns (Offer[] memory offers);
}