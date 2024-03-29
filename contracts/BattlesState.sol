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

  struct Battle {
      uint256 seq;
      Player[] players;
      uint256 stakePerPlayer;
      address lastPlayerMoved;//notused
      bool active;
      address winner;
  }

  mapping (uint256 => Battle) public battles;
  uint256 battleCounter;
  
 
  function getBattleStats1(uint256 _battleid) view public returns (uint, bool, uint256,uint256,uint256,uint256) {
        return (battles[_battleid].seq,  battles[_battleid].active, battles[_battleid].players[0].pepes[0].health, battles[_battleid].players[0].pepes[1].health,    battles[_battleid].players[1].pepes[0].health,  battles[_battleid].players[1].pepes[1].health        );
    }
    
      function getBattleStats2(uint256 _battleid) view public returns ( uint8,uint8,bytes32,bytes32) {
        return (battles[_battleid].players[0].selectedPepe, battles[_battleid].players[1].selectedPepe,      battles[_battleid].players[0].randomHash,      battles[_battleid].players[1].randomHash    );
    }
       function getBattleStats3(uint256 _battleid) view public returns ( bytes32,bytes32,uint8,uint8) {
        return (battles[_battleid].players[0].moveHash,        battles[_battleid].players[1].moveHash,        battles[_battleid].players[0].move,        battles[_battleid].players[1].move    );
    }



  function newBattle(uint256[] _pepes, bytes32 _randomHash, address _oponent) payable public {
      Battle storage battle = battles[battleCounter]; // creates new battle with ID of battleCounter
      battleCounter += 1; // increases for next battle to be higher
      battle.seq = 0;
      battle.players.length = 2; // allows 2 players in array

      battle.players[0].playerAddress = msg.sender; // sets player 0 to be the sender of newBattle command
      battle.players[1].playerAddress = _oponent; //????? why send opoment. not checking it at joinbattle
      battle.players[0].randomHash = _randomHash; // sets initial random hash. player creates this.

      for(uint256 i = 0; i < _pepes.length; i ++) { // adds default pepes based on _pepes parameter (for exmp 10)
          battle.players[0].pepes.push(BattlePep(_pepes[i], 30));
      }

      battle.stakePerPlayer = msg.value; // sets ETH stake to be equal to the amount send with message

      emit NewBattle(battleCounter - 1, msg.sender, _oponent, _pepes, msg.value); // emits read-able event in chain listing the above
  }

  function joinBattle(uint256 _battle, uint256[] _pepes, bytes32 _randomHash) payable public {
      Battle storage battle = battles[_battle]; // uses the _battle parameter number to find the correct battle in the contract to join.
      require(battle.players[1].playerAddress == msg.sender || battle.players[1].playerAddress == address(0)); // requires player 2 to be the sender of this function, or being 0. meaning p1 did not select an enemy and anyone can be p2.
      require(battle.active == false); // requires this battle's status to be non active. 

      if(battle.players[1].playerAddress != msg.sender) { // if not yet set. set player 2 to be equal to msg sender
        battle.players[1].playerAddress = msg.sender;
      }

      require(msg.value == battle.stakePerPlayer); // required the value of the message to be the same as the initial sender
      require(battle.players[0].pepes.length == _pepes.length); // same amount of pepes in battle

      battle.players[1].randomHash = _randomHash; // saves players 2 initial random hash.

      for(uint256 i = 0; i < _pepes.length; i ++) { // adds p2 pepes to battle
          battle.players[1].pepes.push(BattlePep(_pepes[i], 30));
      }

      battle.active = true; // sets battle active so its not to be joined again
     

      emit BattleStarted(_battle, battle.players[0].playerAddress, msg.sender, msg.value); // emit above on chain
  }

  event NewBattle(uint256 ID, address indexed playerOne, address indexed playerTwo, uint256[] pepes, uint256 stake);
  event BattleStarted(uint256 ID, address indexed playerOne, address indexed playerTwo, uint256 stake);
  event PayOutFail(address indexed winner, uint256 stake);


  constructor() public payable {
    // constructor
  }

  function returnRandomHash (uint256 _battle) public view returns(bytes32){
      Battle storage battle = battles[_battle];
      uint player = getPlayerOneOrTwo(_battle, msg.sender);
      bytes32 randomHash = battle.players[player].randomHash;
      return randomHash;
  }

    function continueGame(uint256 _battle, uint256 _seq, uint8 _move, bytes32 _hash) public { // renamed from 'move' to 'continueGame' to clarify its about the game state and nothing to do with pepe moves.
      Battle storage battle = battles[_battle];
      require(battle.active);
      require(_seq >= battle.seq);
      require(_seq % 2 == getPlayerOneOrTwo(_battle, msg.sender)); // requires that the game seq modules 2 (4 % 2 = 0.... 5 % 2 = 1) 
// to either be 0 or 1, so player 1 turn or player 2 turn,  then check if sender is player 1 or 2.  if sender of message is valid for turn.....
// this is unfair however because this always makes player 2 the one to pay for reveal move and doTurn. 
// i suggest a require boolean to check if a player already did submit move / revealed move. dont go into function. 
// reset boolean at doTurn.

//not using seq for checking wich player turns is easier for frontend aswell. 

      if(_seq % 4 < 2) { // we start at 0. so
        /* 
        0.S % 4 = 0 = sub,
        1.S % 4 = 1 = sub
        2.R % 4 = 2 = reveal
        3.R % 4 = 3 = reveal
        4.S % 4 = 0 = sub
        5.S % 4 = 1 = sub 
        6.R % 4 = 2 = reveal
        7.R % 4 = 3 = reveal
        */
    
        submitMove(_battle, _hash); // !!!!!!!! the _move parameter is always needed to call this function.
        //!!!!!! however in the submit move seq there is no _move to submit just the encoded hash!

        //!! its confusing that the submitMove _hash is a randomhash + move re-encrypted into a "movehash" combo while ...
      }
      else{
          // !! ... here the _hash is the original randomhash.. and _move the original number move. to be compared later to be equal to "movehash" while re-encrypted. 
        revealMove(_battle, _move, _hash); 
        // !! TL;DR. the parameter _hash might contrain 2 entirely diffrent things. 
      }

      battle.seq = _seq; // increase seq / turns. proceed to next move.

  }

  function submitMove(uint256 _battle, bytes32 _moveHash) internal {
      Battle storage battle = battles[_battle]; // use battle id to specify game
      uint8 player = getPlayerOneOrTwo(_battle, msg.sender); //finds out of sender of this message is either p1 or p2
      battle.players[player].moveHash = _moveHash; // puts the hash on chain that has encrypted data of chosen move. player makes this on client side. randomhash + chosen move
  }


  function revealMove(uint256 _battle, uint8 _move, bytes32 _hash) internal { //???? why are we calling it _hash and not _randomHash as its always a randomhash? 
      Battle storage battle = battles[_battle]; // specify game
      uint8 player = getPlayerOneOrTwo(_battle, msg.sender); // find if sender is p1 or p2
      bytes32 moveHash = keccak256(abi.encodePacked(_move, _hash));
      require(battle.players[player].randomHash == _hash); // require the players random hash *(initial random set hash on join) to be equal to the _hash parameter send now.
      require(battle.players[player].moveHash == moveHash); // requires player moveHash *(set in submit move above) to be equal to a chosen move + the random/initial hash.
      // this means that the chosen move uppon "reveal" has to be the same as the move on "submit" and therefore unchanged. or the hash outcome would not equal
      battle.players[player].move = _move; // save the checked and submitted move to be excuted.
      battle.players[player].randomHash = moveHash; // setting the randomHash to be the movehash. 
      battle.players[player].hasRevealed = true; // sets hasRevealed to true for player that reveals move. 
    /*   if(battle.seq % 4 == 0) { // check if current move in set is 4th, invalid as seq starts at 0. and also unfair for paying.
          doTurn(_battle);
      } */

      if (battle.players[getOpponent(player)].hasRevealed && battle.players[player].hasRevealed)
      {
          // if both players revealed. the last player that reveals has to pay for doTurn. 
          // currently this is always player 2 as its still based on continueGame function. See new idea.
          battle.players[player].hasRevealed = false;
          battle.players[getOpponent(player)].hasRevealed = false;
          doTurn(_battle);
      }
  }

  function doTurn(uint256 _battle) internal {
      Battle storage battle = battles[_battle]; // locate battle

      uint8 playerFirst = uint8(battle.seq % 2); // this function has no use as its always the same result because turn based on continueGame function,
      uint8 playerSecond = uint8((battle.seq + 1) % 2); // player 2 will always have to pay for doTurn and battle.seq % 2 will always be 1(player 2) 
// seq = 3. % 

// we want this function to be paid by the slowest player. last revealing. see above. We want the move's to excute on pepe speed order. incase of a draw. player last revealed goes second.
// pepe switch should always go before any normal moves.
// ?? how are we going to calculate stats of pepe. 
      doMove(_battle, playerFirst);//sends 0
      doMove(_battle, playerSecond);// sends 1. 
  }

  function doMove(uint256 _battle, uint8 _player) internal {
      Battle storage battle = battles[_battle]; // locate battle
      uint8 move = battle.players[_player].move; // get move from player
      uint8 oponent; // init oponent int.
      if(_player == 0){
        oponent = 1; // set oponent to be oppersite of player
      }
      else {
        oponent = 0;
      }

      if(move > 9){ //if the player is switching pepe he has to use a move above 10, 10 being the lowest and selecting pepe 0. 
      // maybe find a better way to deal with this so that the game moves can eventually get extended. 
      // pepe switch should always go before any normal moves.. 
          uint8 pepeSelected = move - 10;
          if(pepeSelected > battle.players[_player].pepes.length || battle.players[_player].pepes[pepeSelected].health == 0) {
            handleLoss(_battle, _player);//player tried to select non existent or dead pepe he dies. got to have this secured in GUI
          }
          else{ //everything ok select other pepe
            battle.players[_player].selectedPepe = pepeSelected;
          }
      }
      else if(move == 0){
          // do nothing. for when you lose your turn on pepe die.
      }
      else { //normal move
          uint256 oponentPepe = battle.players[oponent].selectedPepe; // set oponentPepe from his selected pepe. ? renamed for easyer understanding ?
          uint256 oponentPepeHealth = battle.players[oponent].pepes[oponentPepe].health; // load health in var

          uint256 damage = 10 + uint256(battle.players[oponent].randomHash) % 10; // calculate damage to be between 10 and 19 based on hash. this gets more advanced later.

          if(damage > oponentPepeHealth) { //if oponent pepe dies with this blow
              battle.players[oponent].pepes[oponentPepe].health = 0; // sets health to 0 instead of negative. 
              autoSwitchPepe(_battle, oponent); // tries to switch pepe to new one. 
              battle.players[oponent].move = 0;// if your oponent's pepe dies. they lose their turn to do a move. 
          }
          else { //else deduct damage from health
              battle.players[oponent].pepes[oponentPepe].health -= damage; // substract damage from health
              
              // emit some event or web3 has to "fetch" the new health? //yes we need that
              // external view function to get current battle state and pepe's health? //yes we need that
          }
      }

  }

  function handleLoss(uint256 _battle, uint256 _loser) internal {
      Battle storage battle = battles[_battle];//battle loc
      uint256 winner; // init winner int
      battle.active = false;
      if(_loser == 1) { // gets losing player from parameter. checks if either player 1(0) or 2(1) and set winner
          winner = 0; 
      }
      else {
          winner = 1;
      }
      battle.winner = battle.players[winner].playerAddress;
      if(!battle.winner.send(battle.stakePerPlayer * 2)) { // send stakes of both players in value to the winners playerAddress, 
        // failed / untrue, do nothing?
        emit PayOutFail(battle.winner, battle.stakePerPlayer * 2);
      }
  }

  function getWinner(uint256 _battle) public view returns(address winner){
      Battle storage battle = battles[_battle];
      return battle.winner;
  }

  function autoSwitchPepe(uint256 _battle, uint256 _player) internal {
      Battle storage battle = battles[_battle]; // battle loc
      for(uint256 i = 0; i < battle.players[_player].pepes.length; i ++) { //for all the pepes from this player
          if(battle.players[_player].pepes[i].health > 0) { // check if current-loop pepe is alive
             battle.players[_player].selectedPepe = uint8(i); // if alive, selected pepe int = current pepe.
             return; // returns / exits function if new pepe is selected.
          } // if not a new pepe is selected and no return is made
      }
      handleLoss(_battle, _player); // then handle loss for current player
  }

  function getOpponent(uint8 _player) internal pure returns(uint8 oponent)  {
      if(_player == 0){ // gets the opponent from the player number send in.
        oponent = 1;
      }
      else {
        oponent = 0;
      }
  }

  function getPlayerOneOrTwo(uint256 _battle, address _player) view public returns(uint8) {
      Battle storage battle = battles[_battle];

      if(battle.players[0].playerAddress == _player) { // checks if player 1 or 2's adress is equal to the msg.sender thats in the parameter. if so return if 1 or 2
        return 0;
      }
      else if(battle.players[1].playerAddress == _player) { 
        return 1;
      }
      else { // if the msg.sender is not equal to either p1 or p2 revert.
        revert();
      }
  }



