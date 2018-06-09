let Battles = artifacts.require("BattlesState.sol");
let sha3 = require('solidity-sha3');
let tryCatch = require("../helpers/exceptions.js").tryCatch;
let errTypes = require("../helpers/exceptions.js").errTypes;
var ethereumjsabi = require('ethereumjs-abi') // replace with web3.utils? 1.0?

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
let playerOneMove = 5;
let playerTwoMove = 3;
let seq = 0;
let startHealth = 30;
let stakeAmount = 0.5;
let balancePlayerOne;

contract('Full battle.', function(accounts) {

  it("Starting a battle should work", async function() {
      battlesInstance = await Battles.deployed();
      battlesInstance.newBattle([1,2], playerOneRandomHash, "0x0000000000000000000000000000000000000000", {value: web3.toWei(stakeAmount, "ether"), from: accounts[0]});
    });

  it("Joining a battle should work", async function() {
      battlesInstance.joinBattle(battleid, [3,4], playerTwoRandomHash, {value: web3.toWei(stakeAmount, "ether"),from: accounts[1]});
  });

  it("Contract should own stake times 2 eth", async function() {
    var bal = web3.eth.getBalance(battlesInstance.address).toString();
    assert.equal(web3.fromWei(bal, 'ether'), stakeAmount *2);
});


it("Getting P1 balance. Saving for later.", async function() {
  balancePlayerOne = web3.eth.getBalance(accounts[0]).toString();
});


  it("Get battle stats seq should be 0 ", async function() {
    var stats = (await battlesInstance.getBattleStats1.call(0));
    assert.equal(stats[0], 0);
});

  it("P1 continueGame and submitting move should work", async function() {
      var seq =0;
     //console.log("Het volgende moet gehashed worden: " + playerOneMove + playerOneRandomHash);
     var moveHash = "0x" + ethereumjsabi.soliditySHA3(
        ["uint8", "bytes32"],
        [playerOneMove, playerOneRandomHash]
      ).toString("hex");
    //  console.log(moveHash);
      battlesInstance.continueGame(battleid, seq, null, moveHash, {from: accounts[0]});
  });
  /** Player 1 submitting move using seq of 0. 
Player 2 has to wait?  Player 2 submitting move seq has to be 1..  How to show in layout? 
"wait for p1 to sub move.." or submit the move of p2 whenever but only excute submit after 1. this will require a web3call to check if p1 submitted? ..
 */

  it("P1 continueGame and submitting move twice while not P1's turn should revert", async function() {
    var seq = 1;
    var moveHash = "0x" + ethereumjsabi.soliditySHA3(
        ["uint8", "bytes32"],
        [playerOneMove, playerOneRandomHash]
      ).toString("hex");
    await tryCatch(battlesInstance.continueGame(battleid, seq, null, moveHash,  {from: accounts[0]}),errTypes.revert);
  });
/** because seq check makes sure its not his players turn.  */

  it("P2 continueGame and submitting move should work", async function() {
    seq = seq +=1;
    var moveHash = "0x" + ethereumjsabi.soliditySHA3(
        ["uint8", "bytes32"],
        [playerTwoMove, playerTwoRandomHash]
      ).toString("hex");
    battlesInstance.continueGame(battleid, seq, null, moveHash, {from: accounts[1]});
});

it("Get battle stats seq should be 1 ", async function() {
    var stats = (await battlesInstance.getBattleStats1.call(0));
    assert.equal(stats[0], 1);
});

it("P1 continueGame with a lower seq should revert", async function() {
    var seq = 0;
    var moveHash = "0x" + ethereumjsabi.soliditySHA3(
        ["uint8", "bytes32"],
        [playerOneMove, playerOneRandomHash]
      ).toString("hex");
    await tryCatch(battlesInstance.continueGame(battleid, seq, null, moveHash,  {from: accounts[0]}),errTypes.revert);
  });

  it("Should Return a P1 hash keccak256 & should equal P1 ethereumjsabi.soliditySHA3. ", async function(){
    var kekkack256 = (await battlesInstance.returnHashFromMoveAndHash(playerOneMove, playerOneRandomHash,  {from: accounts[0]})) ;
    //console.log(kekkack256);
    var moveHash = "0x" + ethereumjsabi.soliditySHA3(
      ["uint8", "bytes32"],
      [playerOneMove, playerOneRandomHash]
    ).toString("hex");
    assert.equal(kekkack256,moveHash);
  });
 

  it("P1 continueGame doing move-reveal should work", async function(){
    seq = seq +=1;
    battlesInstance.continueGame(battleid, seq, playerOneMove, playerOneRandomHash,  {from: accounts[0]});
  });

  it("Get battle stats P1, move should be revealed and 5 ", async function() {
    var stats = (await battlesInstance.getBattleStats3.call(0));
    assert.equal(stats[2], 5);
  });

  it("Get Pepe's health should be " +startHealth , async function() {
    var stats = (await battlesInstance.getBattleStats1.call(0));
    
    assert.equal(stats[3], startHealth);
    assert.equal(stats[5], startHealth);
    
});

  it("P2 continueGame doing move-reveal should work", async function(){
    seq = seq +=1;
    battlesInstance.continueGame(battleid, seq, playerTwoMove, playerTwoRandomHash,  {from: accounts[1]});
  });

  it("Get Pepe's health should be lower then "+startHealth, async function() {
    var stats = (await battlesInstance.getBattleStats1.call(0));
    
    assert.notEqual(stats[2], startHealth);
    assert.notEqual(stats[4], startHealth);
});

it("P1 submit switches pepe and load new randomHash", async function(){
  playerOneRandomHash = (await battlesInstance.returnRandomHash(battleid,  {from: accounts[0]})) ;
  seq = seq +=1;
  playerOneMove = 11; // selects second pepe. 
  var moveHash = "0x" + ethereumjsabi.soliditySHA3(
    ["uint8", "bytes32"],
    [playerOneMove, playerOneRandomHash]
  ).toString("hex");
  battlesInstance.continueGame(battleid, seq, null, moveHash,  {from: accounts[0]});

});

it("P2 submit move and load new randomHash", async function(){
  playerTwoRandomHash = (await battlesInstance.returnRandomHash(battleid,  {from: accounts[1]})) ;
  seq = seq +=1;
  playerTwoMove = 3;
  var moveHash = "0x" + ethereumjsabi.soliditySHA3(
    ["uint8", "bytes32"],
    [playerTwoMove, playerTwoRandomHash]
  ).toString("hex"); 
  battlesInstance.continueGame(battleid, seq, null, moveHash,  {from: accounts[1]});
});

it("P1 continueGame doing move-reveal should work", async function(){
  seq = seq +=1;
  battlesInstance.continueGame(battleid, seq, playerOneMove, playerOneRandomHash,  {from: accounts[0]});
});

it("P2 continueGame doing move-reveal should work", async function(){
  seq = seq +=1;
  battlesInstance.continueGame(battleid, seq, playerTwoMove, playerTwoRandomHash,  {from: accounts[1]});
});

it("P1's second pepe should have less health", async function() {
  var stats = (await battlesInstance.getBattleStats1.call(0));
  assert.notEqual(stats[3], startHealth);
});

it("P1 submit move and load new randomHash", async function(){
  playerOneRandomHash = (await battlesInstance.returnRandomHash(battleid,  {from: accounts[0]})) ;
  seq = seq +=1;
  playerOneMove = 6;  
  var moveHash = "0x" + ethereumjsabi.soliditySHA3(
    ["uint8", "bytes32"],
    [playerOneMove, playerOneRandomHash]
  ).toString("hex");
  battlesInstance.continueGame(battleid, seq, null, moveHash,  {from: accounts[0]});

});

it("P2 submit move and load new randomHash", async function(){
  playerTwoRandomHash = (await battlesInstance.returnRandomHash(battleid,  {from: accounts[1]})) ;
  seq = seq +=1;
  playerTwoMove = 3;
  var moveHash = "0x" + ethereumjsabi.soliditySHA3(
    ["uint8", "bytes32"],
    [playerTwoMove, playerTwoRandomHash]
  ).toString("hex"); 
  battlesInstance.continueGame(battleid, seq, null, moveHash,  {from: accounts[1]});
});

it("P1 continueGame submits move that should kill", async function(){
  seq = seq +=1;
  battlesInstance.continueGame(battleid, seq, playerOneMove, playerOneRandomHash,  {from: accounts[0]});
});

it("P2 continueGame doing move-reveal his pepe should die", async function(){
  seq = seq +=1;
  battlesInstance.continueGame(battleid, seq, playerTwoMove, playerTwoRandomHash,  {from: accounts[1]});
});

it("Pepe of p2 should have 0 hp.", async function(){
  var stats = (await battlesInstance.getBattleStats1.call(0));
 // console.log(stats);
  assert.equal(stats[4], 0);
});

it("Selected (second) pepe of p1 should have 13 hp.", async function(){
  var stats = (await battlesInstance.getBattleStats1.call(0));
  assert.equal(stats[3], 13); // works with 30hp.
});

it("P2's move should be 0 because his pepe died before excuting ", async function(){
  var stats = (await battlesInstance.getBattleStats3.call(0));
  assert.equal(stats[3], 0); 
});

it("P1 submit move and tries to end game. P2 skips by submitting 0. 3 times", async function(){
  //----------------turn 1
  //p1
  playerOneRandomHash = (await battlesInstance.returnRandomHash(battleid,  {from: accounts[0]})) ;
  seq = seq +=1;
  playerOneMove = 6;  
  var moveHash = "0x" + ethereumjsabi.soliditySHA3(
    ["uint8", "bytes32"],
    [playerOneMove, playerOneRandomHash]
  ).toString("hex");
  battlesInstance.continueGame(battleid, seq, null, moveHash,  {from: accounts[0]});
  //p2
  playerTwoRandomHash = (await battlesInstance.returnRandomHash(battleid,  {from: accounts[1]})) ;
  seq = seq +=1;
  playerTwoMove = 0;
  var moveHash = "0x" + ethereumjsabi.soliditySHA3(
    ["uint8", "bytes32"],
    [playerTwoMove, playerTwoRandomHash]
  ).toString("hex"); 
  battlesInstance.continueGame(battleid, seq, null, moveHash,  {from: accounts[1]});
  //p1
  seq = seq +=1;
  battlesInstance.continueGame(battleid, seq, playerOneMove, playerOneRandomHash,  {from: accounts[0]});
  //p2
  seq = seq +=1;
  battlesInstance.continueGame(battleid, seq, playerTwoMove, playerTwoRandomHash,  {from: accounts[1]});
   //----------------turn 2
  //p1
  playerOneRandomHash = (await battlesInstance.returnRandomHash(battleid,  {from: accounts[0]})) ;
  seq = seq +=1;
  playerOneMove = 6;  
  var moveHash = "0x" + ethereumjsabi.soliditySHA3(
    ["uint8", "bytes32"],
    [playerOneMove, playerOneRandomHash]
  ).toString("hex");
  battlesInstance.continueGame(battleid, seq, null, moveHash,  {from: accounts[0]});
  //p2
  playerTwoRandomHash = (await battlesInstance.returnRandomHash(battleid,  {from: accounts[1]})) ;
  seq = seq +=1;
  playerTwoMove = 0;
  var moveHash = "0x" + ethereumjsabi.soliditySHA3(
    ["uint8", "bytes32"],
    [playerTwoMove, playerTwoRandomHash]
  ).toString("hex"); 
  battlesInstance.continueGame(battleid, seq, null, moveHash,  {from: accounts[1]});
  //p1
  seq = seq +=1;
  battlesInstance.continueGame(battleid, seq, playerOneMove, playerOneRandomHash,  {from: accounts[0]});
  //p2
  seq = seq +=1;
  battlesInstance.continueGame(battleid, seq, playerTwoMove, playerTwoRandomHash,  {from: accounts[1]});
   //----------------turn 3
  //p1
  playerOneRandomHash = (await battlesInstance.returnRandomHash(battleid,  {from: accounts[0]})) ;
  seq = seq +=1;
  playerOneMove = 6;  
  var moveHash = "0x" + ethereumjsabi.soliditySHA3(
    ["uint8", "bytes32"],
    [playerOneMove, playerOneRandomHash]
  ).toString("hex");
  battlesInstance.continueGame(battleid, seq, null, moveHash,  {from: accounts[0]});
  //p2
  playerTwoRandomHash = (await battlesInstance.returnRandomHash(battleid,  {from: accounts[1]})) ;
  seq = seq +=1;
  playerTwoMove = 0;
  var moveHash = "0x" + ethereumjsabi.soliditySHA3(
    ["uint8", "bytes32"],
    [playerTwoMove, playerTwoRandomHash]
  ).toString("hex"); 
  battlesInstance.continueGame(battleid, seq, null, moveHash,  {from: accounts[1]});
  //p1
  seq = seq +=1;
  battlesInstance.continueGame(battleid, seq, playerOneMove, playerOneRandomHash,  {from: accounts[0]});
  //p2
  seq = seq +=1;
  battlesInstance.continueGame(battleid, seq, playerTwoMove, playerTwoRandomHash,  {from: accounts[1]});
  
});

it("Battle winner address should be player one's adres", async function(){
  var winner = (await battlesInstance.getWinner.call(0));
  assert.equal(winner, accounts[0]);
});

it("Contract should own 0.0 eth", async function() {
  var bal = web3.eth.getBalance(battlesInstance.address).toString();
  assert.equal(web3.fromWei(bal, 'ether'), 0);
});


it("Winner should own more eth then start", async function() {
  var winner = (await battlesInstance.getWinner.call(0));
  var bal = web3.eth.getBalance(winner).toString();
  assert.isAbove(balancePlayerOne, bal)
});

it("ContinueGame after finish should fail.", async function() {
  seq = seq +=1;
  var moveHash = "0x" + ethereumjsabi.soliditySHA3(
      ["uint8", "bytes32"],
      [playerOneMove, playerOneRandomHash]
    ).toString("hex");
  await tryCatch(battlesInstance.continueGame(battleid, seq, null, moveHash,  {from: accounts[0]}),errTypes.revert);
});


})
