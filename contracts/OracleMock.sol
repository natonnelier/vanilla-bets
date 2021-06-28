//SPDX-License-Identifier: Unlicense
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "hardhat/console.sol";
import { ArrayLib, DateLib } from "./Utils.sol";
import "./OracleInterface.sol";
import "./Ownable.sol";

/*
 This contract's purpose is to mock data to be used in tests. No real life scenario should implement it.
 */

contract OracleMock is OracleInterface, Ownable {

    using ArrayLib for string[];
    using DateLib for DateLib.DateTime;

    bytes32[] gameIds;
    mapping(bytes32 => Game) gameIdToGames;

    function addGame(string memory _name, string[] memory _participants, uint _date) public override onlyOwner returns (bytes32 _id) {

        //hash the crucial info to generate a unique id 
        _id = keccak256(abi.encodePacked(_name, _date));

        //require id to be unique (not already added) 
        require(!gameExists(_id), "Game already exists");
        
        // add draw to participants
        string[] memory participants = _participants.prepend("Draw");

        //add the match 
        gameIdToGames[_id] = Game(_id, _name, participants, _date, Status.Pending, -1); 
        gameIds.push(_id);

        //return the unique id of the new match
        return _id;
    }

    function gameExists(bytes32 _gameId) public view override returns (bool) {
        return gameIdToGames[_gameId].id != "";
    }

    function getGame(bytes32 _gameId) public view override returns (
        bytes32 id,
        string memory name,
        string[] memory participants,
        uint date, 
        Status status, 
        int winner) {

        Game storage _game = gameIdToGames[_gameId];
        return (_game.id, _game.name, _game.participants, _game.date, _game.status, _game.winner);
    }

    // return all Games with Status == Status.Pending
    function getPendingGames() public view override returns (Game[] memory) {
        uint count = 0;

        // get number of pending Games in order to initialize array
        for (uint i = 0; i < gameIds.length; i++) {
            if (gameIdToGames[gameIds[i]].status == Status.Pending) { count++; }
        }

        Game[] memory _pendingGames = new Game[](count);

        if (count > 0) {
            uint index = 0;
            for (uint i = 0; i < gameIds.length; i++) {
                if (gameIdToGames[gameIds[i]].status == Status.Pending) {
                    _pendingGames[index++] = gameIdToGames[gameIds[i]];
                }
            }
        }

        return _pendingGames;
    }

    // return an array including all Games
    function getAllGames() public view override returns (Game[] memory) {
        Game[] memory _games = new Game[](gameIds.length);
        for (uint i = 0; i < gameIds.length; i++) {
            _games[i] = gameIdToGames[gameIds[i]];
        }
        return _games;
    }

    function setGameWinner(bytes32 _gameId, int _winner) external override {
        // check game exists
        require(gameExists(_gameId), "Game does not exists");

        Game storage game = gameIdToGames[_gameId];

        // check participants[_winner] is valid -> _winner not out of bounds
        require(game.participants.length > uint(_winner), "Winner is not among Game's participants");

        game.winner = _winner;
        game.status = Status.Completed;
    }

    function setGameInProgress(bytes32 _gameId) external override {
        // check game exists
        require(gameExists(_gameId), "Game does not exists");
        Game storage game = gameIdToGames[_gameId];
        game.status = Status.InProgress;
    }

    function setGameCompleted(bytes32 _gameId) external override {
        // check game exists
        require(gameExists(_gameId), "Game does not exists");
        Game storage game = gameIdToGames[_gameId];
        game.status = Status.Completed;
    }

    function setGamePending(bytes32 _gameId) external override {
        // check game exists
        require(gameExists(_gameId), "Game does not exists");
        Game storage game = gameIdToGames[_gameId];
        game.status = Status.Pending;
    }

    function testConnection() public pure override returns (bool) {
        return true;
    }
}
