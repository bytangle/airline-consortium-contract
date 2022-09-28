const Airlines = artifacts.require("Airlines");

module.export = (deployer) => {
    deployer.deploy(Airlines);
}