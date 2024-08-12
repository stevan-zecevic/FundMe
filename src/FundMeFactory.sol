// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

import {FundMe_AmountBased} from "contracts/FundMe_AmountBased.sol";
import {FundMe_TimeBased} from "contracts/FundMe_TimeBased.sol";

contract FundMeFactory {
    address[] private s_fundations;

    // @dev: Time limited contracts has a priority over the amount based one
    function createFundation(
        uint256 _timeLimit,
        uint256 _goalAmount,
        uint256 _minimumFund,
        address _priceFeedAddress
    ) public {
        if (_timeLimit != 0) {
            FundMe_TimeBased newFundation = new FundMe_TimeBased(
                _timeLimit,
                _minimumFund,
                _priceFeedAddress
            );

            s_fundations.push(address(newFundation));
        }

        if (_goalAmount != 0) {
            FundMe_AmountBased newFundation = new FundMe_AmountBased(
                _goalAmount,
                _minimumFund,
                _priceFeedAddress
            );

            s_fundations.push(address(newFundation));
        }
    }

    function getFundation(uint256 _index) public view returns (address) {
        return s_fundations[_index];
    }
}
