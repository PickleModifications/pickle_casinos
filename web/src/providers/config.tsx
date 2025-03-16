import React, { createContext, useContext, useState, ReactNode } from 'react';
import { useNuiEvent } from './nui/useNui';
import { Chip } from '@/components/casino/Casino';

export type Config = {
    identifier: string;
    locale?: Record<string, string>;
    countryCode?: string;
    currency?: string;
    chips?: Chip[];
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
        ],
        locale: {
            "casino_money": "Balance: %s",
            "casino_betrange": "Limit: %s - %s",
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
        },
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