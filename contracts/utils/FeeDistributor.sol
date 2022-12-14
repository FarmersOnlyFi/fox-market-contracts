// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableMapUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "../interfaces/IFoxMarketCore.sol";

abstract contract FeeDistributor is Initializable, IFoxMarketCore {
    using EnumerableMapUpgradeable for EnumerableMapUpgradeable.AddressToUintMap;
    uint256 private constant BASIS_POINTS = 10_000;

    uint256 public constant maxFee = 1000; // 10% in basis points;

    uint256 public fee; // fee in basis points;

    EnumerableMapUpgradeable.AddressToUintMap private _shareDistribution;

    uint256 private _totalShares;

    event FeeDistributed(address indexed from, address indexed to, address indexed token, uint256 amount);

    function __FeeDistributor_init(uint256 _fee) internal onlyInitializing {
        fee = _fee;
    }

    function _distributeFee(address token, uint256 _fee) internal {
        uint256 count = _shareDistribution.length();
        for (uint256 i = 0; i < count; i++) {
            address destination;
            uint256 share;
            (destination, share) = _shareDistribution.at(i);
            uint256 amount = _fee * share / _totalShares;
            IERC20Upgradeable(token).transferFrom(msg.sender, destination, amount);
            emit FeeDistributed(msg.sender, destination, token, amount);
        }
    }

    function _setFeeShare(address destination, uint256 share) internal {
        require(destination != address(0), "FeeDistributor::Destination Address cannot be the zero address");
        require(share > 0, "FeeDistributor::Share must be greater than zero");
        bool exists;
        uint256 _share;
        (exists, _share) = _shareDistribution.tryGet(destination);
        if (exists) {
            if (share >= _share) {
                _totalShares += share - _share;
            } else {
                _totalShares -= _share - share;
            }
        } else {
            _totalShares += share;
        }
        _shareDistribution.set(destination, share);
    }

    function _removeFeeShare(address destination) internal {
        bool exists;
        uint256 share;
        (exists, share) = _shareDistribution.tryGet(destination);
        require(exists, "FeeDistributor::Destination address is not a configured fee share address");
        _totalShares -= share;
        _shareDistribution.remove(destination);
    }

    function _getMarketFee(uint256 saleAmount) internal view returns (uint256) {
        return saleAmount * fee / BASIS_POINTS;
    }
    /**
     * @dev Set the escrow fee in basis points
     */
    function _setFee(uint256 _fee) internal {
        require(_fee <= maxFee, "OfferFactory::Fee higher than maxFee");
        fee = _fee;
    }

    function getFeeShares() public view returns (FeeDistribution memory feeDistribution) {
        uint256 total = _totalShares;
        uint256 count = _shareDistribution.length();
        address[] memory destinations = new address[](count);
        uint256[] memory shares = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            (destinations[i], shares[i]) = _shareDistribution.at(i);
        }
        return FeeDistribution(destinations, shares, total);
    }

    uint256[48] private __gap;
}
