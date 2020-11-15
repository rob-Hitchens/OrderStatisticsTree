//const BigNumber = require('big-number');
const OrderStatisticsTree = artifacts.require("HitchensOrderStatisticsTree.sol");
const fs = require('fs');
let ost;
let scenarios = [];

contract("OrderStatisticsTree - sort and rank", accounts => {

    beforeEach(async () => {;
        // assert.isAtLeast(accounts.length, 20, "should have at least 20 unlocked, funded accounts");
        ost = await OrderStatisticsTree.new();
    });

    it("should be ready to test", async () => {
        assert.strictEqual(true, true, "something is wrong");
    });

    it("should process scenario 3", async () => {
        let element;
        let rank;
        let percentile; 
        let steps = await loadSteps();   
        console.log("Number of steps: "+steps.length);  
        let s = await loadScenario2(steps);
        await printScenario(s);
        await printExists(steps);
        await printComparisonsAt(s);
    });

});

async function loadSteps() {
    let rawdata = fs.readFileSync('test/steps_3.json');
    steps = JSON.parse(rawdata);
    return steps
}

async function printExists(s) {
    console.log();
    console.log("See if values exists");
    console.log("value, exists");
    for(i=0; i < s.length; i++) {
        element = s[i]["amount"];
        if (element > 0){
            exists = await ost.valueExists(element);
            console.log(element, exists);
        }       
    }
}

async function printComparisonsAt(s) {
    console.log();
    console.log("ValueAtRank");
    console.log("element, value at rank, value at rank reverse")
    for(i=1; i <= s.length; i++) {
        value = await ost.valueAtRank(i);
        valueR = await ost.valueAtRankReverse(i);
        console.log(i, value.toString(), valueR.toString()); 
    }
}

/*
async function printComparisons(s) {
    let first;
    let last;
    let rank;
    let rankReal;
    let percentile;
    let i;
    let element;

    // print stats for elements not in the set 
    last = await ost.lastValue();
    last = last.toString(10);
    console.log();
    console.log("Explore values not in the set");
    console.log("value, rank, rankReal, percentile, is above last value")
    for(i=start; i < stop; i += increment) {
        rank = await ost.valueRank(i);
        rankReal = await ost.valueAtRankReverse(i);
        percentile = await ost.valuePercentile(i);
        rank = rank.toString(10);
        percentile = percentile.toString(10);
        overMax = i > parseInt(last);
        console.log(i, rank, rankReal.toString(), percentile, overMax);
    }

}
*/

async function printScenario(s) {
    let count;
    let first;
    let last;
    let rootVal;
    let n;
    let node;
    let keyCount;
    let inside;

    // enumerate the sorted list and stats
    console.log("element, rank, rankReal, keycount")
    for(i=0; i < s.length; i++) {
        element = s[i];
        rank = await ost.valueRank(element);
        rank = rank.toString(10);
        rankReal = await ost.valueAtRankReverse(rank);
        rankReal = rankReal.toString(10);
       // percentile = await ost.valuePercentile(element);
       // percentile = percentile.toString(10);
        keyCount = await ost.valueKeyCount();
        inside = keyCount - (i - 1);
        console.log(element, rank, rankReal, keyCount.toString(10),inside.toString(10));
    }
    
    // tree structure summary
    console.log();
    console.log("Tree Properties");
    count = await ost.valueKeyCount();
    first = await ost.firstValue();
    last = await ost.lastValue();
    rootVal = await ost.treeRootNode();

    count = count.toString(10);
    first = first.toString(10);
    last = last.toString(10);
    rootVal = rootVal.toString(10);

    console.log("Count", count);
    console.log("First", first);
    console.log("Last", last);
    console.log("Root Value", rootVal);

    // enumerate the node contents
    console.log();
    console.log("Node Details, (crawled in order), value, parent, left, right, red, keyCount, count");

    n = first;
    while(parseInt(n) > 0) {
        node = await ost.getNode(n);
        console.log(
            n,
            node[0].toString(10), 
            node[1].toString(10),
            node[2].toString(10),
            node[3],
            node[4].toString(10),
            node[5].toString(10)
        )
        n = await ost.nextValue(n);
        n = n.toString(10);
    }
}

async function loadScenario(index, accounts) {
    const s = scenarios[0];
    let sorted = [];
    let account = accounts[0]; // we don't think we're concerned with unique users/keys (yet) so everything will be user 0
    let element;
    let removeIndex;

    // inserts
    for(i=0; i < s.ins.length; i++) {
        element = s.ins[i];
        sorted.push(element);
        await ost.insertKeyValue(account, element);
    }

    // deletes
    for(i=0; i < s.del.length; i++) {
        element = s.del[i];
        removeIndex = sorted.indexOf(element);
        sorted.splice(removeIndex, 1);
        await ost.removeKeyValue(account, element);
    }
    //sort it and return
    sorted.sort(numeric);
    return sorted;
}

async function loadScenario1(index, accounts) {
    let account = accounts[0];
    let element;
    let sorted = [];
    let removeIndex;

    for(i=0; i < scenario1.length; i++) {
        element = scenario1[i];
        account = accounts[accountMap[i]];
        if (element > 0) {
            sorted.push(element);
            console.log(account,element);
            await ost.insertKeyValue(account, element);
        } else {
            removeIndex = sorted.indexOf(element*-1);
            sorted.splice(removeIndex,1);
            console.log(account, element);
            await ost.removeKeyValue(account, element*-1);
        }
    }
    sorted.sort(numeric);
    return sorted;
}

async function loadScenario2(steps) {
    let account;
    let element;
    let sorted = [];
    let removeIndex;

    for(i=0; i < steps.length; i++) {
        element = steps[i]["amount"];
        account = steps[i]["address"];
        if (element > 0) {
            sorted.push(element);
            await ost.insertKeyValue(account, element);
        } else {
            removeIndex = sorted.indexOf(element*-1);
            sorted.splice(removeIndex,1);
            await ost.removeKeyValue(account, element*-1);
        }
    }
    sorted.sort(numeric);
    return sorted;
}

function numeric(a, b) {
    return a - b;
}