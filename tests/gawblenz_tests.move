#[test_only]
module gawblenz::gawblenz_test;

use gawblenz::distribution::{Self, Distribution, OGCap, WhitelistCap};
use gawblenz::gawblen::{Self, Gawblen};
use sui::coin::Coin;
use sui::random::Random;
use sui::sui::SUI;
use sui::test_scenario;

#[test]
fun test_gawblenz() {
    let (admin, manny) = (@0x1, @0x2);

    let mut scenario = test_scenario::begin(@0x0);

    sui::random::create_for_testing(scenario.ctx());

    scenario.next_tx(@0x0);

    let mut random: Random = scenario.take_shared();
    random.update_randomness_state_for_testing(
        0,
        x"1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F",
        scenario.ctx(),
    );

    scenario.next_tx(admin);
    gawblen::init_for_testing(scenario.ctx());
    scenario.next_tx(admin);
    distribution::init_for_testing(scenario.ctx());
    scenario.next_tx(admin);

    let distribution_cap = distribution::create_distribution_cap_for_testing(scenario.ctx());
    let mut admin_cap = gawblen::create_admin_cap_for_testing(scenario.ctx());

    distribution::new<gawblen::Gawblen>(
        scenario.ctx(),
        admin,
        &distribution_cap,
    );

    scenario.next_tx(admin);

    let mut distribution = scenario.take_shared<Distribution<Gawblen>>();

    gawblen::create(
        &mut admin_cap,
        &mut distribution,
        b"https://gawblenz.com/image.png".to_string(),
        sui::vec_map::empty(),
        scenario.ctx(),
    );

    gawblen::create(
        &mut admin_cap,
        &mut distribution,
        b"https://gawblenz.com/image.png".to_string(),
        sui::vec_map::empty(),
        scenario.ctx(),
    );

    gawblen::create(
        &mut admin_cap,
        &mut distribution,
        b"https://gawblenz.com/image.png".to_string(),
        sui::vec_map::empty(),
        scenario.ctx(),
    );

    scenario.next_tx(admin);

    distribution.update_phase(
        &distribution_cap,
        3,
    );

    scenario.next_tx(manny);

    let mut coin = sui::coin::mint_for_testing<SUI>(
        10_000_000_000,
        scenario.ctx(),
    );

    let payment = coin.split(distribution::public_cost(), scenario.ctx());

    distribution::mint(
        &mut distribution,
        payment,
        &random,
        scenario.ctx(),
    );

    scenario.next_tx(admin);

    let gawblen = scenario.take_from_address<Gawblen>(manny);

    assert!(gawblen.number() == 1, 0);
    assert!(distribution.items_length() == 2, 0);
    assert!(distribution.total_minted() == 1, 0);
    assert!(distribution.og_minted() == 0, 0);
    assert!(distribution.whitelist_minted() == 0, 0);

    scenario.next_tx(admin);

    let payment = scenario.take_from_address<Coin<SUI>>(admin);

    assert!(payment.value() == distribution::public_cost(), 0);

    scenario.next_tx(manny);

    distribution::mint(
        &mut distribution,
        payment,
        &random,
        scenario.ctx(),
    );

    scenario.next_tx(admin);
    let gawblen2 = scenario.take_from_address<Gawblen>(manny);
    assert!(gawblen2.number() == 3, 0);
    assert!(distribution.items_length() == 1, 0);
    assert!(distribution.total_minted() == 2, 0);
    assert!(distribution.og_minted() == 0, 0);
    assert!(distribution.whitelist_minted() == 0, 0);

    scenario.next_tx(admin);
    let payment = scenario.take_from_address<Coin<SUI>>(admin);
    assert!(payment.value() == distribution::public_cost(), 0);

    transfer::public_transfer(admin_cap, admin);
    transfer::public_transfer(distribution_cap, admin);
    transfer::public_transfer(payment, admin);
    transfer::public_transfer(gawblen, manny);
    transfer::public_transfer(gawblen2, manny);
    transfer::public_transfer(coin, admin);
    test_scenario::return_shared(distribution);
    test_scenario::return_shared(random);

    scenario.end();
}

