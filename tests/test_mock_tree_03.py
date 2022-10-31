import pytest
import logging
from brownie import chain, Wei, reverts
LOGGER = logging.getLogger(__name__)
from web3 import Web3

PRICES_0 = [10000,11111,22222, 33333, 44444]
PRICES_1 = [10, 100, 110, 200, 300]
KEYS_0 = [
    0x0000000000000000000000000000000000000000000000000000000000000001,
    0x0000000000000000000000000000000000000000000000000000000000000002,
    0x0000000000000000000000000000000000000000000000000000000000000003,
    0x0000000000000000000000000000000000000000000000000000000000000004,
    0x0000000000000000000000000000000000000000000000000000000000000005,
    0x0000000000000000000000000000000000000000000000000000000000000006,
    0x0000000000000000000000000000000000000000000000000000000000000007,
    0x0000000000000000000000000000000000000000000000000000000000000008,
    0x0000000000000000000000000000000000000000000000000000000000000009,
    0x000000000000000000000000000000000000000000000000000000000000000a,
    0x000000000000000000000000000000000000000000000000000000000000000b,
    0x000000000000000000000000000000000000000000000000000000000000000c,
    0x000000000000000000000000000000000000000000000000000000000000000d,
]


def test_feed_one_price(accounts, treeMock):
    for x in KEYS_0:
        treeMock.insertKeyValue(x, PRICES_0[4], {"from": accounts[0]})
        logging.info('Tree root: {}'.format(treeMock.treeRootNode()))
        logging.info(
        'Node({}):parent = {}, left = {}, right = {}, isRed = {}, keyCount = {}, count = {}'.format(
            PRICES_0[4],
            treeMock.getNode2(PRICES_0[4])[0],
            treeMock.getNode2(PRICES_0[4])[1],
            treeMock.getNode2(PRICES_0[4])[2],
            treeMock.getNode2(PRICES_0[4])[3],
            treeMock.getNode2(PRICES_0[4])[4],
            treeMock.getNode2(PRICES_0[4])[5],
        ))
        logging.info('Median after same price insert:{}'.format(treeMock.medianValue()))
        logging.info('median Rank from {} values:{}'.format(treeMock.getNode2(PRICES_0[4])[4],treeMock.mock1(50)))
    
    x = 1
    logging.info('Next  value:, value at rank({}):{}, keys count {}'.format(
            x,
            treeMock.valueAtRank(x),
            treeMock.getNodeKeysCount( treeMock.valueAtRank(x))
    ))
    #logging.info('Median after same price insert:{}'.format(treeMock.medianValue()))
    # feed_count = treeMock.valueKeyCount()
    # assert  feed_count == 11
    # logging.info('Median after same price insert:{}'.format(treeMock.medianValue()))
    # list_from_tree = []
    # list_from_tree.append(treeMock.firstValue())
    # #logging.info('First value:{}'.format(list_from_tree[0]))
    # for x in range(feed_count):
    #     #st_from_tree.append(treeMock.nextValue(list_from_tree[x]))
    #     logging.info('Next  value:, value at rank({}):{}, keys count {}'.format(
    #         #list_from_tree[x],
    #         #treeMock.valueRank(list_from_tree[x]),
    #         x+1,
    #         treeMock.valueAtRank(x+1),
    #         treeMock.getNodeKeysCount( treeMock.valueAtRank(x+1))
    #     ))
    # logging.info('Price list from tree:{}'.format(list_from_tree))

