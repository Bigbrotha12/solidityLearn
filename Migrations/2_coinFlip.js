const coinFlip = artifacts.require("coinFlip");

module.exports = function(deployer) {
  deployer.deploy(coinFlip);
};
