//SPDX-License-Identifier: Unlicense
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "hardhat/console.sol";

import { SafeMath } from "./Utils.sol";

import "./VanillaBet.sol";
import "./Ownable.sol";
import "./Disableable.sol";
import "./OracleInterface.sol";

//TODO: what if bets have no winner?

/*
This class is in charge of calculating and paying bet's prizes among winners
including house share
*/

contract Payout is VanillaBet, Disableable {

    using SafeMath for uint;

    //constants
    uint HOUSE_SHARE = 1;

    // Events
    event PrizePaid(string message, bytes32 gameId, address user, uint amount, uint date);

    // transfers house share to the owner
    // params amount the house share on current game bets
    function _transferToOwner(uint _amount) private {
        owner.transfer(_amount);
    }

    function _calculateBetTotals(bytes32 _gameId, int _winner) private view returns (uint _losingTotal, uint _winningTotal) {
        Bet[] storage bets = gameToBets[_gameId];

        // count winning bets & get total 
        for (uint i = 0; i < bets.length; i++) {
            if (bets[i].winner == _winner) {
                _winningTotal = _winningTotal.add(bets[i].amount);
            } else {
                _losingTotal = _losingTotal.add(bets[i].amount);
            }
        }

        return (_losingTotal, _winningTotal);
    }

    // calculates the amount to be paid out for a bet of the given amount, under the given circumstances
    // param _winningTotal the total amount of winning bets
    // param _losingTotal the total amount in losing bets or amount to be distributed among winners
    // param _betAmount the amount of this particular bet
    // returns prize to be paid to user and hause share, in wei
    function _calculateWinnerPrize(uint _losingTotal, uint _winningTotal, uint _betAmount) private view returns (uint _prize, uint _housePrize) {

        //calculate raw share
        uint subtotal = _betAmount + _losingTotal.mul(_betAmount) / _winningTotal;

        //calculate house share
        _housePrize = subtotal / (100 * HOUSE_SHARE);

        //calculate final prize for user
        _prize = subtotal.sub(_housePrize);

        return (_prize, _housePrize);
    }

    // calculates prizes to pay to each winner and house share
    // param _gameId the unique id of the game
    // param _winner the index of the winner of the game (0 for draw)
    // TODO: what if bets have no winner?
    function _payPrizes(bytes32 _gameId, int _winner) private returns (bool _paid) {

        Bet[] storage bets = gameToBets[_gameId];

        //get totals needed to calculate payment
        (uint _losingTotal, uint _winningTotal) = _calculateBetTotals(_gameId, _winner);

        //throw error if there are no winners
        require(_winningTotal > 0, "No winning bets");

        uint housePrizeTotal = 0;

        //pay each winner and sum house share 
        for (uint i = 0; i < bets.length; i++) {
            if (bets[i].winner == _winner) {
                (uint _prize, uint _housePrize) = _calculateWinnerPrize(_losingTotal, _winningTotal, bets[i].amount);
                housePrizeTotal = housePrizeTotal.add(_housePrize);
                bets[i].user.transfer(_prize);

                emit PrizePaid("Prize sent to user address", _gameId, bets[i].user, _prize, block.timestamp);
            }
        }

        //transfer the house share to the owner
        _transferToOwner(housePrizeTotal);

        //set gamePaidOut
        _paid = true;
        gamePaidOut[_gameId] = _paid;

        return _paid;
    }

    // check outcome and status for a given Game and triggers payout to winners
    // param _gameId the id of the game to check
    // returns boolean indicating if prices where paid or not
    function checkStatusAndPay(bytes32 _gameId) public notDisabled onlyOwner returns (bool _paid)  {
        int _winner = -1;
        OracleInterface.Status _status;

        (,,,, _status, _winner) = oracle.getGame(_gameId);

        require(OracleInterface.Status.Completed == _status, "Game has not been completed yet");
        require(_winner > -1, "A winner hasn't been declared for this Game");
        require(!gamePaidOut[_gameId], "Prizes have already been paid for this Game");

        _paid = _payPrizes(_gameId, _winner);

        return _paid;
    }
}
