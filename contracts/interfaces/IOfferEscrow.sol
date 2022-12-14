// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IFoxMarketCore.sol";

interface IOfferEscrow is IFoxMarketCommon {

    function market() external view returns(address);
    function seller() external view returns(address);
    function offerToken() external view returns(address);
    function saleToken() external view returns(address);
    function saleAmount() external view returns(uint256);
    function fee() external view returns(uint256);
    function lockedUntil() external view returns(uint256);

    function fill(address buyer, uint256 marketFee, FeeDistribution memory feeDistribution) external;
    function cancel() external;

    function offerAmount() external view returns (uint256);
    function getOfferDetails() external view returns (Offer memory);

}