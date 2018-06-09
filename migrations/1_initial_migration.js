var Migrations = artifacts.require("./Migrations.sol");
//var Battles = artifacts.require("./Battles");
var Battles = artifacts.require("./BattlesState.sol");

module.exports = function(deployer) {
  deployer.deploy(Migrations);
  deployer.deploy(Battles);
};
