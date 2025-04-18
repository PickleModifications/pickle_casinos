import { useEffect, useRef, useState } from "react"
import Chart from 'chart.js/auto';
import { DisplayCurrency, GetCurrencyString } from "../casino/Casino";
import { useConfig } from "@/providers/config";
import { Button } from "../ui/button";
import { Translate } from "@/providers/locale/Locale";
import { Settings } from "lucide-react";

const DEFAULT_CASINO_BALANCE = {
    money: 0,
    dirty_money: 1110,
}

type CasinoBalance = {
    money: number;
    dirty_money: number;
}

type CasinoTransaction = {
    id: number;
    origin: {
        identifier: string;
        name: string;
    },
    type: string;
    amount: number;
    datetime: number;
}

type CasinoSettings = {
    [key: string]: any;
}

function Card({className, children} : {className?: string, children?: React.ReactNode}) {
    return (
        <div className={`bg-secondary rounded-lg flex flex-col p-4 ${className}`}>
            {children}
        </div>
    )
}

function DisplayTransactions({transactions} : {transactions: CasinoTransaction[]}) {
    const {config} = useConfig();
    return (
        <div className="p-1 bg-background/50 max-h-[310px] relative rounded-lg">
            <div className="flex flex-col gap-2 h-full overflow-y-auto p-2">
                {transactions.map((transaction) => (
                    <div key={transaction.id} className="gap-2">
                        <div className="flex flex-row justify-between items-center w-full">
                            <div className="text-sm font-bold">{transaction.origin.name}</div>
                            <div className="text-sm font-bold"><DisplayCurrency value={transaction.amount} /></div>
                        </div>
                        <div className="flex flex-row justify-between items-center w-full">
                        <div className="text-xs text-muted-foreground">{new Date(transaction.datetime).toLocaleString()}</div>
                        <div className="text-xs text-muted-foreground"><Translate id={"casino_manage_" + transaction.type}/></div>
                        </div>
                    </div>
                ))}
            </div>
        </div>
    )
}

function DisplaySettings({settings} : {settings: CasinoSettings}) {
    const [settingsState, setSettingsState] = useState<CasinoSettings>(settings);
    const settingsConfig = [
        {variable: "moneyExchangeRate", type: "range", min: 1, max: 100, default: 100, step: 1},
        {variable: "dirtyExchangeRate", type: "range", min: 1, max: 100, default: 75, step: 1},
    ]
    useEffect(() => {
        const newSettings: CasinoSettings = {};
        settingsConfig.forEach((setting) => {
            newSettings[setting.variable] = settingsState[setting.variable] || setting.default;
        });
        setSettingsState(newSettings);
    }, [settings]);
    return (
        <div className="flex flex-col gap-2 h-full overflow-y-auto p-2">
            {settingsConfig.map((setting, settingIndex) => (
                <div key={settingIndex} className="flex flex-row justify-between items-center w-full">
                    <div className="flex flex-col gap-1 w-full">
                        <div className="flex flex-col">
                            <div className="flex flex-row w-full justify-between items-center">
                                <div className="text-sm font-bold"><Translate id={"casino_manage_" + setting.variable}/></div>
                                <div className="text-sm font-bold">{settingsState[setting.variable]}%</div>
                            </div>
                            <div className="text-xs text-zinc-400"><Translate id={"casino_manage_" + setting.variable + "_desc"}/></div>
                        </div>
                        {setting.type === "range" && (
                            <div className="flex flex-row w-full">
                                <input className="w-full" type="range" min={setting.min} max={setting.max} step={setting.step} value={settingsState[setting.variable]} onChange={(e) => {
                                    const newValue = parseInt(e.target.value);
                                    setSettingsState((prevState) => ({
                                        ...prevState,
                                        [setting.variable]: newValue,
                                    }));
                                }} />
                            </div>
                        )}
                    </div>
                </div>
            ))}
            <Button variant={"default"} className="w-full" onClick={() => {}}>
                <Settings size={16} /> 
                <Translate id={"casino_manage_editor"}/>
            </Button>
        </div>
    )
}

