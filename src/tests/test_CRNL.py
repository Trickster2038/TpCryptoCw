from brownie import CRNL, liteCRNL, reverts, chain, history, accounts
import pytest

# deploys default contract
@pytest.fixture(scope="function", autouse=True)
def deploy_fixture(fn_isolation):
    CRNL.deploy(100, True, \
        100,100,10,10, \
        15, \
        chain.time(), 86400, 86400, 84000, {'from':accounts[0]})
    chain.sleep(1)

# checks if all functions work in normal conditions
def test_default_usage():
    t = CRNL[0]

    balance1 = accounts[1].balance()
    t.commit("0x1f48afeee3247a1506c5ee8602abcfdf1909c3c5142a6a20223577fee8161f60", \
        {'from':accounts[1], 'value': 225}) # random
    assert(balance1 - 220 == accounts[1].balance())

    t.changeCommitHash("0x4cf0329d3493fa458d54ff3008e9f4c69573b7720769671ef587a0082d184c0e", \
        {'from':accounts[1]}) # 5, 654
    t.commit("0xba3cc781c216dd7efa8a4295804186167660c8296119071ce2d45af33013e4fa", \
        {'from':accounts[2], 'value': 220}) # 15, 777
    t.commit("0x9045d2d894123dfb90a24453e03fdea3ab02099fb79a2eb93d31e0271c3a9f33", \
        {'from':accounts[3], 'value': 220}) # 10, 666  

    chain.sleep(86401) 
    balance2 = accounts[1].balance()
    t.reveal(5,654,{'from':accounts[1]})
    assert(balance2 + 100 == accounts[1].balance())

    t.reveal(15,777,{'from':accounts[2]})
    t.reveal(10,666,{'from':accounts[3]})

    chain.sleep(86401) 
    balance3 = accounts[3].balance()
    t.countRewards({'from':accounts[3]}) # 2/3 AVG = 6.67 => 6
    assert(balance3 + 10*3 + 100 == accounts[3].balance())

    balance4 = accounts[1].balance()
    t.takeReward({'from':accounts[1]}) # 5 is the closest to 6 
    assert(accounts[1].balance() > balance4)
    t.changeOwner(accounts[5], {'from':accounts[0]})

    balance5 = accounts[5].balance()
    t.rewardOwner({'from':accounts[6]})
    assert(balance5 + 10*3 == accounts[5].balance())
    chain.sleep(86401) 
    t.destruct({'from':accounts[7]})
    # assert True

# checks that destruct fees are recived by owner or destructor (depends on settings)
def test_destruct_fees():
    t = CRNL[0]
    t2 = CRNL.deploy(100, False, 100,100,10,10,15,chain.time(), 86400, 86400, 84000, {'from':accounts[0]})
    chain.sleep(1)
    t.commit("0x1f48afeee3247a1506c5ee8602abcfdf1909c3c5142a6a20223577fee8161f60", \
        {'from':accounts[1], 'value': 225}) # random
    t2.commit("0x1f48afeee3247a1506c5ee8602abcfdf1909c3c5142a6a20223577fee8161f60", \
        {'from':accounts[1], 'value': 225}) # random
    chain.sleep(86401 * 3)
    balance1 = accounts[0].balance()
    t.destruct({'from':accounts[7]})
    assert(balance1 == accounts[0].balance() - 220)
    balance2 = accounts[7].balance()
    t2.destruct({'from':accounts[7]})
    assert(balance2 == accounts[7].balance() - 210) # 10 => accounts[0]

# checks that fake revealNumber fails to reveal
def test_fake_reveal():
    t = CRNL[0]
    t.commit("0x4cf0329d3493fa458d54ff3008e9f4c69573b7720769671ef587a0082d184c0e", \
        {'from':accounts[1], 'value': 221}) # 5, 654
    chain.sleep(86401) 
    with reverts("hash check fail"):
        t.reveal(8,111,{'from':accounts[1]})

