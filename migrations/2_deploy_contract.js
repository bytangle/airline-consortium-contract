const Airlines = artifacts.require("Airlines");

module.exports = (deployer, accounts) => {
    console.log(accounts);
    if(accounts) {
        deployer.deploy(Airlines, {value : "200000"});
    }
}