pragma solidity ^0.4.4;


contract Battles {

    struct BattlePep {
        uint256 id;
        uint256 health;
    }

    struct Player {
        address playerAddress;
        BattlePep[] pepes;
        bool submited;
        bool revealed;
        bytes32 moveHash;
        uint8 move;
        uint8 selectedPepe;
        bytes32 randomHash;
    }

    mapping (uint256 => Battle) public battles;
    uint256 battleCounter;

    struct Battle {
        Player[] players;
        uint256 stakePerPlayer;
        address lastPlayerMoved;
        uint256 turnCounter;
        bool active;
    }

    event NewBattle(uint256 ID, address indexed playerOne, address indexed playerTwo, uint256[] pepes, uint256 stake);
    event BattleStarted(uint256 ID, address indexed playerOne, address indexed playerTwo, uint256 stake);

    ///// hoe stuur je _pepes mee? voor onze test. en uiteindelijk ? dit wordt een contact op onze parity chain. dus dan zou je web3.send (contr addrs) (pepe token?)

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

    function submitMove(uint256 _battle, bytes32 _moveHash) public {
      // make something to check if move is already submitted ?
        Battle storage battle = battles[_battle];
        uint8 player = getPlayerOneOrTwo(_battle, msg.sender);

        require(battle.players[player].submited == false);
        battle.players[player].moveHash = _moveHash; // movehash is a int? or a hash? @revealMove we got another _move?
        battle.players[player].submited = true;
    }

    function revealMove(uint256 _battle, uint8 _move, bytes32 _nextHash) public {
      //
        Battle storage battle = battles[_battle];
        uint8 player = getPlayerOneOrTwo(_battle, msg.sender);

        require(battle.players[player].randomHash == keccak256(_nextHash)); //check if new hash is correct  // what is _nextHash? where do we get this. why would it be equal to randomHash?
        require(battle.players[player].submited == true);
        require(battle.players[player].moveHash == keccak256(_move, _nextHash)); // moveHash from submit move should be equal to the _move with _nextHash? so we submit move twice?
        battle.players[player].move = _move;
        battle.players[player].randomHash = _nextHash; //does this needs to be returned to the player?
        battle.players[player].revealed = true; // should we not make a check if both revealed and call doTurn automaticly?
    }

    function doTurn(uint256 _battle) public { //who calls doTurn and revealMove?
        Battle storage battle = battles[_battle];
        require(battle.players[0].revealed == true);
        require(battle.players[1].revealed == true); //both players need to have revealed previously

        uint8 playerFirst = uint8(battle.turnCounter % 2);
        uint8 playerSecond = uint8((battle.turnCounter + 1) % 2); // second is with one C

        doMove(_battle, playerFirst);
        doMove(_battle, playerSecond);

        battle.players[0].revealed = false;
        battle.players[0].submited = false;
        battle.players[1].revealed = false;
        battle.players[1].submited = false;

        battle.turnCounter ++;
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
                battle.players[oponent].pepes[selectedPepe].health -= damage; // emit some event or web3 has to "fetch" the new health?
                // external view function to get current battle state and pepe's health? 
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

    constructor() public {
        // constructor
    }
}