/* Example of data coming in:.Battle;017.Seq;240.Peps;1234123412341234.Spep;0102.rhash;0x123450x12345.Smoves;0x1230x321.Rmoves;0503
. to indicate a new parameter. 
; to indicate data coming from it.
Currently data is not seperated so must be fixed sized (000-999 for battles. 0000 - 9999 for pepeshealth, 32 for hashes ec.)
First prototype will have fixed size states starting at fixed indexes.
Second step is to seperate by string search. 
Final step is to seperate state data to allow for dynamic amounts of pepe,  */


  function continueGameFromState(string fullState,  bytes32 _playerStateHashed, bytes _opponentStateHashed, bytes32 _randOrMoveHash, uint8 _move ) public { // not sure if correct useage of underscore
    uint battleid = parseInt(substring(fullState,7,10),3);// see data exmp above. read from 7 to 10 to get battleid
    Battle storage battle = battles[battleid]; 
       
   // require(recoverSigner(_playerStateHashed, _opponentStateHashed) == battle.players[getOpponent(getPlayerOneOrTwo(battleid, msg.sender))].playerAddress);
    //client side hash the full state. (contract adds, healths....ect) and called it '_playerStateHashed' AKA message, 
    //use the opponent's version '_opponentStateHashed' AKA signature. should return the adress of opponent and if so. both parties agreed on state.

    require(battle.seq < parseInt(substring(fullState,15,18),3));
    battle.seq = parseInt(substring(fullState,15,18),3) + 1;


    Player storage playerOne = battle.players[0];
    Player storage playerTwo = battle.players[1];

    playerOne.pepes[0].health = parseInt(substring(fullState,24,28),4);
    playerOne.pepes[1].health = parseInt(substring(fullState,28,32),4);
    playerTwo.pepes[0].health = parseInt(substring(fullState,32,36),4);
    playerTwo.pepes[1].health = parseInt(substring(fullState,36,40),4);

    
    playerOne.selectedPepe = uint8(parseInt(substring(fullState,46,48),2));
    playerTwo.selectedPepe = uint8(parseInt(substring(fullState,48,50),2));

    playerOne.randomHash = bytes32(stringToBytes32(substring(fullState,57,123)));
    playerTwo.randomHash = bytes32(parseInt(substring(fullState,123,189),66));

    playerOne.moveHash = bytes32(parseInt(substring(fullState,197,263),66)); 
    playerTwo.moveHash = bytes32(parseInt(substring(fullState,263,329),66));

    playerOne.move = uint8(parseInt(substring(fullState,337,339),2));
    playerTwo.move = uint8(parseInt(substring(fullState,339,341),2)); 

   // continueGame(battleid, battle.seq, _move, _randOrMoveHash );(battleid, battle.seq, _move, _randOrMoveHash ); // using newly saved battle and seq and using send hash/move to continue.
  }  

  //  function importState1(uint8 _battleid, uint8 _seq, uint256 _p1p)

