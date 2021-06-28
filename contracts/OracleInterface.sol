//SPDX-License-Identifier: Unlicense
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "hardhat/console.sol";

/*
 This contract holds the basic methods structure for Oracles
 */

interface OracleInterface {

    enum Status {
        Pending,    // game hasn't started
        InProgress, // game is underway
        Completed   // game completed and there is an outcome
    }

    struct Game {
        bytes32 id;
        string name;
        string[] participants;
        uint date; 
        Status status;
        int winner; // index in participants (-1 if no winner has been declated)
    }

    function getGame(bytes32 _gameId) external view returns (
        bytes32 id,
        string memory name, 
        string[] memory participants,
        uint date, 
        Status status, 
        int winner);

    function gameExists(bytes32 _gameId) external view returns (bool);

    function addGame(string memory _name, string[] memory _participants, uint _date) external returns (bytes32);

    function getPendingGames() external view returns (Game[] memory);

    function getAllGames() external view returns (Game[] memory);

    function setGameWinner(bytes32 _gameId, int _winner) external;

    function testConnection() external pure returns (bool);

    function setGameInProgress(bytes32 _gameId) external;
    function setGameCompleted(bytes32 _gameId) external;
    function setGamePending(bytes32 _gameId) external;
}
