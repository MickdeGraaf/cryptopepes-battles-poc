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
      bool hasRevealed;
  }
  mapping (uint256 => Battle) public battles;
  uint256 battleCounter;

  struct Battle {
      uint256 seq;
      Player[] players;
      uint256 stakePerPlayer;
      address lastPlayerMoved;
      bool active;
  }

  function newBattle(uint256[] _pepes, bytes32 _randomHash, address _oponent) payable public {
      Battle storage battle = battles[battleCounter]; // creates new battle with ID of battleCounter
      battleCounter += 1; // increases for next battle to be higher

      battle.players.length = 2; // allows 2 players in array

      battle.players[0].playerAddress = msg.sender; // sets player 0 to be the sender of newBattle command
      battle.players[1].playerAddress = _oponent; //????? why send opoment. not checking it at joinbattle
      battle.players[0].randomHash = _randomHash; // sets initial random hash. player creates this.

      for(uint256 i = 0; i < _pepes.length; i ++) { // adds default pepes based on _pepes parameter (for exmp 10)
          battle.players[0].pepes.push(BattlePep(_pepes[i], 10000));
      }

      battle.stakePerPlayer = msg.value; // sets ETH stake to be equal to the amount send with message

      emit NewBattle(battleCounter - 1, msg.sender, _oponent, _pepes, msg.value); // emits read-able event in chain listing the above
  }

  function joinBattle(uint256 _battle, uint256[] _pepes, bytes32 _randomHash) payable public {
      Battle storage battle = battles[_battle]; // uses the _battle parameter number to find the correct battle in the contract to join.
      require(battle.players[1].playerAddress == msg.sender || battle.players[1].playerAddress == address(0)); // requires player 2 to be the sender of this function or default?
      require(battle.active == false); // requires this battle's status to be non active. 

      if(battle.players[1].playerAddress != msg.sender) { // if not yet set. set player 2 to be equal to msg sender
        battle.players[1].playerAddress = msg.sender;
      }

      require(msg.value == battle.stakePerPlayer); // required the value of the message to be the same as the initial sender
      require(battle.players[0].pepes.length == _pepes.length); // same amount of pepes in battle

      battle.players[1].randomHash = _randomHash; // saves players 2 initial random hash.

      for(uint256 i = 0; i < _pepes.length; i ++) { // adds p2 pepes to battle
          battle.players[1].pepes.push(BattlePep(_pepes[i], 10000));
      }

      battle.active = true; // sets battle active so its not to be joined again
     

      emit BattleStarted(_battle, battle.players[0].playerAddress, msg.sender, msg.value); // emit above on chain
  }

  event NewBattle(uint256 ID, address indexed playerOne, address indexed playerTwo, uint256[] pepes, uint256 stake);
  event BattleStarted(uint256 ID, address indexed playerOne, address indexed playerTwo, uint256 stake);


  constructor() {
    // constructor
  }

    function continueGame(uint256 _battle, uint256 _seq, uint8 _move, bytes32 _hash) public { // renamed from 'move' to 'continueGame' to clarify its about the game state and nothing to do with pepe moves.
      require(_seq % 2 == getPlayerOneOrTwo(_battle, msg.sender)); // requires that the game seq modules 2 (4 % 2 = 0.... 5 % 2 = 1) 
// to either be 0 or 1, so player 1 turn or player 2 turn,  then check if sender is player 1 or 2.  if sender of message is valid for turn.....


// this is unfair however because this always makes player 2 the one to pay for reveal move and doTurn. 
// i suggest a require boolean to check if a player already did submit move / revealed move. dont go into function. 
// reset boolean at doTurn.
// this might also eliminate the need to check at what seq you are as this does not matter. it will not reveal without both players having true on submit. 
// it will not submit twice of increase seq for a player that tries to submit twice. 

      if(_seq % 4 < 2) { // we start at 0. so
        /* 
        0.S % 4 = 0 = sub,
        1.S % 4 = 1 = sub
        2.R % 4 = 2 = reveal
        3.R % 4 = 3 = reveal
        4.S % 4 = 0 = sub
        5.S % 4 = 1 = sub */
        submitMove(_battle, _hash); 
      }
      else{
        revealMove(_battle, _hash, _move); 
      }

      battles[_battle].seq += 1; // increase seq / turns. proceed to next move.

  }

  function submitMove(uint256 _battle, bytes32 _moveHash) internal {
      Battle storage battle = battles[_battle]; // use battle id to specify game
      uint8 player = getPlayerOneOrTwo(_battle, msg.sender); //finds out of sender of this message is either p1 or p2
      battle.players[player].moveHash = _moveHash; // puts the hash on chain that has encrypted data of chosen move. player makes this on client side. randomhash + chosen move
  }


  function revealMove(uint256 _battle, bytes32 _hash, uint8 _move) internal {
      Battle storage battle = battles[_battle]; // specify game
      uint8 player = getPlayerOneOrTwo(_battle, msg.sender); // find if sender is p1 or p2

      require(battle.players[player].randomHash == keccak256(_hash)); // require the players random hash *(initial random set hash on join) to be equal to the _hash parameter send now.
      require(battle.players[player].moveHash == keccak256(_move, _hash)); // requires player moveHash *(set in submit move above) to be equal to a chosen move + the random/initial hash.
      // this means that the chosen move uppon "reveal" has to be the same as the move on "submit" and therefore unchanged. or the hash outcome would not equal
      battle.players[player].move = _move; // save the checked and submitted move to be excuted.
      battle.players[player].randomHash = _hash; // ?????? why are we setting the random hash again. its not changed as the player submits his old hash + move 
      //???? why are we calling it _hash and not _randomHash as its done when creating the game? 
      battle.players[player].hasRevealed = true; // sets hasRevealed to true for player that reveals move. 
    /*   if(battle.seq % 4 == 0) { // check if current move in set is 4th, invalid as seq starts at 0. and also unfair for paying.
          doTurn(_battle);
      } */

      if (battle.players[getOpponent(player)].hasRevealed && battle.players[player].hasRevealed)
      {
          // if both players revealed. the last player that reveals has to pay for doTurn. 
          // currently this is always player 2 as its still based on continueGame function. See new idea.
          doTurn(_battle);
      }
  }

  function doTurn(uint256 _battle) internal {
      Battle storage battle = battles[_battle]; // locate battle

      uint8 playerFirst = uint8(battle.seq % 2); // this function has no use as its always the same result because turn based on continueGame function,
      uint8 playerSecond = uint8((battle.seq + 1) % 2); // player 2 will always have to pay for doTurn and battle.seq % 2 will always be 1(player 2) 
// seq = 3. % 

// we want this function to be paid by the slowest player. last revealing. see above. We want the move's to excute on pepe speed order. incase of a draw. player last revealed goes second.
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

  function handleLoss(uint256 _battle, uint256 _loser) internal {
      Battle storage battle = battles[_battle];
      uint256 winner;

      if(_loser == 1) {
          winner = 0;
      }
      else {
          winner = 1;
      }

      if(!battle.players[winner].playerAddress.send(battle.stakePerPlayer * 2)) {
        //nothing;
        // is this for when sending fails?
        //yes so players cannot halt battles locking funds via a smart contract
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




                        /* STATE -------------------------------------------------------------------------------------------------------------------------------------------*/ /* move ------------------------------------------------- */
  function continueGameFromState(uint256 _battle, uint8 _seq, uint256[] pepHealths, uint8[2] selectedPepe, bytes32[2] randomHash, bytes32[2] submittedMoves, uint8[2] revealedMoves, bytes32 _hash, uint8 _move, bytes _signature ) public {
      Battle storage battle = battles[_battle];

      require(_seq > battle.seq); //seq must be greater than current

      bytes32 message = prefixed(keccak256(address(this), _seq, pepHealths, selectedPepe, randomHash, submittedMoves,  revealedMoves ));
      require(recoverSigner(message, _signature) == battle.players[getOpponent(getPlayerOneOrTwo(_battle, msg.sender))].playerAddress);

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

      continueGame(_battle, _seq, _move, _hash);(_battle, _seq, _move, _hash);

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
