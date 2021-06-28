//SPDX-License-Identifier: Unlicense
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "hardhat/console.sol";
import "./Utils.sol";
import "./OracleInterface.sol";
import "./Ownable.sol";

//TODO: add Admin role so users can create an event and open betting on it

/* 
This class takes bets and handles payouts for sporting events including participants
and a winner or draw outcome
*/

contract VanillaBet is Ownable {

    address internal oracleAddress = 0x38329CA0B835D3c96f7763A807813bDa6BFe2006; // SportsOracle address in Ropsten network
    OracleInterface internal oracle = OracleInterface(oracleAddress);

    // Events
    event NewBet(string message, bytes32 gameId, address player, uint amount, int winner);

    struct Bet {
        address payable user;
        bytes32 gameId; // maybe bytes16?
        uint amount;
        int winner;  // index of the winner in _game.participants[], 0 for draw
    }

    mapping(address => bytes32[]) internal userToBets;
    mapping(bytes32 => Bet[]) internal gameToBets;
    mapping(bytes32 => bool) internal gamePaidOut;

    // sets a new Oracle to be used by contract
    // param _oracleAddress the address of the new oracle
    function setOracleAddress(address _oracleAddress) external onlyOwner returns (bool) {
        oracleAddress = _oracleAddress;
        oracle = OracleInterface(oracleAddress);
        return oracle.testConnection();
    }

    // returns the address of the current Oracle 
    function getOracleAddress() external view returns (address) {
        return oracleAddress;
    }

    // return true if Oracle connection is valid
    function testOracleConnection() public view returns(bool) {
        return oracle.testConnection();
    }

    // param _gameId id of a game
    // returns true if the game is bettable
    function _gameOpenForBetting(bytes32 _gameId) private view returns (bool) {
        OracleInterface.Status status; 
        (,,,, status,) = getGame(_gameId);
        return status == OracleInterface.Status.Pending;
    }

    // returns an array of game ids from games currently open for betting
    function getBettableGames() public view returns (OracleInterface.Game[] memory) {
        return oracle.getPendingGames();
    }

    // returns array of game ids for all Games
    function getGames() public view returns (OracleInterface.Game[] memory) {
        return oracle.getAllGames();
    }

    // param _gameId the id of the desired game
    // returns game data
    function getGame(bytes32 _gameId) public view returns (
        bytes32 id,
        string memory name,
        string[] memory participants,
        uint date,
        OracleInterface.Status status,
        int winner) {

        return oracle.getGame(_gameId);
    }

    // returns array ids for Games on which the user has bet
    function getAllUserBets() public view returns (bytes32[] memory) {
        return userToBets[msg.sender];
    }

    // get array of game bets
    // params _gameId the id of the Game
    function getAllGameBets(bytes32 _gameId) public view returns(Bet[] memory _total) {
        return gameToBets[_gameId];
    }

    // gets a user's bet on a given game
    // param _gameId the id of the desired game
    // returns tuple containing the bet amount, and the index of the chosen winner (or (0,0) if no bet found)
    function getUserBet(bytes32 _gameId) public view returns (uint amount, int winner) {
        Bet[] storage bets = gameToBets[_gameId];
        for (uint n = 0; n < bets.length; n++) {
            if (bets[n].user == msg.sender) {
                return (bets[n].amount, bets[n].winner);
            }
        }
        return (0, 0);
    }

    // places a bet on the given game
    // params _gameId the id of the game on which to bet, _winner the index of the participant chosen as winner
    function placeBet(bytes32 _gameId, int _winner) public payable {

        // make sure that game exists
        require(oracle.gameExists(_gameId), "There is no Game with the given id");

        // game must still be open for betting
        require(_gameOpenForBetting(_gameId), "Game is not open for betting");

        // add the new bet
        Bet[] storage bets = gameToBets[_gameId];
        bets.push(Bet(msg.sender, _gameId, msg.value, _winner));

        // add the mapping
        bytes32[] storage userBets = userToBets[msg.sender];
        userBets.push(_gameId);

        // broadcast Event
        emit NewBet("Bet added", _gameId, msg.sender, msg.value, _winner);
    }
}
