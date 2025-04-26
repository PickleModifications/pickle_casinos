import React, { createContext, useContext, useState, ReactNode } from 'react';
import { useNuiEvent } from './nui/useNui';
import { Chip } from '@/components/casino/Casino';
import { GameSettingsType } from '@/components/creator/Creator';

export type Config = {
    bonusWheelMultipliers: {
        id: string;
        multiplier: number;
    }[];
    maxVipPrice: number;
    identifier: string;
    locale?: Record<string, string>;
    countryCode?: string;
    currency?: string;
    chips?: Chip[];
    gameSettings?: GameSettingsType;
    templates: {label: string, value: string}[];
}

interface ConfigContextProps {
    config: Config;
    setConfig: (config: Config) => void;
}

const ConfigContext = createContext<ConfigContextProps | undefined>(undefined);

export const ConfigProvider: React.FC<{ children: ReactNode }> = ({ children }) => {
    const [config, setConfig] = useState<Config>({
        maxVipPrice: 1000000,
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
        gameSettings: {},
        templates: [],
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