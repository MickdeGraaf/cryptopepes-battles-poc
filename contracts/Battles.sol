pragma solidity ^0.4.4;


contract Battles {

    struct BattlePep {
        uint256 id;
        uint256 health;
    }

    struct Player {
        address playerAddress;
        BattlePep[] pepes;
        uint8 selectedPepe;
        bool submited;
        bool revealed;
        bytes32 moveHash;
        uint8 move;
        bytes32 randomHash;
    }

    Battle[] public battles;
    uint256 battleCounter;
    Battle[] public pendingBattles;
    uint256 pendingBattleCounter;

    struct Battle {
        Player[] players;
        uint256 stakePerPlayer;
        address lastPlayerMoved;
        uint256 turnCounter;
    }

    event NewBattle(uint256 ID, address indexed playerOne, address indexed playerTwo, uint256[] pepes, uint256 stake);
    event BattleStarted(uint256 ID, address indexed playerOne, address indexed playerTwo, uint256 stake);

    function newBattle(uint256[] _pepes, bytes32 _randomHash, address _oponent) payable public {
        Battle storage battle = pendingBattles[pendingBattleCounter];
        pendingBattleCounter += 1;

        battle.players[0].playerAddress = msg.sender;
        battle.players[1].playerAddress = _oponent;
        battle.players[0].randomHash = _randomHash;

        for(uint256 i = 0; i < _pepes.length; i ++) {
            battle.players[0].pepes.push(BattlePep(_pepes[i], 10000));
        }

        battle.stakePerPlayer = msg.value;

        emit NewBattle(pendingBattleCounter - 1, msg.sender, _oponent, _pepes, msg.value);
    }

    function joinBattle(uint256 _battle, uint256[] _pepes, bytes32 _randomHash) payable public {
        require(battle.players[1].playerAddress == msg.sender || battle.players[1].playerAddress == address(0));

        Battle storage battle = pendingBattles[_battle];

        if(battle.players[1].playerAddress != msg.sender) {
          battle.players[1].playerAddress = msg.sender;
        }

        require(msg.value == battle.stakePerPlayer);
        require(battle.players[0].pepes.length == _pepes.length);

        battle.players[1].randomHash = _randomHash;

        for(uint256 i = 0; i < _pepes.length; i ++) {
            battle.players[1].pepes.push(BattlePep(_pepes[i], 10000));
        }

        battles[battleCounter] = battle;
        battleCounter += 1;

        delete(pendingBattles[_battle]);

        emit BattleStarted(battleCounter - 1, battle.players[0].playerAddress, msg.sender, msg.value);
        delete(pendingBattles[_battle]);
    }

    function submitMove(uint256 _battle, bytes32 _moveHash) public {
        Battle storage battle = battles[_battle];
        uint8 player = getPlayerOneOrTwo(_battle, msg.sender);

        require(battle.players[player].submited == false);
        battle.players[player].moveHash = _moveHash;
        battle.players[player].submited = true;
    }

    function revealMove(uint256 _battle, uint8 _move, bytes32 _nextHash) public {
        Battle storage battle = battles[_battle];
        uint8 player = getPlayerOneOrTwo(_battle, msg.sender);

        require(battle.players[player].randomHash == keccak256(_nextHash)); //check if new hash is correct
        require(battle.players[player].submited == true);
        require(battle.players[player].moveHash == keccak256(_move, _nextHash));
        battle.players[player].move = _move;
        battle.players[player].randomHash = _nextHash;
        battle.players[player].revealed = true;
    }

    function doTurn(uint256 _battle) public {
        Battle storage battle = battles[_battle];
        require(battle.players[0].revealed == true);
        require(battle.players[1].revealed == true); //both players need to have revealed previously

        uint8 playerFirst = uint8(battle.turnCounter % 2);
        uint8 playerSeccond = uint8((battle.turnCounter + 1) % 2);

        doMove(_battle, playerFirst);
        doMove(_battle, playerSeccond);

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

            uint256 damage = 10 + 10 % uint256(battle.players[oponent].randomHash);

            if(damage > oponentPepeHealth) { //if oponent pepe dies with this blow
                battle.players[oponent].pepes[selectedPepe].health = 0;
                autoSwitchPepe(_battle, oponent);
            }
            else { //else deduct damage from health
                battle.players[oponent].pepes[selectedPepe].health -= damage;
            }
        }

    }

    function autoSwitchPepe(uint256 _battle, uint256 _player) internal {
        Battle storage battle = battles[_battle];
        for(uint256 i = 0; i < battle.players[_player].pepes.length; i ++) {
            if(battle.players[_player].pepes[i].health > 0) {
               battle.players[_player].selectedPepe = uint8(i);
               return;
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
        }
    }

    function getPlayerOneOrTwo(uint256 _battle, address _player) view public returns(uint8) {
        Battle storage battle = battles[_battle];

        if(battle.players[0].playerAddress == _player) {
          return 0;
        }
        else if(battle.players[0].playerAddress == _player) {
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
