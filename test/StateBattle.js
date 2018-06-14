let Battles = artifacts.require("BattlesState.sol");
let tryCatch = require("../helpers/exceptions.js").tryCatch;
let errTypes = require("../helpers/exceptions.js").errTypes;
var ethereumjsabi = require('ethereumjs-abi') // replace with web3.utils? 1.0?

let battlesInstance;


playerOneRandomHash = 0x0000000000000000000000000000000000000321;
playerTwoRandomHash = 0x0000000000000000000000000000000000000123;


let battleid = 0;
let playerOneMove = 5;
let playerTwoMove = 3;
let seq = 0;
let startHealth = 30;
let stakeAmount = 0.5;
let balancePlayerOne;


contract('State continued battle.', function(accounts) {
    it("Starting a battle should work", async function() {
        battlesInstance = await Battles.deployed();
        battlesInstance.newBattle([1,2], playerOneRandomHash, "0x0000000000000000000000000000000000000000", {value: web3.toWei(stakeAmount, "ether"), from: accounts[0]});
      });
  
})