let Battles = artifacts.require("BattlesState.sol");
let sha3 = require('solidity-sha3');
let tryCatch = require("../helpers/exceptions.js").tryCatch;
let errTypes = require("../helpers/exceptions.js").errTypes;
var ethereumjsabi = require('ethereumjs-abi') // replace with web3.utils? 1.0?
var Web3Utils = require('web3-utils');



sha3 = sha3.default;

let battlesInstance;


/* let playerOneHashes = [];
let playerTwoHashes = [];

playerOneHashes.push(sha3(68657057));
playerTwoHashes.push(sha3(68657472));


for(var i = 0; i < 1000; i ++) {
  playerOneHashes.push(sha3(playerOneHashes[i]));
  playerTwoHashes.push(sha3(playerTwoHashes[i]));
}

//playerOneRandomHash = playerOneHashes[playerOneHashes.length - 1];
//playerTwoRandomHash = playerTwoHashes[playerTwoHashes.length - 1];
console.log(playerOneHashes[playerOneHashes.length - 1]);
console.log(playerTwoHashes[playerTwoHashes.length - 1]); */
let playerOneRandomHash = '0x51e0466ae9ad217ddde891d5d5e00925ce2b92e577cd966aab00863823bfb6c9'
let playerTwoRandomHash = '0xa7b77a420908ff0fc96fc28f92f2286c0dd9c659cc812e87b1e46eb687dcd617'

let battleid = 0;
let playerOneMove = 5;
let playerTwoMove = 3;
let seq = 0;
let startHealth = 30;
let stakeAmount = 2.5;
let balancePlayerOne;

contract('Full battle.', function(accounts) {
  

  it("Starting a battle should work", async function() {
      battlesInstance = await Battles.deployed();
      battlesInstance.newBattle([1,2], playerOneRandomHash, "0x0000000000000000000000000000000000000000", {value: web3.toWei(stakeAmount, "ether"), from: accounts[0]});
     
      var NewBattle = battlesInstance.NewBattle( {fromBlock: 0, toBlock: 'latest'});
      NewBattle.watch(function(error, result){
       //console.log(result);
       NewBattle.stopWatching();
    });

    var PayOutFail = battlesInstance.PayOutFail( {fromBlock: 0, toBlock: 'latest'});
    PayOutFail.watch(function(error, result){
     console.log(result);
     console.log(error);
     PayOutFail.stopWatching();
  });
    });

    

  it("Joining a battle should work", async function() {
      battlesInstance.joinBattle(battleid, [3,4], playerTwoRandomHash, {value: web3.toWei(stakeAmount, "ether"),from: accounts[1]});
  });

  it("Contract should own stake times 2 eth. currently: " + stakeAmount *2, async function() {
    var bal = web3.eth.getBalance(battlesInstance.address).toString();
    assert.equal(web3.fromWei(bal, 'ether'), stakeAmount *2);
});


it("Getting P1 balance. Saving for later.", async function() {
  balancePlayerOne = web3.eth.getBalance(accounts[0]).toString();
  console.log(balancePlayerOne);
});


  it("Get battle stats seq should be 0 ", async function() {
    var stats = (await battlesInstance.getBattleStats1.call(0));
    assert.equal(stats[0], 0);
});

  it("P1 continueGame and submitting move should work", async function() {
      var seq =0;
     var moveHash = "0x" + ethereumjsabi.soliditySHA3(
        ["uint8", "bytes32"],
        [playerOneMove, playerOneRandomHash]
      ).toString("hex");
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

  it("Should Return a P1 movehash keccak256 & should equal P1 web3 1.0 utils.soliditySHA3. ", async function(){
    var kekkack256 = (await battlesInstance.returnHashFromMoveAndHash(playerOneMove, playerOneRandomHash,  {from: accounts[0]})) ;
   // console.log(kekkack256);
    var moveHash = Web3Utils.soliditySha3({t: 'uint8', v: playerOneMove}, {t: 'bytes32', v:playerOneRandomHash});
   /*  var moveHash = "0x" + ethereumjsabi.soliditySHA3(
      ["uint8", "bytes32"],
      [playerOneMove, playerOneRandomHash]
    ).toString("hex"); */
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

/* it("Should return full state", async function(){// get entire state for statechannel string.
  var stats1 = (await battlesInstance.getBattleStats1.call(0));
  var stats2 = (await battlesInstance.getBattleStats2.call(0));
  var stats3 = (await battlesInstance.getBattleStats3.call(0));
  console.log(
   "Seq: " + stats1[0] +
   " Active: " + stats1[1] +
   " P1 Pep1 Health: " + stats1[2] +
   " P1 Pep2 Health: " + stats1[3] +
   " P2 Pep1 Health: " + stats1[4] +
   " P2 Pep2 Health: " + stats1[5] +
   " P1 Sel Pep: " + stats2[0] +
   " P2 Sel Pep: " + stats2[1] +
   " P1 RandHash: " + stats2[2] +
   " P2 RandHash: " + stats2[3] +
   " P1 MoveHash: " + stats3[0] +
   " P2 MoveHash: " + stats3[1] +
   " P1 Move: " + stats3[2] +
   " P2 Move: " + stats3[3] 
   
  );
}); */

it("P1 submit switches pepe and load new randomHash", async function(){
  playerOneRandomHash = (await battlesInstance.returnRandomHash(battleid,  {from: accounts[0]})) ;
  seq = seq +=1;
  console.log(playerOneRandomHash);
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
  console.log(stats[3]);
});
/* 
it("Should return full state, check for match", async function(){
  var stats1 = (await battlesInstance.getBattleStats1.call(0));
  var stats2 = (await battlesInstance.getBattleStats2.call(0));
  var stats3 = (await battlesInstance.getBattleStats3.call(0));
  console.log(
   "Seq: " + stats1[0] +
   " Active: " + stats1[1] +
   " P1 Pep1 Health: " + stats1[2] +
   " P1 Pep2 Health: " + stats1[3] +
   " P2 Pep1 Health: " + stats1[4] +
   " P2 Pep2 Health: " + stats1[5] +
   " P1 Sel Pep: " + stats2[0] +
   " P2 Sel Pep: " + stats2[1] +
   " P1 RandHash: " + stats2[2] +
   " P2 RandHash: " + stats2[3] +
   " P1 MoveHash: " + stats3[0] +
   " P2 MoveHash: " + stats3[1] +
   " P1 Move: " + stats3[2] +
   " P2 Move: " + stats3[3] 
  );
  
});
 */
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
  console.log("turn 1");
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
  console.log("turn 1 ends"); 
  //----------------turn 2
   console.log("turn 2");
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
  console.log("turn 2 ends"); 
  //----------------turn 3
   console.log("turn 3");
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
  console.log("turn 3 ends");
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
  console.log(bal);
  assert.isAbove(parseInt(bal),balancePlayerOne);
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
