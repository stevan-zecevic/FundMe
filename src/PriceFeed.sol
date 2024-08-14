// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import {AggregatorV3Interface} from "chainlink-toolkit/src/interfaces/feeds/AggregatorV3Interface.sol";

contract PriceFeed {
    AggregatorV3Interface internal dataFeed;

    constructor(address _priceFeedAddress) {
        dataFeed = AggregatorV3Interface(_priceFeedAddress);
    }

    function getLatestAnswer() internal view returns (uint256) {
        (, int answer, , , ) = dataFeed.latestRoundData();
        return uint256(answer);
    }

    // CHECK: Maybe this can remain uint8 instead of uint256
    function getDecimals() internal view returns (uint8) {
        uint8 decimals = dataFeed.decimals();

        return decimals;
    }

    function convertToUSD(uint256 _value) internal view returns (uint256) {
        uint8 decimals = getDecimals();
        uint256 answer = getLatestAnswer();

        uint256 scaledAnswer = answer * 10 ** (18 - decimals); // Scaled to wei format

        return (scaledAnswer * _value) / 10 ** 18;
    }
}
