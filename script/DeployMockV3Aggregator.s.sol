// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import {Script} from "forge-std/Script.sol";
import {MockV3Aggregator} from "test/mock/MockV3Aggregator.t.sol";
import {Constants} from "script/NetworkConfig.s.sol";

contract DeployMockV3Aggregator is Script, Constants {
    function run() external returns (MockV3Aggregator) {
        vm.startBroadcast();
        MockV3Aggregator aggregator = new MockV3Aggregator(PRICEFEED_DECIMALS, PRICEFEED_INITIAL_ANSWER);
        vm.stopBroadcast();

        return aggregator;
    }
}
