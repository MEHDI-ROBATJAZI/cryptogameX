var CardBase = artifacts.require("CardBase");

module.exports = function(deployer) {
  // deployment steps
  deployer.deploy(CardBase);
};