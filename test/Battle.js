let Battles = artifacts.require("Battles");
let sha3 = require('solidity-sha3');
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

contract('Battles', function(accounts) {

  it("Starting a battle should work", async function() {
      battlesInstance = await Battles.deployed();
      battlesInstance.newBattle([1,2,3,4,5], playerOneHashes[playerOneHashes.length - 1], "0x0000000000000000000000000000000000000000");
  });

  it("Joining a battle should work", async function() {
      battlesInstance.joinBattle(0, [6,7,8,9,10], playerTwoHashes[playerTwoHashes.length - 1], {from: accounts[0]});
  });

  it("Submitting a turn should work", async function() {

  });

  it("Submitting a turn twice should fail", asyc function() {

  });

})