#[test]
fun test_gawblenz_og() {
    let (admin, manny) = (@0x1, @0x2);

    let mut scenario = test_scenario::begin(@0x0);

    sui::random::create_for_testing(scenario.ctx());

    scenario.next_tx(@0x0);

    let mut random: Random = scenario.take_shared();
    random.update_randomness_state_for_testing(
        0,
        x"1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F",
        scenario.ctx(),
    );

    scenario.next_tx(admin);
    gawblen::init_for_testing(scenario.ctx());
    scenario.next_tx(admin);
    distribution::init_for_testing(scenario.ctx());
    scenario.next_tx(admin);

    let distribution_cap = distribution::create_distribution_cap_for_testing(scenario.ctx());
    let mut admin_cap = gawblen::create_admin_cap_for_testing(scenario.ctx());

    distribution::new_og_cap(
        scenario.ctx(),
        &distribution_cap,
        1000,
        manny,
    );
    scenario.next_tx(admin);

    let mut og_cap = scenario.take_from_address<OGCap>(manny);

    distribution::new<gawblen::Gawblen>(
        scenario.ctx(),
        admin,
        &distribution_cap,
    );

    scenario.next_tx(admin);

    let mut distribution = scenario.take_shared<Distribution<Gawblen>>();

    gawblen::create(
        &mut admin_cap,
        &mut distribution,
        b"https://gawblenz.com/image.png".to_string(),
        sui::vec_map::empty(),
        scenario.ctx(),
    );

    gawblen::create(
        &mut admin_cap,
        &mut distribution,
        b"https://gawblenz.com/image.png".to_string(),
        sui::vec_map::empty(),
        scenario.ctx(),
    );

    gawblen::create(
        &mut admin_cap,
        &mut distribution,
        b"https://gawblenz.com/image.png".to_string(),
        sui::vec_map::empty(),
        scenario.ctx(),
    );

    scenario.next_tx(admin);

    distribution.update_phase(
        &distribution_cap,
        1,
    );

    scenario.next_tx(manny);

    let mut coin = sui::coin::mint_for_testing<SUI>(
        10_000_000_000,
        scenario.ctx(),
    );

    let payment = coin.split(distribution::og_cost(), scenario.ctx());

    distribution::og_mint(
        &mut distribution,
        payment,
        &mut og_cap,
        &random,
        scenario.ctx(),
    );

    scenario.next_tx(admin);

    let gawblen = scenario.take_from_address<Gawblen>(manny);

    assert!(gawblen.number() == 2, 0);
    assert!(distribution.items_length() == 2, 0);
    assert!(distribution.total_minted() == 1, 0);
    assert!(distribution.og_minted() == 1, 0);
    assert!(og_cap.og_current_mint() == 1, 0);
    assert!(distribution.whitelist_minted() == 0, 0);

    scenario.next_tx(admin);

    let payment = scenario.take_from_address<Coin<SUI>>(admin);

    assert!(payment.value() == distribution::og_cost(), 0);

    transfer::public_transfer(admin_cap, admin);
    transfer::public_transfer(distribution_cap, admin);
    transfer::public_transfer(payment, admin);
    transfer::public_transfer(gawblen, manny);
    transfer::public_transfer(coin, admin);
    transfer::public_transfer(og_cap, manny);
    test_scenario::return_shared(distribution);
    test_scenario::return_shared(random);

    scenario.end();
}