# checks that low msg.value fails to commit
def test_low_balance():
    t = CRNL[0]
    with reverts("not enougth ETH"):
        t.commit("0x4cf0329d3493fa458d54ff3008e9f4c69573b7720769671ef587a0082d184c0e", \
        {'from':accounts[1], 'value': 219}) # 5, 654

# test that changeOwner() works and only owner can call it
def test_change_owner():
    t = CRNL[0]
    with reverts("only owner can transfer his rights"):
        t.changeOwner(accounts[5], {'from':accounts[1]})
    t.changeOwner(accounts[5], {'from':accounts[0]})

# test of freePlaces functions
def test_free_places():
    t = CRNL.deploy(100, True, 100,100,10,10,2,chain.time(), 86400, 86400, 84000, {'from':accounts[0]})
    chain.sleep(1)
    
    # changes block.timestamp() when mined
    t2 = CRNL.deploy(100, True, 100,100,10,10,2,chain.time(), 86400, 86400, 84000, {'from':accounts[0]})

    assert(t.isFreePlaces() == True)
    t.commit("0x1f48afeee3247a1506c5ee8602abcfdf1909c3c5142a6a20223577fee8161f60", \
        {'from':accounts[1], 'value': 220}) # random
    t.commit("0x1f48afeee3247a1506c5ee8602abcfdf1909c3c5142a6a20223577fee8161f60", \
        {'from':accounts[2], 'value': 220}) # random
    assert(t.isFreePlaces() == False)

# checks that limit of participants can't be overflown
def test_people_limit():
    CRNL.deploy(100, True, 100,100,10,10,2,chain.time(), 86400, 86400, 84000, {'from':accounts[0]})
    t = CRNL[1]
    chain.sleep(1)
    t.commit("0x1f48afeee3247a1506c5ee8602abcfdf1909c3c5142a6a20223577fee8161f60", \
        {'from':accounts[1], 'value': 220}) # random
    t.commit("0x1f48afeee3247a1506c5ee8602abcfdf1909c3c5142a6a20223577fee8161f60", \
        {'from':accounts[2], 'value': 220}) # random
    with reverts("max part-s limit overflow"):
        t.commit("0x1f48afeee3247a1506c5ee8602abcfdf1909c3c5142a6a20223577fee8161f60", \
            {'from':accounts[3], 'value': 220}) # random

# checks that reCall of commit, reveal, countReward, takeReward is unable
def test_double_calls():
    t = CRNL[0]
    t.commit("0x4cf0329d3493fa458d54ff3008e9f4c69573b7720769671ef587a0082d184c0e", \
        {'from':accounts[1], 'value': 221}) # 5, 654
    t.commit("0xba3cc781c216dd7efa8a4295804186167660c8296119071ce2d45af33013e4fa", \
        {'from':accounts[2], 'value': 220}) # 15, 777
    t.commit("0x9045d2d894123dfb90a24453e03fdea3ab02099fb79a2eb93d31e0271c3a9f33", \
        {'from':accounts[3], 'value': 220}) # 10, 666  
    with reverts("already commited"):
        t.commit("0x4cf0329d3493fa458d54ff3008e9f4c69573b7720769671ef587a0082d184c0e", \
            {'from':accounts[1], 'value': 221}) # 5, 654

    chain.sleep(86401)
    t.reveal(5,654,{'from':accounts[1]})
    t.reveal(15,777,{'from':accounts[2]})
    t.reveal(10,666,{'from':accounts[3]}) 
    with reverts("already revealed"):
        t.reveal(5,654,{'from':accounts[1]})

    chain.sleep(86401)
    t.countRewards({'from':accounts[3]}) # 2/3 AVG = 6.67 => 6
    with reverts("rewards already counted"):
        t.countRewards({'from':accounts[3]}) # 2/3 AVG = 6.67 => 6

    t.takeReward({'from':accounts[1]}) # 5 is the closest to 6 
    with reverts("reward is already taken"):
        t.takeReward({'from':accounts[1]}) # 5 is the closest to 6 

