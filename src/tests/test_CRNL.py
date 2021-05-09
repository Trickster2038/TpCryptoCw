from brownie import accounts
from brownie import CRNL
from brownie import reverts
from brownie import chain
import pytest

@pytest.fixture(scope="function", autouse=True)
def deploy_fixture(fn_isolation):
    CRNL.deploy(100,100,100,10,10,15,chain.time(), 86400, 86400, 84000, {'from':accounts[0]})

def test_default_usage():
    t = CRNL[0]
    chain.sleep(1) 
    t.commit(34800169113441137656655510613550640410253994535886922253593317958438436228110, \
        {'from':accounts[1], 'value': 221}) # 5, 654
    t.commit(84237577606170373470970710271612687310126724891082767247421816067059279455482, \
        {'from':accounts[2], 'value': 220}) # 15, 777
    t.commit(65256417849135098107207539788601443641021523921824715219531979081585702641459, \
        {'from':accounts[3], 'value': 220}) # 10, 666  
    chain.sleep(86401) 
    t.reveal(5,654,{'from':accounts[1]})
    t.reveal(15,777,{'from':accounts[2]})
    t.reveal(10,666,{'from':accounts[3]})
    chain.sleep(86401) 
    t.countRewards({'from':accounts[1]})
    t.takeReward({'from':accounts[3]})
    assert True

    