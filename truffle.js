
var HDWalletProvider = require("truffle-hdwallet-provider");
var mnemonic = "tongue kick couple practice clever bottom cool dial elder potato special rebel";
module.exports = {
  networks: {
    development: {
      host: "127.0.0.1",
      port: 7545,
      network_id: "*"
    },
    rinkeby: {
      provider: function(){
        return new HDWalletProvider(mnemonic, "https://rinkeby.infura.io/vedYi6i5AgNcF1GwzZap")
      },
      network_id: "*"
    }
  }
};