# checks that time modifiers works
def test_time_logic():
    t = CRNL[0]
    t.commit("0x4cf0329d3493fa458d54ff3008e9f4c69573b7720769671ef587a0082d184c0e", \
        {'from':accounts[1], 'value': 221}) # 5, 654
    t.commit("0xba3cc781c216dd7efa8a4295804186167660c8296119071ce2d45af33013e4fa", \
        {'from':accounts[2], 'value': 220}) # 15, 777
    t.commit("0x9045d2d894123dfb90a24453e03fdea3ab02099fb79a2eb93d31e0271c3a9f33", \
        {'from':accounts[3], 'value': 220}) # 10, 666 
    with reverts("reveal phase is not started"):
        t.reveal(5,654,{'from':accounts[1]})
    
    chain.sleep(86401)
    t.reveal(5,654,{'from':accounts[1]})
    t.reveal(15,777,{'from':accounts[2]})
    t.reveal(10,666,{'from':accounts[3]}) 
    with reverts("reward phase is not started"):
        t.countRewards({'from':accounts[3]}) # 2/3 AVG = 6.67 => 6
    with reverts("reward phase is not started"):
        t.takeReward({'from':accounts[1]}) # 5 is the closest to 6 
    with reverts("commit phase finished"):
        t.commit("0x4cf0329d3493fa458d54ff3008e9f4c69573b7720769671ef587a0082d184c0e", \
            {'from':accounts[5], 'value': 221}) # 5, 654

    chain.sleep(86401)
    t.countRewards({'from':accounts[3]}) # 2/3 AVG = 6.67 => 6
    t.takeReward({'from':accounts[1]}) # 5 is the closest to 6 
    with reverts("destruct phase is not started"):
        t.destruct({'from':accounts[7]})
    with reverts("reveal phase finished"):
        t.reveal(10,666,{'from':accounts[3]}) 

    chain.sleep(86401) 
    t.destruct({'from':accounts[7]})

# cheks that stages can't be skipped
def test_stages_logic():
    t = CRNL[0]
    t.commit("0x4cf0329d3493fa458d54ff3008e9f4c69573b7720769671ef587a0082d184c0e", \
        {'from':accounts[1], 'value': 220}) # 5, 654
    t.commit("0xba3cc781c216dd7efa8a4295804186167660c8296119071ce2d45af33013e4fa", \
        {'from':accounts[2], 'value': 220}) # 15, 777
    t.commit("0x9045d2d894123dfb90a24453e03fdea3ab02099fb79a2eb93d31e0271c3a9f33", \
        {'from':accounts[3], 'value': 220}) # 10, 666  
    chain.sleep(86401) 
    t.reveal(5,654,{'from':accounts[1]})
    #t.reveal(15,777,{'from':accounts[2]})
    t.reveal(10,666,{'from':accounts[3]})
    with reverts("not commited"):
        t.reveal(10,666,{'from':accounts[4]})

    chain.sleep(86401) 
    with reverts("not revealed"):
        t.countRewards({'from':accounts[2]})
    t.countRewards({'from':accounts[3]}) # 2/3 AVG = 6.67 => 6
    with reverts("not revealed"):
        t.takeReward({'from':accounts[2]})
    t.takeReward({'from':accounts[1]}) # 5 is the closest to 6 
    t.changeOwner(accounts[5], {'from':accounts[0]})
    t.rewardOwner({'from':accounts[6]})
    chain.sleep(86401) 
    t.destruct({'from':accounts[7]})

