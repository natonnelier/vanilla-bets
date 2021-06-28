// We import Chai to use its asserting functions here.
const { expect } = require("chai");
const { tomorrowUnix } = require('./helpers.ts');


describe("Payout", function () {

    let Payout;
    let contract;
    let oracle;
    let owner;
    let addr1;
    let addr2;


    before(async function () {
        Payout = await ethers.getContractFactory("Payout");
        [owner, addr1, addr2, addr3] = await ethers.getSigners();

        contract = await Payout.deploy();
    });

    // Test owner and deployment.
    describe("Deployment", function () {

        it("Should set the right owner", async function () {
            expect(await contract.owner()).to.equal(owner.address);
        })
    });

    // Test checkout and prize pay
    describe("checkStatusAndPay function", function() {
        before(async function () {
            ArrayLib = await ethers.getContractFactory("ArrayLib");
            arrayLib = await ArrayLib.deploy();

            OracleMock = await ethers.getContractFactory(
                "OracleMock",
                {
                    libraries: { ArrayLib: arrayLib.address }
                }
            );

            oracle = await OracleMock.deploy();
            await contract.setOracleAddress(oracle.address);
            expect(await contract.testOracleConnection()).to.equal(true);
        });

        // check Status validation
        describe("when Game status is not completed", function() {
            let game;

            before(async function() {
                // create Game
                await oracle.addGame("Boca vs River", ["River", "Boca"], tomorrowUnix());                
                game = (await oracle.getAllGames())[0];

                // place Bet on Boca
                await contract.placeBet(game.id, 2);
            })

            it("it throws error and reverts transaction", async function() {
                expect(contract.checkStatusAndPay(game.id))
                       .to.be.revertedWith("Game has not been completed yet");
            })
        });

        // check Status validation
        describe("when Game does not have a winner yet", function() {
            let game;

            before(async function() {
                // create Game
                await oracle.addGame("Inter vs Milan", ["Inter", "Milan"], tomorrowUnix());                
                game = (await oracle.getAllGames())[0];

                // place Bet on Milan
                await contract.placeBet(game.id, 2);

                // set status Completed
                await oracle.setGameCompleted(game.id);
            })

            it("it throws error and reverts transaction", async function() {
                expect(contract.checkStatusAndPay(game.id))
                       .to.be.revertedWith("A winner hasn't been declared for this Game");
            })
        })

        // pay prizes
        describe("when Game has winner set and status is completed", function() {
            let game;
            let winningTotal;
            let losingTotal;
            
            describe("if one winner gets the whole pot", function() {
                let losingBet = 8000;
                let winningBet = 6000;

                before(async function() {
                    // create Game
                    await oracle.addGame("Gremio vs Fluminense", ["Gremio", "Fluminense"], tomorrowUnix());
                    const games = await oracle.getAllGames();
                    game = games[games.length-1];
    
                    // user places Bet on Fluminense
                    await contract.connect(addr1).placeBet(game.id, 2, { from: addr1.address, value: winningBet });
    
                    // admin places Bet on Gremio
                    await contract.connect(addr2).placeBet(game.id, 1, { from: addr2.address, value: losingBet });
    
                    // set status Completed
                    await oracle.setGameCompleted(game.id);
    
                    // set Fluminense as winner
                    await oracle.setGameWinner(game.id, 2);
                })
    
                it("it pays prizes properly to winner", async function() {
                    winningTotal = winningBet;
                    losingTotal = losingBet;

                    const subtotal = winningBet + losingTotal * winningBet / winningTotal;

                    //calculate house share
                    const houseShare = subtotal / 100;

                    //calculate final prize for user
                    const prize = subtotal - houseShare;

                    const tx = await contract.checkStatusAndPay(game.id);
    
                    // check emited events content
                    const res = await tx.wait();
                    const event = res.events[0];
    
                    // check values in broadcasted events
                    expect(event.args.message).to.equal("Prize sent to user address");
                    expect(event.args.user).to.equal(addr1.address);
                    expect(event.args.amount).to.equal(prize);
                })
            })
            
            describe("if multiple winners share the prize", function() {
                let losingBet = 8000;
                let winningBet1 = 6000;
                let winningBet2 = 4000;

                before(async function() {
                    // create Game
                    await oracle.addGame("Chelsea vs Arsenal", ["Chelsea", "Arsenal"], tomorrowUnix());
                    const games = await oracle.getAllGames();
                    game = games[games.length-1];
    
                    // user places Bet on Arsenal
                    await contract.connect(addr1).placeBet(game.id, 2, { from: addr1.address, value: winningBet1 });

                    // user places Bet on Arsenal
                    await contract.connect(addr3).placeBet(game.id, 2, { from: addr3.address, value: winningBet2 });
    
                    // admin places Bet on Chelsea
                    await contract.connect(addr2).placeBet(game.id, 1, { from: addr2.address, value: losingBet });
    
                    // set status Completed
                    await oracle.setGameCompleted(game.id);
    
                    // set Fluminense as winner
                    await oracle.setGameWinner(game.id, 2);
                })
    
                it("it pays prizes properly to each winner", async function() {
                    winningTotal = winningBet1 + winningBet2;
                    losingTotal = losingBet;

                    const subtotal1 = winningBet1 + losingTotal * winningBet1 / winningTotal;
                    const subtotal2 = winningBet2 + losingTotal * winningBet2 / winningTotal;

                    //calculate house share
                    const houseShare1 = subtotal1 / 100;
                    const houseShare2 = subtotal2 / 100;

                    //calculate final prize for user
                    const prize1 = subtotal1 - houseShare1;
                    const prize2 = subtotal2 - houseShare2;

                    const tx = await contract.checkStatusAndPay(game.id);
    
                    // check emited events content
                    const res = await tx.wait();
    
                    // check values in broadcasted events for first winner addr1
                    expect(res.events[0].args.message).to.equal("Prize sent to user address");
                    expect(res.events[0].args.user).to.equal(addr1.address);
                    expect(res.events[0].args.amount).to.equal(prize1);
    
                    // check values in broadcasted events for second winner addr3
                    expect(res.events[1].args.message).to.equal("Prize sent to user address");
                    expect(res.events[1].args.user).to.equal(addr3.address);
                    expect(res.events[1].args.amount).to.equal(prize2);
                })
            })
        })
    }) 
});
