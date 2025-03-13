import { useConfig } from "../config";
export function useLocale() {
    const { config } = useConfig();
    return (key: string, ...args: any) => {
        if (config.locale && config.locale[key]) {
            return config.locale[key].replace(/%s/g, function() {
                return args.shift();
            });
        }
        return key;
    };
}

export function Translate({id, args = []} : {id: string, args?: any[]}) {
    const locale = useLocale();
    return locale(id, ...(args || []));
}