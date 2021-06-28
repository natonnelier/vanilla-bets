# vanilla-bets

Vanilla Bets is a decentralized betting app that handles the creation of Bets and winners payout, including a small fee that is assigned to the contract's owner (or deployer).

It works with information it retrieves from an Oracle. You can check OracleInterface for required structure or use [the following project](https://github.com/natonnelier/sports-oracle).

## Requirements

It was developed using:
- solidity 0.7.3
- hardhat 2.3.3
- ethers 5.4.0

Tests use:
- chai 4.3.4

## Proyect Structure
`VanillaBet` contract handles the following tasks:
- connection with Oracle and update of it's current address.
- retrieving of Games information (from Oracle).
- creation of Bets and retrieving of Bets data.

`Payout` is in charge of the checkout and pay handed to the winners and also the house take.

Look at the comments in the contract's functions for more details.

## Install

Just git clone this repo and make sure you have all the required dependencies.

To compile: 
```
npx hardhat compile
```

To run tests:
```
npx hardhat test
```

To run node and deploy locally:
```
npx hardhat node
npx hardhat run scripts/deploy.js --network localhost
```

You should edit `scripts/deploy.js` if you want to deploy on any network.

## Usage

Bets are created by calling the public function `placeBet(bytes32 _gameId, int _winner)` on `VanillaBet.sol`. This takes the value of the transaction and stores it in a `Bet` struct mapped to the given `Game` together with the sender address.

After the `Game` is completed and a winner has been declared, the function `checkStatusAndPay(bytes32 _gameId)` in `Payout.sol` takes care of calculating prizes, pay the winners and take a share for the house.


## Contribute

If you want to contribute, don't hesitate to [create a new issue](https://github.com/natonnelier/vanilla-bets/issues/new).

## License

This is an open source software [licensed as MIT](https://github.com/natonnelier/vanilla-bets/blob/master/LICENSE).