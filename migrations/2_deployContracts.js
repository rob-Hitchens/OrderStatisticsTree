/**
 * Deploy and link libraries and contracts
 */

const OrderStatisticsTreeLib = artifacts.require("HitchensOrderStatisticsTreeLib");
const OrderStatisticsTree = artifacts.require("HitchensOrderStatisticsTree");

module.exports = async function (deployer) {    
    await deployer.deploy(OrderStatisticsTreeLib);
    await deployer.link(OrderStatisticsTreeLib, OrderStatisticsTree);
    await deployer.deploy(OrderStatisticsTree);
}
