var Migrations = artifacts.require("./Migrations.sol");
var Battles = artifacts.require("./Battles");

module.exports = function(deployer) {
  deployer.deploy(Migrations);
  deployer.deploy(Battles);
};
