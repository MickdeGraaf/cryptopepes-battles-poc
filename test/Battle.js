let Battles = artifacts.require("BattlesState.sol");
let sha3 = require('solidity-sha3');
let tryCatch = require("../helpers/exceptions.js").tryCatch;
let errTypes = require("../helpers/exceptions.js").errTypes;

sha3 = sha3.default;

let battlesInstance;


let playerOneHashes = [];
let playerTwoHashes = [];

playerOneHashes.push(sha3(68657057));
playerTwoHashes.push(sha3(68657472));


for(var i = 0; i < 1000; i ++) {
  playerOneHashes.push(sha3(playerOneHashes[i]));
  playerTwoHashes.push(sha3(playerTwoHashes[i]));
}

playerOneRandomHash = playerOneHashes[playerOneHashes.length - 1];
playerTwoRandomHash = playerTwoHashes[playerTwoHashes.length - 1];

let battleid = 0;


contract('Battles', function(accounts) {

  it("Starting a battle should work", async function() {
      battlesInstance = await Battles.deployed();
      battlesInstance.newBattle([1,2], playerOneRandomHash, "0x0000000000000000000000000000000000000000");
  });

  it("Joining a battle should work", async function() {
      battlesInstance.joinBattle(battleid, [3,4], playerTwoRandomHash, {from: accounts[1]});
  });

  it("get battle stats seq should be 0 ", async function() {
    var stats = (await battlesInstance.getBattleStats1.call(0));
    //console.log(moves);
    assert.equal(stats[0], 0);
});

  it("P1 continueGame and submitting move should work", async function() {
      var seq =0;
      moveHash = sha3(playerOneRandomHash, "5" );
      battlesInstance.continueGame(battleid, seq, null, moveHash, {from: accounts[0]});
  });
  /** Player 1 submitting move using seq of 0. 
Player 2 has to wait?  Player 2 submitting move seq has to be 1..  How to show in layout? 
"wait for p1 to sub move.." or submit the move of p2 whenever but only excute submit after 1. this will require a web3call to check if p1 submitted? ..
 */

  it("P1 continueGame and submitting move twice while not p1's turn should revert", async function() {
    var seq = 1;
    moveHash = sha3(playerOneRandomHash, "5" );
    await tryCatch(battlesInstance.continueGame(battleid, seq, null, moveHash,  {from: accounts[0]}),errTypes.revert);
  });
/** because seq check makes sure its not his players turn.  */

  it("P2 continueGame and submitting move should work", async function() {
    var seq = 1;
    moveHash = sha3(playerOneRandomHash, "2" );
    battlesInstance.continueGame(battleid, seq, null, moveHash, {from: accounts[1]});
});

it("get battle stats seq should be 1 ", async function() {
    var stats = (await battlesInstance.getBattleStats1.call(0));
    assert.equal(stats[0], 1);
});

it("P1 continueGame with a lower seq should revert", async function() {
    var seq = 0;
    moveHash = sha3(playerOneRandomHash, "5" );
    await tryCatch(battlesInstance.continueGame(battleid, seq, null, moveHash,  {from: accounts[0]}),errTypes.revert);
  });

  it("")

})
