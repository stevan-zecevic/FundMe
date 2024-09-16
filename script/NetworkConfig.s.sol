// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

import {Script} from "forge-std/Script.sol";
import {MockV3Aggregator} from "test/mock/MockV3Aggregator.t.sol";

contract Constants {
    uint256 public constant LOCAL_CHAINID = 31337;
    uint256 public constant SEPOLIA_CHAINID = 11155111;
    uint256 public constant BASE_SEPOLIA_CHAINID = 84532;
    uint8 public constant PRICEFEED_DECIMALS = 8;
    int256 public constant PRICEFEED_INITIAL_ANSWER = 2000e8;
}

contract NetworkConfig is Script, Constants {
    struct Config {
        address priceFeedAddress;
    }

    constructor() {}

    function getConfig() public returns (Config memory) {
        uint256 chainId = block.chainid;
        Config memory config = Config({priceFeedAddress: address(0)});

        if (chainId == LOCAL_CHAINID) {
            vm.startBroadcast();
            MockV3Aggregator priceFeed = new MockV3Aggregator(
                PRICEFEED_DECIMALS,
                PRICEFEED_INITIAL_ANSWER
            );
            vm.stopBroadcast();

            config = Config({priceFeedAddress: address(priceFeed)});
        } else if (chainId == SEPOLIA_CHAINID) {
            config = Config({
                priceFeedAddress: 0x694AA1769357215DE4FAC081bf1f309aDC325306
            });
        } else if (chainId == BASE_SEPOLIA_CHAINID) {
            config = Config({
                priceFeedAddress: 0x4aDC67696bA383F43DD60A9e78F2C97Fbbfc7cb1
            });
        }

        return config;
    }
}
