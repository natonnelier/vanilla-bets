// We import Chai to use its asserting functions here.
const { expect } = require("chai");
const { tomorrowUnix } = require('./helpers.ts');


describe("VanillaBet", function () {

    let VanillaBet;
    let contract;
    let oracle;
    let owner;
    let oracleOwner;
    let addr1;
    let addr2;

    before(async function () {
        VanillaBet = await ethers.getContractFactory("VanillaBet");
        [owner, addr1, addr2] = await ethers.getSigners();

        contract = await VanillaBet.deploy();
    });

    // Test owner and deployment.
    describe("Deployment", function () {

        it("Should set the right owner", async function () {
            expect(await contract.owner()).to.equal(owner.address);
        })
    });

    // Connect to Oracle and get confirmation
    describe("Connecting to Oracle", function() {
        before(async function () {
            ArrayLib = await ethers.getContractFactory("ArrayLib");
            arrayLib = await ArrayLib.deploy();

            OracleMock = await ethers.getContractFactory(
                "OracleMock",
                {
                    libraries: { ArrayLib: arrayLib.address }
                }
            );
            [oracleOwner] = await ethers.getSigners();

            oracle = await OracleMock.deploy();

            await contract.setOracleAddress(oracle.address)
        });

        it("it responds successfully", async function() {
            expect(await contract.testOracleConnection()).to.equal(true);
        })
        
        it("contract should set a new Oracle address successfully", async function() {
            expect(await contract.getOracleAddress()).to.equal(oracle.address);
        })

        // retrieve data from Oracle
        describe("get Games info", function() {
            let games;

            before(async function() {
                await oracle.addGame("Boca vs River", ["Draw", "River", "Boca"], tomorrowUnix());
                await oracle.addGame("Gremio vs Fluminense", ["Draw", "Gremio", "Fluminense"], tomorrowUnix());

                // set second Game inProgress in order to test data retrieving
                games = await oracle.getAllGames();
                await oracle.setGameInProgress(games[0].id);
            })

            it("getGames function retrieves an array with all Games", async function() {
                var _games = await contract.getGames();
                expect(_games.length).to.equal(2);
            })

            it("getBettableGames function retrieves an array with Games in Pending status", async function() {
                var _games = await contract.getBettableGames();
                expect(_games.length).to.equal(1);
            })

            it("getGame function retrieves a single Game data", async function() {
                var game = await contract.getGame(games[0].id);
                expect(game.name).to.equal("Boca vs River");
            })

            // place Bets and get betting data
            describe("including Bets", function() {                
                it("placeBet function creates a Bet for the given Game if it's open for bets", async function() {
                    // create Bet for second Game in games with winner 2 (Fluminense)
                    await contract.placeBet(games[1].id, 2);

                    var bet = await contract.getUserBet(games[1].id);
                    expect(bet[1]).to.equal(2);
                })

                it("placeBet function throws an error if the Game is not open for bets", async function() {
                    // create Bet for first Game which is InProgress state
                    await expect(contract.placeBet(games[0].id, 2))
                        .to.be.revertedWith('Game is not open for betting');
                })

                it("placeBet function throws an error if the Game does not exist", async function() {
                    // create Bet for first Game which is InProgress state
                    var invalidId = "0x341f85f5eca6304166fcfb6f591d49f6019f23fa39be0615e6417da06bf747ce";

                    await expect(contract.placeBet(invalidId, 1)).to.be.revertedWith("There is no Game with the given id");
                })

                it("getAllGameBets function returns all bets for a given game", async function() {
                    var gameBets = await contract.getAllGameBets(games[1].id);
                    expect(gameBets.length).to.equal(1);
                })
            })

        })
    }) 
});