function importState(bytes _state, uint8 battleid /* bytes _opponentSignature */) public 
  returns(
    uint8 _seq,  
     uint256 _p1p1h, 
    uint256 _p1p2h, 
    uint256 _p2p1h, 
    uint256 _p2p2h,
     uint8 _p1selp,
    uint8 _p2selp,
    bytes32 _p1randhash,
    bytes32 _p2randhash,
    bytes32 _p1movehash,
    bytes32 _p2movehash,
    uint8 _p1move,
    uint8 _p2move  ) {

      //   require(recoverSigner(_state, _opponentSignature) == battle.players[getOpponent(getPlayerOneOrTwo(battleid, msg.sender))].playerAddress);
    
    assembly {
      _seq := mload(add(_state, 32))
       _p1p1h := mload(add(_state, 64))
      _p1p2h := mload(add(_state, 96))
      _p2p1h := mload(add(_state, 128))
      _p2p2h := mload(add(_state, 160)) 
    }
    setState(battleid,_seq, _p1p1h,_p1p2h,_p2p1h,_p2p2h);

    assembly {
      _p1selp := mload(add(_state, 192))
       _p2selp := mload(add(_state, 224))
      _p1randhash := mload(add(_state, 256))
      _p2randhash := mload(add(_state, 288))
    }
    setState2(battleid,_p1selp, _p2selp,_p1randhash,_p2randhash);

    assembly {
      _p1movehash := mload(add(_state, 320))
       _p2movehash := mload(add(_state, 352))
      _p1move := mload(add(_state, 384))
      _p2move := mload(add(_state, 416))
    }
    setState3(battleid,_p1movehash, _p2movehash,_p1move,_p2move);

    // continueGame(battleid, _seq, _move, _randOrMoveHash );(battleid, battle.seq, _move, _randOrMoveHash ); // using newly saved battle and seq and using send hash/move to continue.
}

