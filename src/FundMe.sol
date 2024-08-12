// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

/*
  1. Users can donate specific amount to their desired fund raiser
  2. Add option to add fund minimum
  3. Owner of contract can set goal to be time based or amount based
  4. Every fund contract stores donors
  5. Every fund has a status, is it in progress or completed 
  6. After time limit or goal amount has been met owner can claim their funds
 */

import {PriceFeed} from "contracts/PriceFeed.sol";
import {Ownable} from "contracts/Ownable.sol";

error FundMe__FundRequirementNotMet(address, uint256, uint256, uint256);
error FundMe__RetreiveError(uint256);
error FundMe__GoalAmountNotMet(uint256, uint256);

abstract contract FundMe is PriceFeed {
    event FundMe__Funded(
        address indexed funderAddress,
        uint256 indexed fundedAmount
    );
    event FundMe__DonationsCollected(uint256 indexed amount);

    enum Status {
        Open,
        Closed,
        Finished
    }

    address[] private s_funders;
    mapping(address => uint256) private s_fundersMapping;
    Status private s_status = Status.Open;

    uint256 immutable i_minimumFund;

    constructor(
        uint256 _minimumFund,
        address _priceFeedAddress
    ) PriceFeed(_priceFeedAddress) {
        i_minimumFund = _minimumFund;
    }

    receive() external payable virtual {}

    fallback() external payable {}

    function performUpkeep(
        bytes calldata /* performData */
    ) public payable virtual;

    function fund() public payable {
        uint256 fundedValueInUSD = convertToUSD(msg.value);
        bool isMinimumFundNotMet = i_minimumFund != 0 &&
            fundedValueInUSD < i_minimumFund * 10 ** 18;

        if (msg.value == 0 || isMinimumFundNotMet || s_status != Status.Open) {
            revert FundMe__FundRequirementNotMet(
                msg.sender,
                uint256(s_status),
                fundedValueInUSD,
                msg.value
            );
        }

        emit FundMe__Funded(msg.sender, msg.value);

        if (s_fundersMapping[msg.sender] == 0) {
            s_funders.push(msg.sender);
        }

        s_fundersMapping[msg.sender] += msg.value;
    }

    function getStatus() public view returns (Status) {
        return s_status;
    }

    function setStatus(Status _status) public {
        s_status = _status;
    }
}
