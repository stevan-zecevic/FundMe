// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

import {Script} from "forge-std/Script.sol";
import {FundMeFactory} from "contracts/FundMeFactory.sol";

contract DeployFundMeFactory is Script {
    function deploy() public returns (FundMeFactory) {
        vm.startBroadcast();
        FundMeFactory factory = new FundMeFactory();
        vm.stopBroadcast();

        return factory;
    }

    function run() external returns (FundMeFactory) {
        FundMeFactory factory = deploy();

        return factory;
    }
}