# cheks that contact works if someone didn't reveal
def test_fault_tolerance():
    t = CRNL[0]
    t.commit("0x4cf0329d3493fa458d54ff3008e9f4c69573b7720769671ef587a0082d184c0e", \
        {'from':accounts[1], 'value': 225}) # 5, 654
    t.commit("0xba3cc781c216dd7efa8a4295804186167660c8296119071ce2d45af33013e4fa", \
        {'from':accounts[2], 'value': 220}) # 15, 777
    t.commit("0x9045d2d894123dfb90a24453e03fdea3ab02099fb79a2eb93d31e0271c3a9f33", \
        {'from':accounts[3], 'value': 220}) # 10, 666  

    chain.sleep(86401) 
    t.reveal(5,654,{'from':accounts[1]})
    t.reveal(15,777,{'from':accounts[2]})
    with reverts("hash check fail"):
        t.reveal(10,68945343,{'from':accounts[3]})
    
    #t.reveal(10,666,{'from':accounts[3]})

    chain.sleep(86401) 
    t.countRewards({'from':accounts[2]}) # 2/3 AVG = (2/3)*((5 + 15) / 2)  = 6.67 => 6
    balance = accounts[1].balance()
    t.takeReward({'from':accounts[1]}) # 5 is the closest to 6 
    assert(accounts[1].balance() > balance)
    # assert True

# cheks that contract count prize size correct
def test_two_winners():
    t = CRNL[0]
    t.commit("0xba3cc781c216dd7efa8a4295804186167660c8296119071ce2d45af33013e4fa", \
        {'from':accounts[1], 'value': 225}) # 15, 777
    t.commit("0x9045d2d894123dfb90a24453e03fdea3ab02099fb79a2eb93d31e0271c3a9f33", \
        {'from':accounts[2], 'value': 220}) # 10, 666
    t.commit("0x9045d2d894123dfb90a24453e03fdea3ab02099fb79a2eb93d31e0271c3a9f33", \
        {'from':accounts[3], 'value': 220}) # 10, 666  

    chain.sleep(86401) 
    t.reveal(15,777,{'from':accounts[1]})
    t.reveal(10,666,{'from':accounts[2]})
    t.reveal(10,666,{'from':accounts[3]})

    chain.sleep(86401) 
    t.countRewards({'from':accounts[3]}) # 2/3 AVG = 7.78 => 7

    balance1 = accounts[2].balance()
    t.takeReward({'from':accounts[2]}) # 10 is the closest to 7 
    assert(accounts[2].balance() > balance1)

    balance2 = accounts[3].balance()
    t.takeReward({'from':accounts[3]}) # 10 is the closest to 7 
    assert(accounts[3].balance() > balance2)
    
    with reverts("not winner"):
        t.takeReward({'from':accounts[1]})

# checks if contract doesn't revert for only 1 user
def test_only_user():
    t = CRNL[0]

    balance0 = accounts[1].balance()
    t.commit("0xba3cc781c216dd7efa8a4295804186167660c8296119071ce2d45af33013e4fa", \
        {'from':accounts[1], 'value': 225}) # 15, 777
    assert(balance0 - 220 == accounts[1].balance())

    chain.sleep(86401) 
    t.reveal(15,777,{'from':accounts[1]})
    assert(balance0 - 120 == accounts[1].balance())

    chain.sleep(86401) 
    t.countRewards({'from':accounts[1]}) # 2/3 AVG = 7.78 => 7
    assert(balance0 - 10 == accounts[1].balance())

    t.takeReward({'from':accounts[1]}) # 10 is the closest to 7 
    assert(balance0 - 10 == accounts[1].balance())
    
