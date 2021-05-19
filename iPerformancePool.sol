pragma solidity ^0.8.0;

interface iPerformancePool {
    function restartPerformance() external;

    //
    function getPerformanceWithAddress(address CityAddress)
        external
        returns (uint256);
}
