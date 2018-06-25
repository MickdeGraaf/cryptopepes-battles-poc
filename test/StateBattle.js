let Battles = artifacts.require("BattlesState.sol");
let tryCatch = require("../helpers/exceptions.js").tryCatch;
let errTypes = require("../helpers/exceptions.js").errTypes;
var ethereumjsabi = require('ethereumjs-abi') // replace with web3.utils? 1.0?
var Web3Utils = require('web3-utils');
var Web3EthAbi = require('web3-eth-abi');
var Web3General = require('web3-eth');
const Utils = require('./helpers/utils');
const ethutil = require('ethereumjs-util');

let battlesInstance;


playerOneRandomHash = 0x51e0466ae9ad217ddde891d5d5e00925ce2b92e577cd966aab00863823bfb6c9;
playerTwoRandomHash = 0xa7b77a420908ff0fc96fc28f92f2286c0dd9c659cc812e87b1e46eb687dcd617;


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
  
      it("Joining a battle should work", async function() {
        battlesInstance.joinBattle(battleid, [3,4], playerTwoRandomHash, {value: web3.toWei(stakeAmount, "ether"),from: accounts[1]});
    });
  

    it("Get battle stats seq should be 0 ", async function() {
        var stats = (await battlesInstance.getBattleStats1.call(0));
        assert.equal(stats[0], 0);
    });

    it("Should return full state, should be 'empty'", async function(){
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

    it("Continue Game From State should excute. P1 submit move-seq 03.", async function(){
        playerOneRandomHash = (await battlesInstance.returnRandomHash(battleid,  {from: accounts[0]})) ;
        playerOneMove = 03; 
        var moveHash = "0x" + ethereumjsabi.soliditySHA3(
          ["uint8", "bytes32"],
          [playerOneMove, playerOneRandomHash]
        ).toString("hex");

        var inputs = []
        inputs.push(2)//seq
        inputs.push(12)//p1p1h
        inputs.push(30)//p1p2
        inputs.push(11)//p2p1
        inputs.push(30)//p2p2
        inputs.push(0)//p1spep
        inputs.push(0)//p2spep
        inputs.push("0xe1f5836ec5a295e2471f91327f18c1fa9a54c272d17437980a74896e6bfb396a")//p1rhash
        inputs.push("0xa2ba5383d7ac579024d84bfc598ef55b6846698370d5600c246858d0c16b4f5f")//p2rhash
        inputs.push("0xe1f5836ec5a295e2471f91327f18c1fa9a54c272d17437980a74896e6bfb396a")//p1movehash
        inputs.push("0xa2ba5383d7ac579024d84bfc598ef55b6846698370d5600c246858d0c16b4f5f")//p2movehash
        inputs.push(05)//p2movehash
        inputs.push(03)//p2movehash

      //  console.log(inputs); 
        stateCompressed= Utils.marshallState(inputs)
       // console.log(stateCompressed);
     
       var stateHashed = Web3Utils.soliditySha3(stateCompressed).toString("hex");
       var opponentsignature = web3.eth.sign(accounts[1],stateHashed);

        //battlesInstance.continueGameFromState("Battle;000.Seq;003.Peps;0012003000110030.Spep;0000.rhash;0xe1f5836ec5a295e2471f91327f18c1fa9a54c272d17437980a74896e6bfb396a0xa2ba5383d7ac579024d84bfc598ef55b6846698370d5600c246858d0c16b4f5f.Hmoves;0xe1f5836ec5a295e2471f91327f18c1fa9a54c272d17437980a74896e6bfb396a0xa2ba5383d7ac579024d84bfc598ef55b6846698370d5600c246858d0c16b4f5f.Rmoves;0503" ,"0x51e0466ae9ad217ddde891d5d5e00925ce2b92e577cd966aab00863823bfb6c9","0x51e0466ae9ad217ddde891d5d5e00925ce2b92e577cd966aab00863823bfb6c9", moveHash, "0" )
        battlesInstance.importState(stateCompressed, battleid/* ,opponentsignature */);
        
      
    });

    it("Should print sign", async function(){
        var inputs = []
        inputs.push(2)//seq
        inputs.push(12)//p1p1h
        inputs.push(30)//p1p2
        inputs.push(11)//p2p1
        inputs.push(30)//p2p2
        inputs.push(0)//p1spep
        inputs.push(0)//p2spep
        inputs.push("0xe1f5836ec5a295e2471f91327f18c1fa9a54c272d17437980a74896e6bfb396a")//p1rhash
        inputs.push("0xa2ba5383d7ac579024d84bfc598ef55b6846698370d5600c246858d0c16b4f5f")//p2rhash
        inputs.push("0xe1f5836ec5a295e2471f91327f18c1fa9a54c272d17437980a74896e6bfb396a")//p1movehash
        inputs.push("0xa2ba5383d7ac579024d84bfc598ef55b6846698370d5600c246858d0c16b4f5f")//p2movehash
        inputs.push(05)//p2movehash
        inputs.push(03)//p2movehash
        stateCompressed= Utils.marshallState(inputs)
        
        var stateHashed = Web3Utils.soliditySha3(stateCompressed).toString("hex");
        console.log( web3.eth.sign(accounts[0],stateHashed));
        
    });

    it("Should return full state, Should be filled.", async function(){
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


      it("P1 submit switches pepe and load new randomHash", async function(){
        playerOneRandomHash = (await battlesInstance.returnRandomHash(battleid,  {from: accounts[0]})) ;
        seq =4
        playerOneMove = 11; // selects second pepe. 
        var moveHash = "0x" + ethereumjsabi.soliditySHA3(
          ["uint8", "bytes32"],
          [playerOneMove, playerOneRandomHash]
        ).toString("hex");
        battlesInstance.continueGame(battleid, seq, null, moveHash,  {from: accounts[0]});
      
      });
      
      it("P2 submit move and load new randomHash", async function(){
        playerTwoRandomHash = (await battlesInstance.returnRandomHash(battleid,  {from: accounts[1]})) ;
        seq = 5;
        playerTwoMove = 3;
        var moveHash = "0x" + ethereumjsabi.soliditySHA3(
          ["uint8", "bytes32"],
          [playerTwoMove, playerTwoRandomHash]
        ).toString("hex"); 
        battlesInstance.continueGame(battleid, seq, null, moveHash,  {from: accounts[1]});
      });
      
      it("P1 continueGame doing move-reveal should work", async function(){
        seq = 6;
        battlesInstance.continueGame(battleid, seq, playerOneMove, playerOneRandomHash,  {from: accounts[0]});
      });
      
      it("P2 continueGame doing move-reveal should work", async function(){
        seq = 7;
        battlesInstance.continueGame(battleid, seq, playerTwoMove, playerTwoRandomHash,  {from: accounts[1]});
      });

      it("P1's second pepe should have 13 health", async function() {
        var stats = (await battlesInstance.getBattleStats1.call(0));
        assert.equal(stats[3]+"", "13");
        //console.log(stats[3]);
      });

    /*   it("Should return full state, check for match", async function(){
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
      

})