# same as first test, but for lite version
def test_liteCRNL():
    t = liteCRNL.deploy(100, 100, chain.time(), 86400, {'from':accounts[0]})
    chain.sleep(1)
    balance1 = accounts[1].balance()
    t.commit("0x1f48afeee3247a1506c5ee8602abcfdf1909c3c5142a6a20223577fee8161f60", \
        {'from':accounts[1], 'value': 225}) # random
    assert(balance1 - 220 == accounts[1].balance())

    t.changeCommitHash("0x4cf0329d3493fa458d54ff3008e9f4c69573b7720769671ef587a0082d184c0e", \
        {'from':accounts[1]}) # 5, 654
    t.commit("0xba3cc781c216dd7efa8a4295804186167660c8296119071ce2d45af33013e4fa", \
        {'from':accounts[2], 'value': 220}) # 15, 777
    t.commit("0x9045d2d894123dfb90a24453e03fdea3ab02099fb79a2eb93d31e0271c3a9f33", \
        {'from':accounts[3], 'value': 220}) # 10, 666  

    chain.sleep(86401) 
    balance2 = accounts[1].balance()
    t.reveal(5,654,{'from':accounts[1]})
    assert(balance2 + 100 == accounts[1].balance())

    t.reveal(15,777,{'from':accounts[2]})
    t.reveal(10,666,{'from':accounts[3]})

    chain.sleep(86401) 
    balance3 = accounts[3].balance()
    t.countRewards({'from':accounts[3]}) # 2/3 AVG = 6.67 => 6
    assert(balance3 + 10*3 + 100 == accounts[3].balance())

    balance4 = accounts[1].balance()
    t.takeReward({'from':accounts[1]}) # 5 is the closest to 6 
    assert(accounts[1].balance() > balance4)
    t.changeOwner(accounts[5], {'from':accounts[0]})

    balance5 = accounts[5].balance()
    t.rewardOwner({'from':accounts[6]})
    assert(balance5 + 10*3 == accounts[5].balance())
    chain.sleep(86401) 
    t.destruct({'from':accounts[7]})

# tests that destruct even is emitted
def test_destruct_event():
    chain.sleep(86400 * 7)
    t = CRNL[0]
    t.destruct({'from':accounts[7]})
    assert(history[1].events.keys()[0] == 'DestructEvent')

# checks views working
def test_views():
    t = CRNL[0]

    # changes block.timestamp() when mined
    t2 = CRNL.deploy(100, True, 100,100,10,10,2,chain.time(), 86400, 86400, 84000, {'from':accounts[0]})

    assert(t.getPhaseId() == 1)

    t.commit("0x1f48afeee3247a1506c5ee8602abcfdf1909c3c5142a6a20223577fee8161f60", \
        {'from':accounts[1], 'value': 225}) # random
    t.changeCommitHash("0x4cf0329d3493fa458d54ff3008e9f4c69573b7720769671ef587a0082d184c0e", \
        {'from':accounts[1]}) # 5, 654
    t.commit("0xba3cc781c216dd7efa8a4295804186167660c8296119071ce2d45af33013e4fa", \
        {'from':accounts[2], 'value': 220}) # 15, 777
    t.commit("0x9045d2d894123dfb90a24453e03fdea3ab02099fb79a2eb93d31e0271c3a9f33", \
        {'from':accounts[3], 'value': 220}) # 10, 666  

    chain.sleep(86405) 

    # changes block.timestamp() when mined
    t2 = CRNL.deploy(100, True, 100,100,10,10,2,chain.time(), 86400, 86400, 84000, {'from':accounts[0]})

    assert(t.getPhaseId() == 2)
    t.reveal(5,654,{'from':accounts[1]})
    t.reveal(15,777,{'from':accounts[2]})
    t.reveal(10,666,{'from':accounts[3]})

    chain.sleep(86405) 

    # changes block.timestamp() when mined
    t2 = CRNL.deploy(100, True, 100,100,10,10,2,chain.time(), 86400, 86400, 84000, {'from':accounts[0]})

    assert(t.getPhaseId() == 3)
    t.countRewards({'from':accounts[3]}) # 2/3 AVG = 6.67 => 6    
    assert(t.getPhaseId() == 4)
    assert(t.getWinnerStake() > 0)
    assert(t.getAvg() == 6)

# checks views reverts if used too soon
def test_views_reverts():
    t = CRNL[0]
     
    with reverts("reward is not counted yet"):
        t.getWinnerStake()
    with reverts("AVG is not counted yet"):
        t.getAvg()

# additional check of time logic
def test_not_started():
    t2 = CRNL.deploy(100, True, 100,100,10,10,2,(chain.time()+100), 86400, 86400, 84000, {'from':accounts[0]})
    with reverts("contract is not started"):
        t2.commit("0x1f48afeee3247a1506c5ee8602abcfdf1909c3c5142a6a20223577fee8161f60", \
        {'from':accounts[1], 'value': 225}) # random