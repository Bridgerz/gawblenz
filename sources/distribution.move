module gawblenz::distribution;

use sui::coin::Coin;
use sui::event;
use sui::kiosk;
use sui::package;
use sui::random::Random;
use sui::sui::SUI;
use sui::table_vec::{Self, TableVec};
use sui::transfer_policy::TransferPolicy;

const PHASE_NOT_STARTED: u8 = 0;
const PHASE_OG: u8 = 1;
const PHASE_WHITELIST: u8 = 2;
const PHASE_PUBLIC: u8 = 3;

// our OTW to claim display
public struct DISTRIBUTION has drop {}

public struct Distribution<phantom T: key + store> has key {
    id: UID,
    items: TableVec<T>,
    og_price: u64,
    whitelist_price: u64,
    public_price: u64,
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

public struct Minted has copy, drop {
    id: ID,
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
    admin: address,
    _: &DistributionCap,
    ctx: &mut TxContext,
) {
    let distribution = Distribution<T> {
        id: object::new(ctx),
        items: table_vec::empty(ctx),
        og_price: 3000000000,
        whitelist_price: 6000000000,
        public_price: 8000000000,
        og_minted: 0,
        whitelist_minted: 0,
        total_minted: 0,
        phase: PHASE_NOT_STARTED,
        admin: admin,
    };

    transfer::share_object(distribution);
}

public fun new_og_cap(
    _: &DistributionCap,
    max_mint: u64,
    recipient: address,
    ctx: &mut TxContext,
) {
    let cap = OGCap {
        id: object::new(ctx),
        max_mint: max_mint,
        current_mint: 0,
    };
    transfer::public_transfer(cap, recipient);
}

public fun new_whitelist_cap(
    _: &DistributionCap,
    max_mint: u64,
    recipient: address,
    ctx: &mut TxContext,
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
    policy: &TransferPolicy<T>,
    payment: Coin<SUI>,
    quantity: u64,
    random: &Random,
    ctx: &mut TxContext,
) {
    assert!(distribution.phase == PHASE_PUBLIC);
    assert!(payment.value() >= distribution.public_price * quantity);

    mint_internal(distribution, payment, policy, quantity, random, ctx);

    distribution.total_minted = distribution.total_minted + quantity;
}

entry fun og_mint<T: key + store>(
    distribution: &mut Distribution<T>,
    policy: &TransferPolicy<T>,
    payment: Coin<SUI>,
    cap: &mut OGCap,
    quantity: u64,
    random: &Random,
    ctx: &mut TxContext,
) {
    assert!(distribution.phase == PHASE_OG);
    assert!(payment.value() >= distribution.og_price * quantity);
    assert!(cap.current_mint + quantity <= cap.max_mint);

    mint_internal(distribution, payment, policy, quantity, random, ctx);

    distribution.og_minted = distribution.og_minted + quantity;
    distribution.total_minted = distribution.total_minted + quantity;
    cap.current_mint = cap.current_mint + quantity;
}

entry fun whitelist_mint<T: key + store>(
    distribution: &mut Distribution<T>,
    policy: &TransferPolicy<T>,
    payment: Coin<SUI>,
    cap: &mut WhitelistCap,
    quantity: u64,
    random: &Random,
    ctx: &mut TxContext,
) {
    assert!(cap.current_mint + quantity <= cap.max_mint);
    assert!(distribution.phase == PHASE_WHITELIST);
    assert!(payment.value() >= distribution.whitelist_price * quantity);

    mint_internal(distribution, payment, policy, quantity, random, ctx);

    distribution.whitelist_minted = distribution.whitelist_minted + quantity;
    distribution.total_minted = distribution.total_minted + quantity;
    cap.current_mint = cap.current_mint + quantity;
}

public fun update_phase<T: key + store>(
    distribution: &mut Distribution<T>,
    _: &DistributionCap,
    phase: u8,
) {
    distribution.phase = phase;
}

public fun update_og_price<T: key + store>(
    distribution: &mut Distribution<T>,
    _: &DistributionCap,
    price: u64,
) {
    distribution.og_price = price;
}

public fun update_whitelist_price<T: key + store>(
    distribution: &mut Distribution<T>,
    _: &DistributionCap,
    price: u64,
) {
    distribution.whitelist_price = price;
}

public fun update_public_price<T: key + store>(
    distribution: &mut Distribution<T>,
    _: &DistributionCap,
    price: u64,
) {
    distribution.public_price = price;
}

public fun og_cost<T: key + store>(distribution: &Distribution<T>): u64 {
    distribution.og_price
}

public fun whitelist_cost<T: key + store>(distribution: &Distribution<T>): u64 {
    distribution.whitelist_price
}

public fun public_cost<T: key + store>(distribution: &Distribution<T>): u64 {
    distribution.public_price
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

#[allow(lint(self_transfer))]
fun mint_internal<T: key + store>(
    distribution: &mut Distribution<T>,
    payment: Coin<SUI>,
    policy: &TransferPolicy<T>,
    quantity: u64,
    random: &Random,
    ctx: &mut TxContext,
) {
    let mut generator = random.new_generator(ctx);

    assert!(distribution.items.length() >= quantity);
    let (mut kiosk, kiosk_owner_cap) = kiosk::new(ctx);
    quantity.do!(|_| {
        let index = generator.generate_u64_in_range(
            0,
            distribution.items.length() - 1,
        );
        let item = distribution.items.swap_remove(index);
        // emit minted event with object ID
        event::emit(Minted {
            id: object::id(&item),
        });
        kiosk.lock(
            &kiosk_owner_cap,
            policy,
            item,
        );
    });
    transfer::public_transfer(payment, distribution.admin);
    transfer::public_transfer(kiosk_owner_cap, ctx.sender());
    transfer::public_share_object(kiosk);
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
