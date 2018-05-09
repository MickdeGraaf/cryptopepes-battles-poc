pragma solidity ^0.4.4;


contract Battles {

    struct BattlePep {
        uint256 id;
        uint256 health;
    }

    Battle[] public battles;
    uint256 battleCounter;
    Battle[] public pendingBattles;
    uint256 pendingBattleCounter;

    struct Battle {
        address playerOne;
        address playerTwo;
        BattlePep[] playerOnePepes;
        BattlePep[] playerTwoPepes;
        uint256 stakePerPlayer;
        address lastPlayerMoved;
        uint256 lastMoveTime;
        bytes32 playerOneHash;
        bytes32 playerTwoHash;
    }

    event NewBattle(uint256 ID, address indexed playerOne, address indexed playerTwo, uint256[] pepes, uint256 stake);
    event BattleStarted(uint256 ID, address indexed playerOne, address indexed playerTwo, uint256 stake);

    function newBattle(uint256[] _pepes, bytes32 _randomHash, address _oponent) payable public {
        Battle storage battle = pendingBattles[pendingBattleCounter];
        pendingBattleCounter += 1;

        battle.playerOne = msg.sender;
        battle.playerTwo = _oponent;
        battle.playerOneHash = _randomHash;

        for(uint256 i = 0; i < _pepes.length; i ++) {
            battle.playerOnePepes.push(BattlePep(_pepes[i], 10000));
        }

        battle.stakePerPlayer = msg.value;

        emit NewBattle(pendingBattleCounter - 1, msg.sender, _oponent, _pepes, msg.value);
    }

    function joinBattle(uint256 _battleID, uint256[] _pepes, bytes32 _randomHash) payable public {
        require(pendingBattles[_battleID].playerTwo == msg.sender || pendingBattles[_battleID].playerTwo == address(0));

        Battle storage battle = pendingBattles[_battleID];

        if(battle.playerTwo != msg.sender) {
          battle.playerTwo = msg.sender;
        }

        require(msg.value == battle.stakePerPlayer);
        require(battle.playerOnePepes.length == _pepes.length);

        battle.playerTwoHash = _randomHash;

        for(uint256 i = 0; i < _pepes.length; i ++) {
            battle.playerTwoPepes.push(BattlePep(_pepes[i], 10000));
        }

        battles[battleCounter] = battle;
        battleCounter += 1;

        delete(pendingBattles[_battleID]);

        emit BattleStarted(battleCounter - 1, battle.playerOne, msg.sender, msg.value);
        delete(pendingBattles[_battleID]);
    }

    constructor() public {
        // constructor
    }
}
