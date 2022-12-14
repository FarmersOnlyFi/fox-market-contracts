// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/access/IAccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "../interfaces/IOfferEscrow.sol";
import "../interfaces/IDFKToken.sol";

contract OfferEscrow is IOfferEscrow, ERC165 {
    TokenType public immutable tokenType; // Type of Offer Escrow
    address public immutable market; // FoxMarket contract address
    address public immutable seller; // Seller Address
    address public immutable offerToken; // Token being sold
    uint256 public immutable offerTokenId; // Token being sold
    address public immutable saleToken; // Token wanted in exchange
    uint256 public immutable saleAmount; // Amount of sale token wanted
    uint256 public immutable fee; // in basis points

    uint256 public lockedUntil;

    IDFKToken private token;

    modifier onlyMarket() {
        require(msg.sender == market, "TokenOffer::Not market");
        _;
    }

    constructor(Offer memory offer) {
        market = offer.market;
        seller = offer.seller;
        offerToken = offer.offerToken;
        offerTokenId = offer.offerTokenId;
        saleToken = offer.saleToken;
        saleAmount = offer.saleAmount;
        tokenType = offer.offerTokenType;
        fee = offer.fee;

        token = IDFKToken(offer.offerToken);
    }

    function fill(address buyer, uint256 marketFee, FeeDistribution memory feeDistribution) external onlyMarket {
        uint256 remaining = saleAmount - marketFee;

        // distribute marketFee to shareholders
        _distributeFee(buyer, marketFee, feeDistribution);

        // send tokens to respective parties
        IERC20(saleToken).transferFrom(buyer, seller, remaining);
        if (tokenType == TokenType.ERC20Locked) {
            uint256 balance = token.balanceOf(address(this));
            if (balance > 0) {
                token.transfer(seller, balance);
            }
            token.transferAll(buyer);
        } else if (tokenType == TokenType.ERC20) {
            token.transfer(buyer, offerAmount());
        } else {
            revert("OfferEscrow::ERC1155 not implemented yet");
        }

        selfdestruct(payable(buyer));
    }

    function cancel() external onlyMarket {
        if (tokenType == TokenType.ERC20Locked) {
            if (offerAmount() > 0) {
                token.transferAll(seller);
            }
        } else if (tokenType == TokenType.ERC20) {
            token.transfer(seller, offerAmount());
        } else {
            revert("OfferEscrow::ERC1155 not implemented yet");
        }

        selfdestruct(payable(seller));
    }

    function offerAmount() public view returns (uint256) {
        if (tokenType == TokenType.ERC20Locked) {
            return token.lockOf(address(this));
        } else if (tokenType == TokenType.ERC20) {
            return token.balanceOf(address(this));
        } else {
            // ERC1155 not implemented yet
            return 0;
        }
    }

    function returnUnlocked() external onlyMarket {
        require(tokenType == TokenType.ERC20Locked, "OfferEscrow::Not a locked offer");
        uint256 balance = token.balanceOf(address(this));
        require(balance > 0, "OfferEscrow::No unlocked token balance");
        token.transfer(seller, balance);
    }

    function getOfferDetails() external view returns (Offer memory) {
        return Offer({
            offerTokenType: tokenType,
            seller: seller,
            offerToken: offerToken,
            offerTokenId: offerTokenId,
            offerAmount: offerAmount(),
            saleToken: saleToken,
            saleAmount: saleAmount,
            fee: fee,
            escrow: address(this),
            market: market,
            cooldown: 0
        });
    }

    function _distributeFee(address buyer, uint256 marketFee, FeeDistribution memory feeDistribution) internal {
        for (uint256 i = 0; i < feeDistribution.destinations.length; i++) {
            uint256 amount = marketFee * feeDistribution.shares[i] / feeDistribution.total;
            IERC20(saleToken).transferFrom(buyer, feeDistribution.destinations[i], amount);
        }
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165) returns (bool) {
        return interfaceId == type(IOfferEscrow).interfaceId || super.supportsInterface(interfaceId);
    }
}