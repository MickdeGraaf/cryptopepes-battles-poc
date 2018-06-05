pragma solidity ^0.4.23;

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
    event NewBattle(uint256 ID, address indexed playerOne,  uint256[] pepes, uint256 stake);
    event BattleStarted(uint256 ID, address indexed playerOne, address indexed playerTwo, uint256 stake);
    event test_value(uint256 indexed somevalue);
    event test_bytes(bytes somebytes);
    event test_singlebyte(byte singlebyte);


    function newBattle(uint256[] _pepes, bytes32 _randomHash) payable public {
        Battle storage battle = battles[battleCounter]; // creates new battle with ID of battleCounter
        battleCounter += 1; // increases for next battle to be higher

        battle.players.length = 2; // allows 2 players in array

        battle.players[0].playerAddress = msg.sender; // sets player 0 to be the sender of newBattle command
      //battle.players[1].playerAddress = _oponent; //????? why send opoment. not checking it at joinbattle
        battle.players[0].randomHash = _randomHash; // sets initial random hash. player creates this.

        for(uint256 i = 0; i < _pepes.length; i ++) { // adds default pepes based on _pepes parameter (for exmp 10)
          battle.players[0].pepes.push(BattlePep(_pepes[i], 10000));
        }

        battle.stakePerPlayer = msg.value; // sets ETH stake to be equal to the amount send with message

        emit NewBattle(battleCounter - 1, msg.sender,  _pepes, msg.value); // emits read-able event in chain listing the above
    }

  
///////////////stringmethod//////////////////////////////////////////////////////////////
    function continueGameFromStateString(string fullState) public {
        uint battleValueFromState = parseInt(substring(fullState,0,3),3);
        emit test_value(battleValueFromState);
    }
  
    function substring(string str, uint startIndex, uint endIndex) constant returns (string) {
        bytes memory strBytes = bytes(str);
        bytes memory result = new bytes(endIndex-startIndex);
        for(uint i = startIndex; i < endIndex; i++) {
            result[i-startIndex] = strBytes[i];
        }
        return string(result);
    }
    function parseInt(string _a, uint _b) internal returns (uint) {
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
  

//////////////////////////////////////////////////////////bytes method/////////////////  
    function continueGameFromState(bytes fullState) public {
        // require checks for state. blabla
        emit test_bytes(fullState);
        
        emit test_value(bytesToUint(fullState));
        
     //   uint8 numat1 = fullState[1];
     //   uint8 numat14;
      //  assembly {
    //        numat1 := byte(0, mload(add(fullState,32)))
  //          numat14 := byte(0, mload(add(fullState,46)))

//        }
      //  emit test_value(numat1);
      //  emit test_value(numat14);

       // Battle storage battle = battles[getBattleFromStateBytes(fullState)];
        //emit test_value(getBattleFromStateBytes(fullState));
        
  }
function bytesToUint (bytes b) constant returns (uint) {
    uint result = 0;
    for (uint i = 0; i < b.length; i++) {
        uint c = uint(b[i]);
        if (c >= 48 && c <= 57) {
            result = result * 16 + (c - 48);
        }
        if(c >= 65 && c<= 90) {
            result = result * 16 + (c - 55);
        }
        if(c >= 97 && c<= 122) {
            result = result * 16 + (c - 87);
        }
    }
    return result;
}

  
  function getBattleFromStateBytes(bytes fullState) internal pure returns (uint256) 
  {
      //make a require fullState to be of some length. 
      uint256 _battle; // ? should battle not be a int16, this might overkill.

      assembly {
          //bytes start after 32 because length prefix
        _battle := mload(add(fullState, 32))
          //first 3 bytes of the state, should allow for 999 game rooms for now. 
      }
    return _battle;
  }
  
}
