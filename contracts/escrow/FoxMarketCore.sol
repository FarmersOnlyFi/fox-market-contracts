// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "../utils/access/StandardAccessControl.sol";
import "../interfaces/IFoxMarketCore.sol";
import "../utils/FeeDistributor.sol";
import "../interfaces/IDFKToken.sol";
import "./OfferEscrow.sol";

contract FoxMarketCore is Initializable, IFoxMarketCore, PausableUpgradeable, StandardAccessControl, FeeDistributor {
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;

    EnumerableSetUpgradeable.AddressSet private _supportedOfferTokens;
    EnumerableSetUpgradeable.AddressSet private _supportedSaleTokens;

    mapping(address => EnumerableSetUpgradeable.AddressSet) private _userOffers;

    EnumerableSetUpgradeable.AddressSet private _offerEscrows;

    function __FoxMarketCore_init(uint256 _fee) internal onlyInitializing {
        __Pausable_init();
        __StandardAccessControl_init();
        __FeeDistributor_init(_fee);
    }

    function _cancel(OfferEscrow offerEscrow, Offer memory offer) internal {
        offerEscrow.cancel();
        removeOfferEscrow(address(offerEscrow), offer.seller);
        emit OfferCancelled(
            address(offerEscrow),
            offer.seller,
            offer.offerToken,
            offer.offerTokenId,
            offer.saleToken,
            offer.offerAmount,
            offer.saleAmount,
            offer.offerTokenType
        );
    }

    function _cooldown(address lToken, address wallet) internal view returns (uint256) {
        IDFKToken token = IDFKToken(lToken);
        return token.transferAllTracker(wallet);
    }

    function _isOffCooldown(address lToken, address wallet) internal view returns (bool) {
        IDFKToken token = IDFKToken(lToken);
        uint256 cooldown = token.transferAllTracker(wallet);
        uint256 interval = token.transferAllInterval();
        return cooldown + interval <= block.timestamp;
    }

    function _lockedOf(address lToken, address wallet) internal view returns (uint256) {
        return IDFKToken(lToken).lockOf(wallet);
    }

    /**
 * @dev Add a new token to the set of supported sale tokens
     */
    function addSupportedSaleToken(address token) external onlyAdmin {
        _supportedSaleTokens.add(token);
        emit SaleTokenSupportAdded(msg.sender, token);
    }

    /**
     * @dev Remove a token from the set of supported sale tokens
     */
    function removeSupportedSaleToken(address token) external onlyAdmin {
        _supportedSaleTokens.remove(token);
        emit SaleTokenSupportRemoved(msg.sender, token);
    }

    /**
    * @dev Add a new token to the set of supported offer tokens
     */
    function addSupportedOfferToken(address token) external onlyAdmin {
        _supportedOfferTokens.add(token);
        emit OfferTokenSupportAdded(msg.sender, token);
    }

    /**
     * @dev Remove a token from the set of supported offer tokens
     */
    function removeSupportedOfferToken(address token) external onlyAdmin {
        _supportedOfferTokens.remove(token);
        emit OfferTokenSupportRemoved(msg.sender, token);
    }

    /**
     * @dev Set the escrow fee in basis points
     */
    function setFee(uint256 _fee) public onlyAdmin {
        _setFee(_fee);
    }

    /**
     * @dev Add or update a fee share address and share amount
     */
    function setFeeShare(address destination, uint256 share) external onlyAdmin {
        _setFeeShare(destination, share);
    }

    /**
     * @dev Remove a fee share address from the fee share pool
     */
    function removeFeeShare(address destination) external onlyAdmin {
        _removeFeeShare(destination);
    }

    /**
     * @dev Pause contract write functions
     */
    function pause() public onlyAdmin {
        _pause();
    }

    /**
     * @dev Unpause contract write functions
     */
    function unpause() public onlyAdmin {
        _unpause();
    }

    /**
     * @dev Admin cancel the current offer, sending funds back to their respective owners
     */
    function adminCancel(address offerEscrow) external onlyAdmin {
        require(_offerEscrows.contains(offerEscrow), "FoxMarket::Invalid Token Offer");
        OfferEscrow _offerEscrow =  OfferEscrow(offerEscrow);
        Offer memory offer = _offerEscrow.getOfferDetails();
        require(_isOffCooldown(offer.offerToken, offer.seller), "FoxMarket::Seller is on locked token transfer cooldown");
        require(_isOffCooldown(offer.offerToken, offerEscrow), "FoxMarket::Offer is still pending locked token transfer cooldown");

        _cancel(_offerEscrow, offer);
    }

    function isSupportedOfferToken(address token) public view returns (bool) {
        return _supportedOfferTokens.contains(token);
    }

    function isSupportedSaleToken(address token) public view returns (bool) {
        return _supportedSaleTokens.contains(token);
    }

    function addOfferEscrow(address escrow, address sender) internal {
        _offerEscrows.add(address(escrow));
        _userOffers[sender].add(address(escrow));
    }

    function removeOfferEscrow(address escrow, address sender) internal {
        _offerEscrows.remove(address(escrow));
        _userOffers[sender].remove(address(escrow));
    }

    function offerEscrowExists(address escrow) internal view returns (bool) {
        return _offerEscrows.contains(escrow);
    }

    function offerEscrows() public view returns (address[] memory) {
        return _offerEscrows.values();
    }

    function userOffers(address user) internal view returns (address[] memory) {
        return _userOffers[user].values();
    }

    function supportedTokens() public view returns (address[] memory offer, address[] memory sale) {
        offer = _supportedOfferTokens.values();
        sale = _supportedSaleTokens.values();
    }

    function returnUnlocked(address escrow) external {
        require(_offerEscrows.contains(escrow), "FoxMarket::Invalid Token Offer");
        OfferEscrow _offerEscrow =  OfferEscrow(escrow);
        Offer memory offer = _offerEscrow.getOfferDetails();
        require(offer.seller == msg.sender, "FoxMarket::Not Seller");
        _offerEscrow.returnUnlocked();
    }

    function cleanup(address escrow, address seller) external onlyAdmin {
        removeOfferEscrow(escrow, seller);
    }

    uint256[46] private __gap;
}