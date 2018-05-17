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

  function move(uint256 _battle, uint256 _seq, uint8 _move, bytes32 _hash) public {

      require(_seq - 1 % 2 == getPlayerOneOrTwo(msg.sender));

      if(_seq % 4 == 3 || _seq % 4 == 0) {
        //submit move
      }
      else{
        //reveal move
      }

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