function setState(
    uint8 _battleid, 
    uint8 _seq ,
     uint256 _p1p1h,
    uint256 _p1p2h,
    uint256 _p2p1h, 
    uint256 _p2p2h
     ) internal {

        uint battleid = _battleid;
        Battle storage battle = battles[battleid];
        require(battle.seq < _seq);
        battle.seq = _seq +1;
        Player storage playerOne = battle.players[0];
        Player storage playerTwo = battle.players[1];
         playerOne.pepes[0].health = _p1p1h;
        playerOne.pepes[1].health = _p1p2h;
        playerTwo.pepes[0].health = _p2p1h;
        playerTwo.pepes[1].health = _p2p2h; 

}
function setState2(
    uint8 _battleid, 
      uint8 _p1selp,
    uint8 _p2selp,
    bytes32 _p1randhash,
    bytes32 _p2randhash
     ) internal {

        uint battleid = _battleid;
        Battle storage battle = battles[battleid];
        Player storage playerOne = battle.players[0];
        Player storage playerTwo = battle.players[1];

        playerOne.selectedPepe = _p1selp;
        playerTwo.selectedPepe = _p2selp;

        playerOne.randomHash =_p1randhash;
        playerTwo.randomHash =_p2randhash;
}

function setState3(
    uint8 _battleid, 
      bytes32 _p1movehash,
    bytes32 _p2movehash,
    uint8 _p1move,
    uint8 _p2move  
     ) internal {

        uint battleid = _battleid;
        Battle storage battle = battles[battleid];
        Player storage playerOne = battle.players[0];
        Player storage playerTwo = battle.players[1];

        playerOne.moveHash =  _p1movehash;
        playerTwo.moveHash =  _p2movehash;

        playerOne.move = _p1move;
        playerTwo.move =  _p2move; 
}


