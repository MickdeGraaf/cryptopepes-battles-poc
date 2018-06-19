let Battles = artifacts.require("BattlesState.sol");
let tryCatch = require("../helpers/exceptions.js").tryCatch;
let errTypes = require("../helpers/exceptions.js").errTypes;
var ethereumjsabi = require('ethereumjs-abi') // replace with web3.utils? 1.0?
var Web3Utils = require('web3-utils');
var Web3EthAbi = require('web3-eth-abi');

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


      function padBytes32(data){
        console.log
        let l = 66-data.length;
        let x = data.substr(2, data.length);
      
        for(var i=0; i<l; i++) {
          x = 0 + x
        }
        return '0x' + x
      }

    it("Continue Game From State should excute. P1 submit move-seq 03.", async function(){
        playerOneRandomHash = (await battlesInstance.returnRandomHash(battleid,  {from: accounts[0]})) ;
        playerOneMove = 03; 
        var moveHash = "0x" + ethereumjsabi.soliditySHA3(
          ["uint8", "bytes32"],
          [playerOneMove, playerOneRandomHash]
        ).toString("hex");

       
        
        // bytes state builder.
         var stats1 = (await battlesInstance.getBattleStats1.call(0));
         console.log(stats1[2]);
         console.log("hoi " + Web3EthAbi.encodeParameters(['uint8','uint256','uint256','uint256','uint256'], [stats1[0], stats1[2],stats1[3],stats1[4],stats1[5]]));
                  
         
        var _seq = padBytes32(web3.toHex(stats1[0]));
        var _p1p1 = padBytes32(web3.toHex(stats1[2]));
        var _p1p2 = padBytes32(web3.toHex(stats1[3]));
        var _p2p1 = padBytes32(web3.toHex(stats1[4]));
        var _p2p2 = padBytes32(web3.toHex(stats1[5]));
        var state = _seq + 
        _p1p1.substr(2, _p1p1.length) +
        _p1p2.substr(2, _p1p2.length) +
        _p2p1.substr(2, _p2p1.length) +
        _p2p2.substr(2, _p2p2.length) ; 
        //console.log(state);
        //
        //battlesInstance.continueGameFromState("Battle;000.Seq;003.Peps;0012003000110030.Spep;0000.rhash;0xe1f5836ec5a295e2471f91327f18c1fa9a54c272d17437980a74896e6bfb396a0xa2ba5383d7ac579024d84bfc598ef55b6846698370d5600c246858d0c16b4f5f.Hmoves;0xe1f5836ec5a295e2471f91327f18c1fa9a54c272d17437980a74896e6bfb396a0xa2ba5383d7ac579024d84bfc598ef55b6846698370d5600c246858d0c16b4f5f.Rmoves;0503" ,"0x51e0466ae9ad217ddde891d5d5e00925ce2b92e577cd966aab00863823bfb6c9","0x51e0466ae9ad217ddde891d5d5e00925ce2b92e577cd966aab00863823bfb6c9", moveHash, "0" )
        battlesInstance.decomposeState(state , battleid/* "0x51e0466ae9ad217ddde891d5d5e00925ce2b92e577cd966aab00863823bfb6c9","0x51e0466ae9ad217ddde891d5d5e00925ce2b92e577cd966aab00863823bfb6c9", moveHash, "0" */ )
        
      
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
})