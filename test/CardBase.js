var CardBase = artifacts.require("CardBase");

contract('CardBase', function(accounts) {
    it("Should generate a new card", function() {
      // Get initial balances of first and second account.
      var account_one = accounts[0];
      var instance;

      return CardBase.deployed()
      .then(_instance => {
        instance = _instance;

        return instance.createNewCard.call()
      })
      .then(a => {
        console.log(a);
        console.log("Im taking random dna");
        console.log(instance.cards);
        return instance.getCard.call(0);
      })
      .then(a => {
        console.log(a);
      })
      .catch(b => {
        console.log(b);
      })
    });
});
