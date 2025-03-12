import React, { createContext, useContext, useState, ReactNode } from 'react';
import { useNuiEvent } from './nui/useNui';

export type Config = {
    identifier: string;
}

interface ConfigContextProps {
    config: Config;
    setConfig: (config: Config) => void;
}

const ConfigContext = createContext<ConfigContextProps | undefined>(undefined);

export const ConfigProvider: React.FC<{ children: ReactNode }> = ({ children }) => {
    const [config, setConfig] = useState<Config>({
        identifier: "ERR_NO_IDENTIFIER",
    });
    useNuiEvent('setConfig', (data) => {
        setConfig(data.config);
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