function Management() {
    const managementGraphRef = useRef<HTMLDivElement>(null);
    const {config} = useConfig();
    const [profit, setProfit] = useState(10100);
    const [balance, setBalance] = useState<CasinoBalance>(DEFAULT_CASINO_BALANCE);
    const [settings, setSettings] = useState<CasinoSettings>({});
    const [transactions, setTransactions] = useState<CasinoTransaction[]>([
        {id: 1, origin: {identifier: "steam:123456789", name: "John Doe"}, type: "deposit", amount: 1000, datetime: Date.now() - 1000000},
        {id: 1, origin: {identifier: "steam:123456789", name: "John Doe"}, type: "deposit", amount: 1000, datetime: Date.now() - 1000000},
        {id: 2, origin: {identifier: "steam:123456789", name: "John Doe"}, type: "withdraw", amount: 500, datetime: Date.now() - 2000000},
    ]);
    const [sidebarSection, setSidebarSection] = useState("transactions");
    const sidebarConfig = [
        {id: "transactions", label: <Translate id={"casino_manage_transactions"}/>},
        {id: "settings", label: <Translate id={"casino_manage_settings"}/>},
    ]
    const colors = {
        positive: "#05df72",
        negative: "#ff6467",
        neutral: "white",
    }
    useEffect(() => {
        if (managementGraphRef.current) {
            const ctx = document.createElement('canvas');
            managementGraphRef.current.innerHTML = ''; // Clear previous content
            managementGraphRef.current.appendChild(ctx);
            const chart = new Chart(ctx, {
                type: 'line',
                data: {
                    labels: ['01/01', '01/02', '01/03', '01/04', '01/05', '01/06'],
                    datasets: [
                        {
                            data: Array.from({ length: 6 }, () => Math.floor(Math.random() * 20000) - 10000),
                            pointBackgroundColor: profit > 0 ? colors.positive : profit < 0 ? colors.negative : colors.neutral,
                            borderColor: profit > 0 ? colors.positive : profit < 0 ? colors.negative : colors.neutral,
                            borderWidth: 1,
                        },
                    ],
                },
                options: {
                    responsive: true,
                    plugins: {
                        legend: {
                            display: false,
                        },
                        tooltip: {
                            boxPadding: 4,
                            multiKeyBackground: (profit > 0 ? colors.positive : profit < 0 ? colors.negative : colors.neutral),
                            callbacks: {
                                label: function(context) {
                                    return GetCurrencyString(context.raw as number, config);
                                }
                            }
                        }
                    },
                    scales: {
                        y: {
                            ticks: {
                                callback: function(value) {
                                    return GetCurrencyString(value as number, config);
                                }
                            }
                        },
                    },
                },
            });

            return () => {
                chart.destroy();
            };
        }
    }, [managementGraphRef]);
    return (
        <div className="absolute top-[50%] left-[50%] translate-x-[-50%] translate-y-[-50%] w-[800px]  bg-background/95">
            <div className="flex flex-col gap-2 relative p-2 h-full">
                <div className="grid grid-cols-2 gap-2 h-full">
                    <div className="flex flex-col gap-2">
                        <Card className="flex flex-col gap-2 items-center justify-center">
                            <div className="w-full">
                                <div className="flex flex-row gap-8 justify-between items-center w-full">
                                    <div className="text-md font-bold"><Translate id={"casino_manage_balance"}/></div>
                                    <div className="flex flex-row gap-2 items-center">
                                        <div className="text-md font-bold" style={{color: colors.positive}}><DisplayCurrency value={balance.money} /></div>
                                    </div>
                                </div>
                                <div className="flex flex-row gap-8 justify-between items-center w-full">
                                    <div className="text-md font-bold"><Translate id={"casino_manage_markedbalance"}/></div>
                                    <div className="flex flex-row gap-2 items-center">
                                        <div className="text-md font-bold" style={{color: colors.negative}}><DisplayCurrency value={balance.dirty_money} /></div>
                                    </div>
                                </div>
                            </div>
                            <Button className="w-full" size={"sm"} variant={"default"}><Translate id={"casino_manage_transfer"}/></Button>
                        </Card>
                        <Card className="gap-2 h-full">
                            <div className="flex flex-row justify-between items-center">
                                <div className="text-lg font-bold"><Translate id={"casino_manage_profit"}/></div>
                                <div className="text-lg font-bold" style={{
                                    color: (profit > 0 ? colors.positive : profit < 0 ? colors.negative : colors.neutral)
                                }}><DisplayCurrency value={profit} /></div>
                            </div>
                            <div ref={managementGraphRef}></div>
                        </Card>
                    </div>
                    <Card className="h-full">
                        <div className="flex flex-row items-center w-full gap-2 pb-2 justify-between">
                            {sidebarConfig.map((section) => (
                                <div className="flex flex-col items-center justify-center text-sm w-full font-semibold cursor-pointer gap-1" onClick={() => setSidebarSection(section.id)} key={section.id}>
                                    {section.label}
                                    {sidebarSection === section.id && (
                                        <div className="w-full border-b border-b-primary"/>
                                    )}
                                </div>
                            ))}
                        </div>
                        {sidebarSection === "transactions" && (
                            <DisplayTransactions transactions={transactions} />
                        )}
                        {sidebarSection === "settings" && (
                            <DisplaySettings settings={settings} />
                        )}
                    </Card>
                </div>
            </div>
        </div>
    )
}

export default function ManagementDisplay() {
    const [visible, setVisible] = useState(false)
    return (
        <>
            {visible && <Management />}
        </>
    )
}