#[test]
fun test_gawblenz_whitelist() {
    let (admin, manny) = (@0x1, @0x2);

    let mut scenario = test_scenario::begin(@0x0);

    sui::random::create_for_testing(scenario.ctx());

    scenario.next_tx(@0x0);

    let mut random: Random = scenario.take_shared();
    random.update_randomness_state_for_testing(
        0,
        x"1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F",
        scenario.ctx(),
    );

    scenario.next_tx(admin);
    gawblen::init_for_testing(scenario.ctx());
    scenario.next_tx(admin);
    distribution::init_for_testing(scenario.ctx());
    scenario.next_tx(admin);

    let distribution_cap = distribution::create_distribution_cap_for_testing(scenario.ctx());
    let mut admin_cap = gawblen::create_admin_cap_for_testing(scenario.ctx());

    distribution::new_whitelist_cap(
        scenario.ctx(),
        &distribution_cap,
        1000,
        manny,
    );
    scenario.next_tx(admin);

    let mut whitelist_cap = scenario.take_from_address<WhitelistCap>(manny);

    distribution::new<gawblen::Gawblen>(
        scenario.ctx(),
        admin,
        &distribution_cap,
    );

    scenario.next_tx(admin);

    let mut distribution = scenario.take_shared<Distribution<Gawblen>>();

    gawblen::create(
        &mut admin_cap,
        &mut distribution,
        b"https://gawblenz.com/image.png".to_string(),
        sui::vec_map::empty(),
        scenario.ctx(),
    );

    gawblen::create(
        &mut admin_cap,
        &mut distribution,
        b"https://gawblenz.com/image.png".to_string(),
        sui::vec_map::empty(),
        scenario.ctx(),
    );

    gawblen::create(
        &mut admin_cap,
        &mut distribution,
        b"https://gawblenz.com/image.png".to_string(),
        sui::vec_map::empty(),
        scenario.ctx(),
    );

    scenario.next_tx(admin);

    distribution.update_phase(
        &distribution_cap,
        2,
    );

    scenario.next_tx(manny);

    let mut coin = sui::coin::mint_for_testing<SUI>(
        10_000_000_000,
        scenario.ctx(),
    );

    let payment = coin.split(distribution::whitelist_cost(), scenario.ctx());

    distribution::whitelist_mint(
        &mut distribution,
        payment,
        &mut whitelist_cap,
        &random,
        scenario.ctx(),
    );

    scenario.next_tx(admin);

    let gawblen = scenario.take_from_address<Gawblen>(manny);

    assert!(gawblen.number() == 2, 0);
    assert!(distribution.items_length() == 2, 0);
    assert!(distribution.total_minted() == 1, 0);
    assert!(distribution.og_minted() == 0, 0);
    assert!(distribution.whitelist_minted() == 1, 0);
    assert!(whitelist_cap.whitelist_current_mint() == 1, 0);

    scenario.next_tx(admin);

    let payment = scenario.take_from_address<Coin<SUI>>(admin);

    assert!(payment.value() == distribution::whitelist_cost(), 0);

    transfer::public_transfer(admin_cap, admin);
    transfer::public_transfer(distribution_cap, admin);
    transfer::public_transfer(payment, admin);
    transfer::public_transfer(gawblen, manny);
    transfer::public_transfer(coin, admin);
    transfer::public_transfer(whitelist_cap, manny);
    test_scenario::return_shared(distribution);
    test_scenario::return_shared(random);

    scenario.end();
}

#[test]
fun test_generate_and_mint_all() {
    let (admin) = @0x1;

    let mut scenario = test_scenario::begin(@0x0);

    scenario.next_tx(admin);
    gawblen::init_for_testing(scenario.ctx());
    scenario.next_tx(admin);
    distribution::init_for_testing(scenario.ctx());
    scenario.next_tx(admin);

    let distribution_cap = distribution::create_distribution_cap_for_testing(scenario.ctx());
    let mut admin_cap = gawblen::create_admin_cap_for_testing(scenario.ctx());

    distribution::new<gawblen::Gawblen>(
        scenario.ctx(),
        admin,
        &distribution_cap,
    );

    scenario.next_tx(admin);

    let mut distribution = scenario.take_shared<Distribution<Gawblen>>();

    admin_cap.max_id().do!(|_| {
        gawblen::create(
            &mut admin_cap,
            &mut distribution,
            b"https://gawblenz.com/image.png".to_string(),
            sui::vec_map::empty(),
            scenario.ctx(),
        );
    });

    scenario.next_tx(admin);

    assert!(distribution.items_length() == 3333, 0);

    distribution.update_phase(
        &distribution_cap,
        3,
    );

    scenario.next_tx(@0x0);

    sui::random::create_for_testing(scenario.ctx());

    scenario.next_tx(@0x0);

    let mut random: Random = scenario.take_shared();
    random.update_randomness_state_for_testing(
        0,
        x"1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F1F",
        scenario.ctx(),
    );

    scenario.next_tx(admin);

    let mut coin = sui::coin::mint_for_testing<SUI>(
        10_000_000_000 * 3333,
        scenario.ctx(),
    );

    // mint all the NFTs
    admin_cap.max_id().do!(|_| {
        let payment = coin.split(distribution::public_cost(), scenario.ctx());

        distribution::mint(
            &mut distribution,
            payment,
            &random,
            scenario.ctx(),
        );
    });

    assert!(distribution.total_minted() == 3333, 0);
    assert!(distribution.items_length() == 0, 0);
    assert!(distribution.og_minted() == 0, 0);
    assert!(distribution.whitelist_minted() == 0, 0);

    transfer::public_transfer(admin_cap, admin);
    transfer::public_transfer(distribution_cap, admin);
    test_scenario::return_shared(distribution);
    transfer::public_transfer(coin, admin);
    test_scenario::return_shared(random);

    scenario.end();
}

// test failure with wrong phase

// test cant mint more than phase max

// test failure with wrong payment