////state restore string helpers.
    function substring(string str, uint startIndex, uint endIndex) internal pure returns (string) {
        bytes memory strBytes = bytes(str);
        bytes memory result = new bytes(endIndex-startIndex);
        for(uint i = startIndex; i < endIndex; i++) {
            result[i-startIndex] = strBytes[i];
        }
        return string(result);
    }
    function parseInt(string _a, uint _b) internal pure returns (uint) {
        bytes memory bresult = bytes(_a);
        uint mint = 0;
        bool decimals = false;
        for (uint i = 0; i < bresult.length; i++) {
            if ((bresult[i] >= 48) && (bresult[i] <= 57)) {
              if (decimals) {
                if (_b == 0) break;
                else _b--;
            }
            mint *= 10;
            mint += uint(bresult[i]) - 48;
            } else if (bresult[i] == 46) decimals = true;
        }
        return mint;
    }
    function stringToBytes32(string memory source) returns (bytes32 result) {
    bytes memory tempEmptyStringTest = bytes(source);
    if (tempEmptyStringTest.length == 0) {
        return 0x0;
    }

    assembly {
        result := mload(add(source, 32))
    }
}
  
//// encrption things.
    function returnHashFromMoveAndHash(uint8 _move, bytes32 _hash) public pure returns (bytes32) {
     // can be removed later. used for truffle testing.
       return keccak256(abi.encodePacked(_move, _hash));
    }


  // Signature methods

   function splitSignature(bytes sig) // splits sig into vars
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

   function recoverSigner(bytes32 message, bytes sig) // calls split sig and then calls ecrecover to check and return if matched / legit signature/move 
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
