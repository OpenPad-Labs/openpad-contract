
module openpad::user_tests {

    // #[test_only]
    // use sui::object::{Self, ID, UID};

    #[test_only]
    use std::string::{Self};

    // #[test_only]
    // use sui::tx_context::{Self, TxContext};

    #[test_only]
    use sui::test_scenario::{Self};

    #[test_only]
    use openpad::user::{Self, init_test, UserProfile, UserRegistry};

    #[test]
    fun create_and_upate_name_should_works() {
        let user_addr = @0x008;
        // let user2_addr = @0x009;

        let nickname = string::utf8(b"James");
        let name2 = b"jamesbond";

        let scenario_val = test_scenario::begin(user_addr);
        let scenario = &mut scenario_val;

        // init module 
        let ctx = test_scenario::ctx(scenario);
        init_test(ctx);

        // create user
        test_scenario::next_tx(scenario, user_addr);
        {
            let registry = test_scenario::take_shared<UserRegistry>(scenario);
            let ctx = test_scenario::ctx(scenario);
            
            user::register_with_name(&mut registry, nickname, ctx);

            test_scenario::return_shared(registry);
        };

        // setter 
        test_scenario::next_tx(scenario, user_addr); 
        {
            let u = test_scenario::take_from_sender<UserProfile>(scenario);
            let ur = test_scenario::take_shared<UserRegistry>(scenario);
            let ctx = test_scenario::ctx(scenario);
            user::update_user_name(&mut u, &ur, name2, ctx);

            test_scenario::return_to_sender(scenario, u);
            test_scenario::return_shared(ur);
            
        };

        // getter
        test_scenario::next_tx(scenario, user_addr); 
        {
            let u = test_scenario::take_from_sender<UserProfile>(scenario);
            assert!(user::name(&u) == string::utf8(name2), 0);

            test_scenario::return_to_sender(scenario, u);
        };

        test_scenario::end(scenario_val);
    }
}