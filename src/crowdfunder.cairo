use starknet::ContractAddress;

#[starknet::interface]
trait IERC20<TContractState> {
    fn name(self: @TContractState) -> felt252;

    fn symbol(self: @TContractState) -> felt252;

    fn decimals(self: @TContractState) -> u8;

    fn total_supply(self: @TContractState) -> u256;

    fn balance_of(self: @TContractState, account: ContractAddress) -> u256;

    fn allowance(self: @TContractState, owner: ContractAddress, spender: ContractAddress) -> u256;

    fn transfer(ref self: TContractState, recipient: ContractAddress, amount: u256) -> bool;

    fn transfer_from(
        ref self: TContractState, sender: ContractAddress, recipient: ContractAddress, amount: u256
    ) -> bool;

    fn approve(ref self: TContractState, spender: ContractAddress, amount: u256) -> bool;
}

#[starknet::interface]
trait ICrowdfunding<TContractState> {
    fn create_campaign(ref self: TContractState, name: felt252, funding_goal: u256);
    fn fund_campaign(ref self: TContractState, campaign_id: u64, token_address: ContractAddress, amount: uint256);
    fn withdraw(ref self: TContractState, campaign_id: u64);

    fn get_campaign(self: @TContractState, campaign_id: u64) -> Campaign;
    fn get_balance(self: @TContractState, campaign_id: u64) -> u256;
}

#[starknet::contract]
mod Crowdfunder {
    #[storage]
    struct Storage {
        campaign_id: u64,
        campaigns: Array<Campaign>,
        balances: Array<u256>
    }

    #[derive(Drop, Serde, starknet::Store)]
    pub struct Campaign {
        name: felt252,
        funding_goal: u256,
        creator: ContractAddress,
    }

    #[abi(embed_v0)]
    impl Crowdfunder of super::ICrowdfunding<ContractState> {
        // Write functions
        fn create_campaign(ref self: TContractState, name: _felt252, _funding_goal: u256) {
            let caller = get_caller_address();
            let new_campaign_id = self.campaign_id.read();

            let campaign = Campaign {
                name: _name,
                funding_goal: _funding_goal,
                creator: caller
            };

            campaigns[new_campaign_id] = campaign;

            // TODO: Emit event 
            // here

            // Update campaign id
            self.campaign_id.write(new_campaign_id + 1);
        }

        fn fund_campaign(ref self: TContractState, campaign_id: u64, token_address: ContractAddress, amount: uint256) {
            let campaign = self.campaigns[campaign_id];
            let caller = get_caller_address();
            let this_contract = get_contract_address();
            
            assert!(balances[campaign_id] < campaign.funding_goal, "CAMPAIGN_COMPLETED");

            IERC20Dispatcher { token_address }.transferFrom(caller, this_contract, amount);

            balances[campaign_id] += amount;
        }

        // Read functions
        fn get_campaign(self: @TContractState, campaign_id: u64) -> Campaign {
            return self.campaigns[campaign_id];
        }

        fn get_balance(campaign_id: u64) -> u256 {
            return self.balances[campaign_id];
        }
    }
}



