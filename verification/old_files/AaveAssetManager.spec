using MockAaveLendingPool as pool

methods {
    // ERC20 methods
    transfer(address, uint256) returns bool envfree => DISPATCHER(true)
    transferFrom(address, address, uint256) returns bool envfree => DISPATCHER(true)
    balanceOf(address) returns uint256 envfree => DISPATCHER(true)
	withdraw(address, uint256, address) => DISPATCHER(true)
    deposit(address, uint256, address, uint16) => DISPATCHER(true)
    mint(address, uint256) => DISPATCHER(true)
    burn(address, uint256) => DISPATCHER(true)

    // summarizing as NONDET
    0x3111e7b3 => NONDET  // IAaveIncentivesController.claimRewards
    notifyRewardAmount(address, address, uint256) => NONDET
    getPoolTokenInfo(bytes32, address) => NONDET

    // envfree contract functions
    getAUM(bytes32) returns uint256 envfree
    rebalance(bytes32, bool) envfree
    aToken() returns address envfree
    pool.aum_token() returns address envfree
    initialize(bytes32, address) envfree

    // envfree harness functions
    Harness_getMaxTargetInvestment() envfree
    Harness_capitalOut(uint256) envfree
    Harness_capitalIn(uint256) envfree
    Harness_getTargetPercentage() envfree
    Harness_getUpperCriticalPercentage() envfree
    Harness_getLowerCriticalPercentage() envfree
}

// definition MAX_TARGET_PERCENTAGE() returns uint256 = 1e18;

rule capital_out_decreases_investments {
    uint256 amount;
    bytes32 poolId;

    uint256 pre_aum = getAUM(poolId);
    Harness_capitalOut(amount);
    uint256 post_aum = getAUM(poolId);

    assert pre_aum >= post_aum, "capital out should reduce the number of managed assets";
}

rule capital_in_increases_investments {
    uint256 amount;
    bytes32 poolId;

    uint256 pre_aum = getAUM(poolId);
    Harness_capitalIn(amount);
    uint256 post_aum = getAUM(poolId);

    assert pre_aum <= post_aum, "capital in should increase the number of managed assets";
}

rule single_init {
    bytes32 pool_id;
    address distributor;
    initialize(pool_id, distributor);
    initialize@withrevert(pool_id, distributor);
    assert lastReverted;
}

rule aum_mutators {
    bytes32 poolId;
    uint256 pre_aum = getAUM(poolId);
    env e;
    calldataarg a;
    method f;

    // Ignore harness functions
    require f.selector != Harness_capitalOut(uint256).selector;
    require f.selector != Harness_capitalIn(uint256).selector;

    f(e, a);
    uint256 post_aum = getAUM(poolId);
    assert pre_aum != post_aum => f.selector == rebalance(bytes32, bool).selector || f.selector == capitalOut(bytes32,uint256).selector;
}

invariant target_percentage_less_than_one() Harness_getTargetPercentage() <= Harness_getMaxTargetInvestment()

invariant legal_config() Harness_getUpperCriticalPercentage() >= Harness_getTargetPercentage() && Harness_getTargetPercentage() >= Harness_getLowerCriticalPercentage()

rule only_set_config_changes_config {
    uint256 init_target_percentage = Harness_getTargetPercentage();
    uint256 init_upper_percentage = Harness_getUpperCriticalPercentage();
    uint256 init_lower_percentage = Harness_getLowerCriticalPercentage();

    env e;
    calldataarg a;
    method f;

    uint256 fin_target_percentage = Harness_getTargetPercentage();
    uint256 fin_upper_percentage = Harness_getUpperCriticalPercentage();
    uint256 fin_lower_percentage = Harness_getLowerCriticalPercentage();

    bool target_changed = (init_target_percentage != fin_target_percentage);
    bool upper_changed = (init_upper_percentage != fin_upper_percentage);
    bool lower_changed = (init_lower_percentage != fin_lower_percentage);
    bool conf_changed = target_changed || upper_changed || lower_changed;

    assert conf_changed => f.selector == setConfig(bytes32, bytes).selector;
}