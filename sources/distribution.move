module gawblenz::distribution;

use sui::coin::Coin;
use sui::package;
use sui::random::Random;
use sui::sui::SUI;
use sui::table_vec::{Self, TableVec};

const PHASE_NOT_STARTED: u8 = 0;
const PHASE_OG: u8 = 1;
const PHASE_WHITELIST: u8 = 2;
const PHASE_PUBLIC: u8 = 3;

const OG_PRICE: u64 = 3000000000;
const WHITELIST_PRICE: u64 = 6000000000;
const PUBLIC_PRICE: u64 = 8000000000;

// our OTW to claim display
public struct DISTRIBUTION has drop {}

public struct Distribution<phantom T: key + store> has key {
    id: UID,
    items: TableVec<T>,
    og_minted: u64,
    whitelist_minted: u64,
    total_minted: u64,
    phase: u8,
    admin: address,
}

public struct DistributionCap has key, store {
    id: UID,
}

public struct OGCap has key, store {
    id: UID,
    max_mint: u64,
    current_mint: u64,
}

public struct WhitelistCap has key, store {
    id: UID,
    max_mint: u64,
    current_mint: u64,
}

/// Claim Publisher to create Display,
fun init(otw: DISTRIBUTION, ctx: &mut TxContext) {
    // get the Publisher obj.
    package::claim_and_keep(otw, ctx);

    let cap = DistributionCap {
        id: object::new(ctx),
    };

    transfer::public_transfer(cap, ctx.sender());
}

public fun new<T: key + store>(
    ctx: &mut TxContext,
    admin: address,
    _: &DistributionCap,
) {
    let distribution = Distribution<T> {
        id: object::new(ctx),
        items: table_vec::empty(ctx),
        og_minted: 0,
        whitelist_minted: 0,
        total_minted: 0,
        phase: PHASE_NOT_STARTED,
        admin: admin,
    };

    transfer::share_object(distribution);
}

public fun new_og_cap(
    ctx: &mut TxContext,
    _: &DistributionCap,
    max_mint: u64,
    recipient: address,
) {
    let cap = OGCap {
        id: object::new(ctx),
        max_mint: max_mint,
        current_mint: 0,
    };
    transfer::public_transfer(cap, recipient);
}

public fun new_whitelist_cap(
    ctx: &mut TxContext,
    _: &DistributionCap,
    max_mint: u64,
    recipient: address,
) {
    let cap = WhitelistCap {
        id: object::new(ctx),
        max_mint: max_mint,
        current_mint: 0,
    };
    transfer::public_transfer(cap, recipient);
}

entry fun mint<T: key + store>(
    distribution: &mut Distribution<T>,
    payment: Coin<SUI>,
    random: &Random,
    ctx: &mut TxContext,
) {
    assert!(distribution.phase == PHASE_PUBLIC);
    assert!(payment.value() >= PUBLIC_PRICE);
    assert!(distribution.items.length() > 0);

    let item = mint_internal(distribution, random, ctx);

    transfer::public_transfer(item, ctx.sender());
    transfer::public_transfer(payment, distribution.admin);

    distribution.total_minted = distribution.total_minted + 1;
}

entry fun og_mint<T: key + store>(
    distribution: &mut Distribution<T>,
    payment: Coin<SUI>,
    cap: &mut OGCap,
    random: &Random,
    ctx: &mut TxContext,
) {
    assert!(cap.current_mint < cap.max_mint);
    assert!(distribution.phase == PHASE_OG);
    assert!(payment.value() >= OG_PRICE);
    assert!(distribution.items.length() > 0);

    let item = mint_internal(distribution, random, ctx);

    transfer::public_transfer(item, ctx.sender());
    transfer::public_transfer(payment, distribution.admin);

    distribution.og_minted = distribution.og_minted + 1;
    distribution.total_minted = distribution.total_minted + 1;
    cap.current_mint = cap.current_mint + 1;
}

entry fun whitelist_mint<T: key + store>(
    distribution: &mut Distribution<T>,
    payment: Coin<SUI>,
    cap: &mut WhitelistCap,
    random: &Random,
    ctx: &mut TxContext,
) {
    assert!(cap.current_mint < cap.max_mint);
    assert!(distribution.phase == PHASE_WHITELIST);
    assert!(payment.value() >= WHITELIST_PRICE);
    assert!(distribution.items.length() > 0);

    let item = mint_internal(distribution, random, ctx);

    transfer::public_transfer(item, ctx.sender());
    transfer::public_transfer(payment, distribution.admin);

    distribution.whitelist_minted = distribution.whitelist_minted + 1;
    distribution.total_minted = distribution.total_minted + 1;
    cap.current_mint = cap.current_mint + 1;
}

public fun update_phase<T: key + store>(
    distribution: &mut Distribution<T>,
    _: &DistributionCap,
    phase: u8,
) {
    distribution.phase = phase;
}

public fun og_cost(): u64 {
    OG_PRICE
}

public fun whitelist_cost(): u64 {
    WHITELIST_PRICE
}

public fun public_cost(): u64 {
    PUBLIC_PRICE
}

public fun items_length<T: key + store>(distribution: &Distribution<T>): u64 {
    distribution.items.length()
}

public fun total_minted<T: key + store>(distribution: &Distribution<T>): u64 {
    distribution.total_minted
}

public fun og_minted<T: key + store>(distribution: &Distribution<T>): u64 {
    distribution.og_minted
}

public fun og_current_mint(cap: &OGCap): u64 {
    cap.current_mint
}

public fun whitelist_current_mint(cap: &WhitelistCap): u64 {
    cap.current_mint
}

public fun whitelist_minted<T: key + store>(
    distribution: &Distribution<T>,
): u64 {
    distribution.whitelist_minted
}

fun mint_internal<T: key + store>(
    distribution: &mut Distribution<T>,
    random: &Random,
    ctx: &mut TxContext,
): T {
    let mut generator = random.new_generator(ctx);
    let index = generator.generate_u64_in_range(
        0,
        distribution.items.length() - 1,
    );
    distribution.items.swap_remove(index)
}

public(package) fun add_nft<T: key + store>(
    registry: &mut Distribution<T>,
    object: T,
) {
    registry.items.push_back(object);
}

#[test_only]
public(package) fun init_for_testing(ctx: &mut TxContext) {
    init(DISTRIBUTION {}, ctx);
}

#[test_only]
public(package) fun create_distribution_cap_for_testing(
    ctx: &mut TxContext,
): DistributionCap {
    DistributionCap {
        id: object::new(ctx),
    }
}
