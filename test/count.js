//const BigNumber = require('big-number');
const OrderStatisticsTree = artifacts.require("HitchensOrderStatisticsTree.sol");
const fs = require('fs');
const scenario1 = 'test/steps_1.json';
const scenario2 = 'test/steps_2.json';
const scenario3 = 'test/steps_3.json';
const showProgress = false; // show steps as the test proceeds
const verbose = false; // output tree state after each step - takes a long time

contract("OrderStatisticsTree - count", accounts => {

    beforeEach(async () => {;
        ost = await OrderStatisticsTree.new();
    });

    it("should be ready to test", async () => {
        assert.strictEqual(true, true, "something is wrong");
    });

    it("should maintain a correct count at all times - steps_1", async () => {
        await testScenario(scenario1);
    });

    it("should maintain a correct count at all times - steps_2", async () => {
        await testScenario(scenario2);
    });

    it("should maintain a correct count at all times - steps_3", async () => {
        await testScenario(scenario3);
    });
});

async function testScenario(testFile) {
    let i;
    let step;
    let isDelete;
    let readableAction;
    let count = 0;
    let treeCount;
    let sorted = [];
    let before;
    let element;
    let rank;
    let percentile; 
    let steps = await loadSteps(testFile);   
    
    if(showProgress) console.log();
    if(showProgress) console.log("Scenario:", testFile);
    if(showProgress) console.log("Number of steps: "+steps.length);  
    if(showProgress) console.log("Steps:");

    for (i=0; i<steps.length; i++) { 
        if(showProgress) cconsole.log("Step:", i, steps[i]["amount"]); 
    }
    if(showProgress) cconsole.log("Step, action, value, expected count, reported count");

    for(i=0; i < steps.length; i++) {
        isDelete = steps[i]["amount"] < 0;
        if(isDelete) {
            readableAction = "delete";
            count--;
        } else {
            readableAction = "insert";
            count++;
        }
        before = sorted;
        sorted = await applyStep(sorted, i);
        treeCount = await ost.valueKeyCount();
        if(verbose) console.log("step", i, readableAction, "value:", steps[i]["amount"], count, treeCount.toString(10));
        if(verbose) await printTreeStucture(sorted); 
        assert.equal(treeCount.toString(10), count, "The count does not match the expected count.");
    }
    return;
}

async function printTreeStucture(s) {
    let i;
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
    return;
}

async function applyStep(sorted, step) {
    let account;
    let element;
    let removeIndex;

    if(showProgress) console.log();
    if(showProgress) console.log("APPLY STEP", step, '***********************************************************');

    element = steps[step]["amount"];
    account = steps[step]["address"];

    if (element > 0) {
        if(showProgress) console.log("INSERT:", account, element);
        sorted.push(element);
        await ost.insertKeyValue(account, element);
    } else {
        if(showProgress) console.log("DELETE:", account, element);
        removeIndex = sorted.indexOf(element*-1);
        sorted.splice(removeIndex,1);
        await ost.removeKeyValue(account, element*-1);
    }
    sorted.sort(numeric);
    return sorted;
}

async function loadSteps(scenario) {
    let rawdata = fs.readFileSync(scenario);
    steps = JSON.parse(rawdata);
    return steps
}

function numeric(a, b) {
    return a - b;
}