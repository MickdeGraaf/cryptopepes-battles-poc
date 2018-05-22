pragma solidity ^0.4.4;


contract BattlesState {

  struct BattlePep {
      uint256 id;
      uint256 health;
  }

  struct Player {
      address playerAddress;
      BattlePep[] pepes;
      bytes32 moveHash;
      uint8 move;
      uint8 selectedPepe;
      bytes32 randomHash;
  }

  mapping (uint256 => Battle) public battles;
  uint256 battleCounter;

  struct Battle {
      uint256 seq;
      Player[] players;
      uint256 stakePerPlayer;
      address lastPlayerMoved;
      uint256 turnCounter;
      bool active;
  }

  function newBattle(uint256[] _pepes, bytes32 _randomHash, address _oponent) payable public {
      Battle storage battle = battles[battleCounter];
      battleCounter += 1;

      battle.players.length = 2;

      battle.players[0].playerAddress = msg.sender;
      battle.players[1].playerAddress = _oponent;
      battle.players[0].randomHash = _randomHash;

      for(uint256 i = 0; i < _pepes.length; i ++) {
          battle.players[0].pepes.push(BattlePep(_pepes[i], 10000));
      }

      battle.stakePerPlayer = msg.value;

      emit NewBattle(battleCounter - 1, msg.sender, _oponent, _pepes, msg.value);
  }

  function joinBattle(uint256 _battle, uint256[] _pepes, bytes32 _randomHash) payable public {
      Battle storage battle = battles[_battle];
      require(battle.players[1].playerAddress == msg.sender || battle.players[1].playerAddress == address(0));
      require(battle.active == false);

      if(battle.players[1].playerAddress != msg.sender) {
        battle.players[1].playerAddress = msg.sender;
      }

      require(msg.value == battle.stakePerPlayer);
      require(battle.players[0].pepes.length == _pepes.length);

      battle.players[1].randomHash = _randomHash;

      for(uint256 i = 0; i < _pepes.length; i ++) {
          battle.players[1].pepes.push(BattlePep(_pepes[i], 10000));
      }

      battle.active = true;

      emit BattleStarted(_battle, battle.players[0].playerAddress, msg.sender, msg.value);
  }

  event NewBattle(uint256 ID, address indexed playerOne, address indexed playerTwo, uint256[] pepes, uint256 stake);
  event BattleStarted(uint256 ID, address indexed playerOne, address indexed playerTwo, uint256 stake);


  constructor() {
    // constructor
  }

  function submitMove(uint256 _battle, bytes32 _hash) internal {
      Battle storage battle = battles[_battle];
      uint8 player = getPlayerOneOrTwo(_battle, msg.sender);
      battle.players[player].moveHash = _hash; // movehash is a int? or a hash? @revealMove we got another _move?
  }


  function revealMove(uint256 _battle, bytes32 _hash, uint8 _move) internal {
      Battle storage battle = battles[_battle];
      uint8 player = getPlayerOneOrTwo(_battle, msg.sender);

      require(battle.players[player].randomHash == keccak256(_hash)); //check if new hash is correct  // what is _nextHash? where do we get this. why would it be equal to randomHash?
      //_nextHash is submitted as a parameter and is the next hash in the hashchain
      require(battle.players[player].moveHash == keccak256(_move, _hash)); // moveHash from submit move should be equal to the _move with _nextHash? so we submit move twice?
      //the move is submitted by submitting the hash. It is submitted once and revealed once
      battle.players[player].move = _move;
      battle.players[player].randomHash = _hash; //does this needs to be returned to the player?
      //the player already knows this as he submitted it
      //yes lets do that! It creates an incentive to submit moves fast as it saves tx fee to be the first

      if(battle.seq % 4 == 0) { //if other player submitted do turn
          doTurn(_battle);
      }
  }

  function doTurn(uint256 _battle) internal { //who calls doTurn and revealMove?
      //reveal move needs to be called by each player, doTurn now gets called by the last player revealing
      Battle storage battle = battles[_battle];

      uint8 playerFirst = uint8(battle.turnCounter % 2);
      uint8 playerSecond = uint8((battle.turnCounter + 1) % 2); // second is with one C

      doMove(_battle, playerFirst);
      doMove(_battle, playerSecond);


  }

  function doMove(uint256 _battle, uint8 _player) internal {
      Battle storage battle = battles[_battle];
      uint8 move = battle.players[_player].move;
      uint8 oponent;
      if(_player == 0){
        oponent = 1;
      }
      else {
        oponent = 0;
      }

      if(move > 9){ //if the player is switching pepe
          uint8 pepeSelected = move - 10;
          if(pepeSelected > battle.players[_player].pepes.length || battle.players[_player].pepes[pepeSelected].health == 0) {
            handleLoss(_battle, _player);//player tried to select non existent or dead pepe he dies
          }
          else{ //everything ok select other pepe
            battle.players[_player].selectedPepe = pepeSelected;
          }
      }
      else { //normal move
          uint256 selectedPepe = battle.players[oponent].selectedPepe;
          uint256 oponentPepeHealth = battle.players[oponent].pepes[selectedPepe].health;

          uint256 damage = 10 + uint256(battle.players[oponent].randomHash) % 10;

          if(damage > oponentPepeHealth) { //if oponent pepe dies with this blow
              battle.players[oponent].pepes[selectedPepe].health = 0;
              autoSwitchPepe(_battle, oponent);
          }
          else { //else deduct damage from health
              battle.players[oponent].pepes[selectedPepe].health -= damage; // emit some event or web3 has to "fetch" the new health? //yes we need that
              // external view function to get current battle state and pepe's health? //yes we need that
          }
      }

  }

  function autoSwitchPepe(uint256 _battle, uint256 _player) internal {
      Battle storage battle = battles[_battle];
      for(uint256 i = 0; i < battle.players[_player].pepes.length; i ++) {
          if(battle.players[_player].pepes[i].health > 0) {
             battle.players[_player].selectedPepe = uint8(i); // do we need some sort of getPepe by id?
             return; // if no new pepe. continue to handle loss.
          }
      }
      handleLoss(_battle, _player);
  }

  function move(uint256 _battle, uint256 _seq, uint8 _move, bytes32 _hash) public {
      require(_seq % 2 == getPlayerOneOrTwo(msg.sender));

      if(_seq % 4 == 3 || _seq % 4 == 0) {
        submitMove(_battle, _hash);
      }
      else{
        revealMove(_battle, _hash, _move);
      }

      battles[_battle].seq += 1;

  }
                        /* STATE -------------------------------------------------------------------------------------------------------------------------------------------*/ /* move ------------------------------------------------- */
  function moveFromState(uint256 _battle, uint8 _seq, uint256[] pephealths, uint8[2] selectedPepe, bytes32[2] randomHash, bytes32[2] submittedMoves, uint8[2] revealedMoves, bytes32 _hash, uint8 _move, bytes _signature ) public {
      Battle storage battle = battles[_battle];

      require(_seq > battle.seq); //seq must be greater than current

      bytes32 message = prefixed(keccak256(address(this), _seq, pephealths, selectedPepe, randomHash, submittedMoves,  revealedMoves ));
      require(recoverSigner(message, _signature) == battle.players[getOpponent(getPlayerOneOrTwo(_battle, msg.sender))]);

      //update STATE

      battle.seq = _seq;

      for(uint256 i = 0; i < pepHealths.length / 2; i ++) {
          battle.players[0].pepes[i].health = pepHealths[i];
      }

      for(uint256 ii = pepHealths.length / 2; ii < pepHealths.length; ii ++) {
          battle.players[0].pepes[ii - pepHealths.length / 2].health = pepHealths[ii];
      }

      Player playerOne = battle.players[0];
      Player playerTwo = battle.players[1];


      playerOne.selectedPepe = selectedPepe[0];
      playerTwo.selectedPepe = selectedPepe[1];

      playerOne.randomHash = randomHash[0];
      playerTwo.randomHash = randomHash[1];

      playerOne.moveHash = submittedMoves[0];
      playerTwo.moveHash = submittedMoves[1];

      playerOne.move = revealedMoves[0];
      playerTwo.move = revealedMoves[1];

      move(_battle, _seq, _move _hash);

  }


  function getOpponent(uint8 _player) returns(uint8 oponent) {
      if(_player == 0){
        oponent = 1;
      }
      else {
        oponent = 0;
      }
  }

  function getPlayerOneOrTwo(uint256 _battle, address _player) view public returns(uint8) {
      Battle storage battle = battles[_battle];

      if(battle.players[0].playerAddress == _player) {
        return 0;
      }
      else if(battle.players[1].playerAddress == _player) { // check array at 1. not 0.
        return 1;
      }
      else {
        revert();
      }
  }


  // Signature methods

   function splitSignature(bytes sig)
       internal
       pure
       returns (uint8, bytes32, bytes32)
   {
       require(sig.length == 65);

       bytes32 r;
       bytes32 s;
       uint8 v;

       assembly {
           // first 32 bytes, after the length prefix
           r := mload(add(sig, 32))
           // second 32 bytes
           s := mload(add(sig, 64))
           // final byte (first byte of the next 32 bytes)
           v := byte(0, mload(add(sig, 96)))
       }

       return (v, r, s);
   }

   function recoverSigner(bytes32 message, bytes sig)
       internal
       pure
       returns (address)
   {
       uint8 v;
       bytes32 r;
       bytes32 s;

       (v, r, s) = splitSignature(sig);

       return ecrecover(message, v, r, s);
   }

   // Builds a prefixed hash to mimic the behavior of eth_sign.
   function prefixed(bytes32 hash) internal pure returns (bytes32) {
       return keccak256("\x19Ethereum Signed Message:\n32", hash);
   }

}
