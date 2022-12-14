// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IDFKToken {
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function canUnlockAmount(address _holder) external view returns (uint256);
    function cap() external view returns (uint256);
    function circulatingSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool);
    function increaseAllowance(address spender, uint256 addedValue) external returns (bool);
    function lastUnlockTime(address) external view returns (uint256);
    function lock(address _holder, uint256 _amount) external;
    function lockFromTime() external view returns (uint256);
    function lockOf(address _holder) external view returns (uint256);
    function lockToTime() external view returns (uint256);
    function name() external view returns (string memory);
    function owner() external view returns (address);
    function symbol() external view returns (string memory);
    function totalBalanceOf(address _holder) external view returns (uint256);
    function totalLock() external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function transferAll(address _to) external;
    function transferAllInterval() external view returns (uint256);
    function transferAllTracker(address) external view returns (uint256);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function unlock() external;
    function unlockedSupply() external view returns (uint256);
    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata data) external;
}