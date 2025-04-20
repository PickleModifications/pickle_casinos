import React, { createContext, useContext, useState, ReactNode } from 'react';
import { useNuiEvent } from './nui/useNui';
import { Chip } from '@/components/casino/Casino';
import { GameSettingsType } from '@/components/creator/Creator';

export type Config = {
    bonusWheelMultipliers: {
        id: string;
        multiplier: number;
    }[];
    identifier: string;
    locale?: Record<string, string>;
    countryCode?: string;
    currency?: string;
    chips?: Chip[];
    gameSettings?: GameSettingsType;
}

interface ConfigContextProps {
    config: Config;
    setConfig: (config: Config) => void;
}

const ConfigContext = createContext<ConfigContextProps | undefined>(undefined);

export const ConfigProvider: React.FC<{ children: ReactNode }> = ({ children }) => {
    const [config, setConfig] = useState<Config>({
        identifier: "ERR_NO_IDENTIFIER",
        currency: "GBP",
        countryCode: "en-GB",
        chips: [
            {color: "#15803D", value: 1},
            {color: "#C2410C", value: 5},
            {color: "#BE185D", value: 10},
            {color: "#3F3F46", value: 100},
            {color: "#0369A1", value: 1000},
            {color: "#15803D", value: 10000},
            {color: "#C2410C", value: 25000},
            {color: "#BE185D", value: 100000},
            {color: "#3F3F46", value: 250000},
            {color: "#0369A1", value: 1000000},
        ],
        bonusWheelMultipliers: [],
        locale: {
            "casino_vipenabled": "VIP Exclusive",
            "casino_money": "Balance: %s",
            "casino_betrange": "Limit: %s - %s",
            "casino_owner": "Owner: %s",
            "casino_id": "ID: %s",
            "casino_location": "Location",
            "casino_entities": "Entities",
            "casino_exit": "Return to Casino List",
            "casino_create": "Create Casino",
            "casino_name": "Label",
            "casino_item": "Chip Item",
            "casino_blipenabled": "Enable Blip",
            "casino_teleport": "Teleport to Casino",
            "casino_delete": "Delete Casino",
            "casino_entity_teleport": "Teleport to Entity",
            "casino_entity_delete": "Delete Entity",
            "casino_entity_create_title": "Create Entity",
            "casino_entity_type": "Entity Type",
            "casino_entity_exit": "Return to Casino",
            "casino_entity_create": "Create Entity",
            "casino_manage_profit": "Weekly Profit",
            "casino_manage_balance": "Cash Account",
            "casino_manage_markedbalance": "Marked Bills",
            "casino_manage_transfer": "Transfer",
            "casino_manage_transactions": "Transactions",
            "casino_manage_settings": "Settings",
            "casino_manage_deposit": "Deposit",
            "casino_manage_withdraw": "Withdraw",
            "casino_manage_moneyExchangeRate": "Cash Exchange Rate",
            "casino_manage_moneyExchangeRate_desc": "The exchange rate for buying chips with cash.",
            "casino_manage_dirtyExchangeRate": "Marked Exchange Rate",
            "casino_manage_dirtyExchangeRate_desc": "The exchange rate for buying chips with marked bills.",
            "casino_manage_editor": "Launch Casino Editor",
            "blackjack_title": "Blackjack",
            "blackjack_nextround": "Next Round: %s",
            "blackjack_dealing": "Dealer is now dealing cards...",
            "blackjack_displaycard": "Dealer is revealing the hidden card...",
            "blackjack_otherturn": "Player in seat #%s is playing their hand...",
            "blackjack_playerturn": "You have %s second(s) to play your hand...",
            "blackjack_won": "You won %s this round!",
            "blackjack_lost": "You didn't win this round, better luck next time!",
            "blackjack_desc": "Welcome to Blackjack! The dealer must stay on 17, and only one split is allowed.",
            "blackjack_hit": "Hit",
            "blackjack_stand": "Stand",
            "blackjack_double": "Double",
            "blackjack_split": "Split",
            "blackjack_hand": "Hand #%s",
            "roulette_title": "Roulette",
            "roulette_desc": "Welcome to Roulette! Place your bets and watch the wheel spin!",
            "roulette_nextround": "Next Round: %s",
            "roulette_section_1": "1st 12",
            "roulette_section_2": "2nd 12",
            "roulette_section_3": "3rd 12",
            "roulette_section_4": "1 to 18",
            "roulette_section_5": "19 to 36",
            "roulette_section_6": "Even",
            "roulette_section_7": "Odd",
            "roulette_red": "Red",
            "roulette_black": "Black",
            "roulette_green": "Green",
            "roulette_rolling": "The ball is spinning, good luck!",
            "roulette_numberwinner": "The winning number is:",
            "roulette_lastnumbers": "Recent Numbers:",
            "baccarat_title": "Baccarat",
            "baccarat_desc": "Welcome to Baccarat! Bet on the player, banker, or a tie. The hand closest to 9 wins!",
            "baccarat_nextround": "Next Round: %s",
            "baccarat_dealing": "Dealer is now dealing cards...",
            "baccarat_displaycard": "Dealer is revealing the hidden card(s)...",
            "baccarat_suited": "Suited Pair",
            "baccarat_suited_desc1": "Single 20:1",
            "baccarat_suited_desc2": "Double 200:1",
            "baccarat_bankerpair": "Banker Pair",
            "baccarat_bankerpair_desc": "11:1",
            "baccarat_playerpair": "Player Pair",
            "baccarat_playerpair_desc": "11:1",
            "baccarat_eitherpair": "Either Pair",
            "baccarat_eitherpair_desc": "5:1",
            "baccarat_player": "Player",
            "baccarat_player_desc": "1:1",
            "baccarat_banker": "Banker",
            "baccarat_banker_desc": "0.95:1",
            "baccarat_tie": "Tie",
            "baccarat_tie_desc": "8:1",
            "baccarat_win_player": "Player Wins!",
            "baccarat_win_banker": "Banker Wins!",
            "baccarat_win_tie": "It's a Tie!",
            "wheel_desc": "Choose numbers and bonuses to bet on!",
            "wheel_title": "Wheel",
            "wheel_nextround": "Next Round: %s",
            "wheel_spinning": "The wheel is spinning, good luck!",
            "wheel_sectionwinner": "The winning section is:",
            "poker_title": "Poker",
            "poker_nextround": "Next Round: %s",
            "poker_bet": "Bet",
            "poker_raise": "Raise",
            "poker_call": "Call",
            "poker_check": "Check",
            "poker_fold": "Fold",
            "poker_all": "All-In",
            "poker_back": "Back",
            "poker_blind_small": "SB",
            "poker_blind_big": "BB",
            "horseracing_title": "Horse Racing",
            "horseracing_desc": "Place your bets and watch the race unfold!",
            "horseracing_changetrack": "Change Track",
            "horseracing_ext_waiting": "Race Intermission",
            "horseracing_ext_racing": "Racing",
            "horseracing_selecttrack": "Select Track",
            "horseracing_nextround": "Next Round: %s",
            "slot_title": "Slot Machine",
        },
        gameSettings: {}
    });
    useNuiEvent('setConfig', (data) => {
        setConfig({ ...config, ...data.config });
    });
    return (
        <ConfigContext.Provider value={{ config, setConfig }}>
            {children}
        </ConfigContext.Provider>
    );
};

export const useConfig = (): ConfigContextProps => {
    const context = useContext(ConfigContext);
    if (!context) {
        throw new Error('useConfig must be used within a ConfigProvider');
    }
    return context;
};