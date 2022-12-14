// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "../interfaces/IFoxMarket.sol";
import "./FoxMarketCore.sol";
import "./OfferEscrow.sol";

contract FoxMarket is Initializable, IFoxMarket, FoxMarketCore, ReentrancyGuardUpgradeable, UUPSUpgradeable {

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize() public initializer {
        __FoxMarketCore_init(100);
        __ReentrancyGuard_init();
        __UUPSUpgradeable_init();
    }

    function createERC20LockedOffer(
        address offerToken,
        address saleToken,
        uint256 saleAmount
    ) external whenNotPaused nonReentrant {
        require(isSupportedOfferToken(offerToken), "FoxMarket::Offer token not supported");
        require(isSupportedSaleToken(saleToken), "FoxMarket::Sale token not supported");
        require(_lockedOf(offerToken, msg.sender) > 0, "OfferEscrow::Seller has no locked tokens");
        require(_isOffCooldown(offerToken, msg.sender), "FoxMarket::Seller is on locked token transfer cooldown");

        Offer memory offer = Offer({
            offerTokenType: TokenType.ERC20Locked,
            market: address(this),
            seller: msg.sender,
            offerToken: offerToken,
            saleToken: saleToken,
            saleAmount: saleAmount,
            fee: fee,
            offerAmount: 0,
            cooldown: 0,
            offerTokenId: 0,
            escrow: address(0)
        });
        OfferEscrow offerEscrow = new OfferEscrow(offer);

        addOfferEscrow(address(offerEscrow), msg.sender);

        emit OfferCreated(address(offerEscrow), msg.sender, offerToken, 0, saleToken, saleAmount, TokenType.ERC20Locked);
    }

    function createERC20Offer(
        address offerToken,
        address saleToken,
        uint256 offerAmount,
        uint256 saleAmount
    ) external whenNotPaused nonReentrant {
        require(isSupportedOfferToken(offerToken), "FoxMarket::Offer token not supported");
        require(isSupportedSaleToken(saleToken), "FoxMarket::Sale token not supported");

        IDFKToken token = IDFKToken(offerToken);

        uint256 balance = token.balanceOf(msg.sender);
        require(balance >= offerAmount, "FoxMarket::Insufficient Offer Token funds");

        Offer memory offer = Offer({
            offerTokenType: TokenType.ERC20,
            market: address(this),
            seller: msg.sender,
            offerToken: offerToken,
            offerAmount: offerAmount,
            saleToken: saleToken,
            saleAmount: saleAmount,
            fee: fee,
            cooldown: 0,
            offerTokenId: 0,
            escrow: address(0)
        });
        OfferEscrow offerEscrow = new OfferEscrow(offer);

        token.transferFrom(msg.sender, address(offerEscrow), offerAmount);

        addOfferEscrow(address(offerEscrow), msg.sender);
        emit OfferCreated(address(offerEscrow), msg.sender, offerToken, 0, saleToken, saleAmount, TokenType.ERC20Locked);
    }

    function createERC1155Offer(
        address offerToken,
        uint256 offerTokenId,
        address saleToken,
        uint256 offerAmount,
        uint256 saleAmount
    ) external whenNotPaused nonReentrant {
        require(isSupportedOfferToken(offerToken), "FoxMarket::Offer token not supported");
        require(isSupportedSaleToken(saleToken), "FoxMarket::Sale token not supported");

        IERC1155Upgradeable token = IERC1155Upgradeable(offerToken);

        uint256 balance = token.balanceOf(msg.sender, offerTokenId);

        require(balance >= offerAmount, "FoxMarket::Insufficient Offer Token funds");

        Offer memory offer = Offer({
            offerTokenType: TokenType.ERC1155,
            market: address(this),
            seller: msg.sender,
            offerToken: offerToken,
            offerTokenId: offerTokenId,
            offerAmount: offerAmount,
            saleToken: saleToken,
            saleAmount: saleAmount,
            fee: fee,
            escrow: address(0),
            cooldown: 0
        });

        OfferEscrow offerEscrow = new OfferEscrow(offer);

        token.safeTransferFrom(msg.sender, address(offerEscrow), offerTokenId, offerAmount, "");

        addOfferEscrow(address(offerEscrow), msg.sender);

        emit OfferCreated(address(offerEscrow), msg.sender, offerToken, offerTokenId, saleToken, saleAmount, TokenType.ERC20Locked);
    }

    function fillOffer(address _offerEscrow) external whenNotPaused nonReentrant {
        require(offerEscrowExists(_offerEscrow), "FoxMarket::Invalid Token Offer");
        OfferEscrow offerEscrow = OfferEscrow(_offerEscrow);

        Offer memory offer = offerEscrow.getOfferDetails();
        if (offer.offerTokenType == TokenType.ERC20Locked) {
            require(offer.offerAmount > 0, "FoxMarket::Seller has not hydrated the Token Offer");
            require(_isOffCooldown(offer.offerToken, msg.sender), "OfferEscrow::Buyer is on locked token transfer cooldown");
            require(_isOffCooldown(offer.offerToken, _offerEscrow), "OfferEscrow::Offer is still pending locked token transfer cooldown");
        }

        FeeDistribution memory feeDistribution = getFeeShares();
        uint256 marketFee = _getMarketFee(offer.saleAmount);

        offerEscrow.fill(msg.sender, marketFee, feeDistribution);
        removeOfferEscrow(_offerEscrow, offer.seller);

        emit OfferFilled(
            address(offerEscrow),
            offer.seller,
            msg.sender,
            offer.offerToken,
            offer.offerTokenId,
            offer.saleToken,
            offer.offerAmount,
            offer.saleAmount,
            offer.offerTokenType
        );
    }

    function cancelOffer(address offerEscrow) external nonReentrant {
        require(offerEscrowExists(offerEscrow), "FoxMarket::Invalid Token Offer");
        OfferEscrow _offerEscrow = OfferEscrow(offerEscrow);
        Offer memory offer = _offerEscrow.getOfferDetails();
        require(offer.seller == msg.sender, "OfferEscrow::Not seller");
        if (offer.offerTokenType == TokenType.ERC20Locked) {
            require(_isOffCooldown(offer.offerToken, offer.seller), "OfferEscrow::Seller is on locked token transfer cooldown");
            require(_isOffCooldown(offer.offerToken, offerEscrow), "OfferEscrow::Offer is still pending locked token transfer cooldown");
        }

        _cancel(_offerEscrow, offer);
    }

    function getOffers() external view returns (Offer[] memory offers) {
        address[] memory _offerEscrows = offerEscrows();
        offers = new Offer[](_offerEscrows.length);

        for (uint256 i; i < _offerEscrows.length; i++) {
            offers[i] = OfferEscrow(_offerEscrows[i]).getOfferDetails();
            if (offers[i].offerTokenType == TokenType.ERC20Locked) {
                offers[i].cooldown = _cooldown(offers[i].offerToken, _offerEscrows[i]);
            }
        }
        return offers;
    }

    function getActiveOffers() external view returns (Offer[] memory offers) {
        address[] memory _offerEscrows = offerEscrows();
        offers = new Offer[](_offerEscrows.length);

        uint256 count = 0;
        for (uint256 i; i < _offerEscrows.length; i++) {
            Offer memory offer = OfferEscrow(_offerEscrows[i]).getOfferDetails();
            if (offer.offerAmount > 0) {
                offers[count] = offer;
                count++;
            }
        }
        return offers;
    }

    function getOffersOf(address wallet) external view returns (Offer[] memory offers) {
        address[] memory _userOffers = userOffers(wallet);
        offers = new Offer[](_userOffers.length);
        for (uint256 i; i < _userOffers.length; i++) {
            offers[i] = OfferEscrow(_userOffers[i]).getOfferDetails();
        }
    }

    function _authorizeUpgrade(address newImplementation) internal onlyDefaultAdmin override {}
    
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IFoxMarket).interfaceId || super.supportsInterface(interfaceId);
    }
}