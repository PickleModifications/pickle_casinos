import { useEffect, useRef, useState } from "react"
import Chart from 'chart.js/auto';
import { DisplayCurrency, GetCurrencyString } from "../casino/Casino";
import { useConfig } from "@/providers/config";
import { Button } from "../ui/button";
import { Translate } from "@/providers/locale/Locale";
import { Settings } from "lucide-react";
import { useNuiEvent } from "@/providers/nui/useNui";
import { fetchNui } from "@/providers/nui/fetchNui";

const DEFAULT_CASINO_BALANCE = {
    money: 0,
    dirty_money: 1110,
}

type CasinoBalance = {
    money: number;
    dirty_money: number;
}

type CasinoTransaction = {
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
                {transactions.map((transaction, index) => (
                    <div key={index} className="gap-2">
                        <div className="flex flex-row justify-between items-center w-full">
                            <div className="text-sm font-bold">{transaction.origin.name}</div>
                            <div className="text-sm font-bold"><DisplayCurrency value={transaction.amount * (transaction.type.includes("withdraw") ? -1 : 1)} /></div>
                        </div>
                        <div className="flex flex-row justify-between items-center w-full">
                        <div className="text-xs text-muted-foreground">{new Date(transaction.datetime * 1000).toLocaleString()}</div>
                        <div className="text-xs text-muted-foreground"><Translate id={"casino_manage_" + transaction.type}/></div>
                        </div>
                    </div>
                ))}
            </div>
        </div>
    )
}

function DisplaySettings({casinoId, settings} : {casinoId: number, settings: CasinoSettings}) {
    const {config} = useConfig();
    const [settingsState, setSettingsState] = useState<CasinoSettings>(settings);
    const settingsConfig = [
        {variable: "moneyExchangeRate", type: "range", min: 1, max: 100, default: 100, step: 1},
        {variable: "dirtyExchangeRate", type: "range", min: 1, max: 100, default: 75, step: 1},
        {variable: "vipPrice", type: "priceRange", min: (config.maxVipPrice || 1000000) / 100, max: (config.maxVipPrice || 1000000), default: (config.maxVipPrice || 1000000) / 100, step: (config.maxVipPrice || 1000000) / 100},
        {variable: "isOpen", type: "checkbox", default: true},
    ]
    useEffect(() => {
        const newSettings: CasinoSettings = {};
        settingsConfig.forEach((setting) => {
            newSettings[setting.variable] = settingsState[setting.variable] != undefined ? settingsState[setting.variable] : setting.default;
        });
        setSettingsState(newSettings);
    }, [settings]);
    useNuiEvent("updateCasinoSetting", (data: any) => {
        if (data.casinoId !== casinoId) return;
        setSettingsState((prevState) => ({
            ...prevState,
            [data.variable]: data.value,
        }));
    })
    return (
        <div className="flex flex-col gap-2 h-full overflow-y-auto p-2">
            {settingsConfig.map((setting, settingIndex) => (
                <div key={settingIndex} className="flex flex-row justify-between items-center w-full">
                    {setting.type.toLowerCase().includes("range") && (
                        <div className="flex flex-col gap-1 w-full">
                        <div className="flex flex-col">
                            <div className="flex flex-row w-full justify-between items-center">
                                <div className="text-sm font-bold"><Translate id={"casino_manage_" + setting.variable}/></div>
                                <div className="text-sm font-bold">
                                    {setting.type == "range" && (settingsState[setting.variable] + "%")}
                                    {setting.type == "priceRange" && <DisplayCurrency value={settingsState[setting.variable]} />}
                                </div>
                            </div>
                            <div className="text-xs text-zinc-400"><Translate id={"casino_manage_" + setting.variable + "_desc"}/></div>
                        </div>
                        {(setting.type === "range" || setting.type === "priceRange") && (
                            <div className="flex flex-row w-full">
                                <input className="w-full" type="range" min={setting.min} max={setting.max} step={setting.step} value={settingsState[setting.variable]} onMouseUp={() => {
                                    fetchNui("updateCasinoSetting", {
                                        casinoId: casinoId,
                                        variable: setting.variable,
                                        value: settingsState[setting.variable],
                                    })
                                }} onChange={(e) => {
                                    const newValue = parseInt(e.target.value);
                                    setSettingsState((prevState) => ({
                                        ...prevState,
                                        [setting.variable]: newValue,
                                    }));
                                }} />
                            </div>
                        )}
                        </div>
                    )}
                    {setting.type.toLowerCase().includes("checkbox") && (
                        <>
                            <div className="text-md font-bold"><Translate id={"casino_manage_" + setting.variable}/></div>
                            <input type="checkbox" className="bg-secondary/50 text-sm text-right text-zinc-400 rounded-md px-2 py-1" checked={settingsState[setting.variable]} onChange={(e) => {
                                setSettingsState((prevState) => ({
                                    ...prevState,
                                    [setting.variable]: e.target.checked,
                                }));
                                fetchNui("updateCasinoSetting", {
                                    casinoId: casinoId,
                                    variable: setting.variable,
                                    value: e.target.checked ? true : false,
                                })
                            }} />
                        </>
                    )}
                </div>
            ))}
            <Button variant={"default"} className="w-full" onClick={() => {
                fetchNui("openCasinoEditor", {
                    casinoId: casinoId,
                });
            }}>
                <Settings size={16} /> 
                <Translate id={"casino_manage_editor"}/>
            </Button>
        </div>
    )
}

function GetWeeklyProfit(transactions: CasinoTransaction[]) {
    let dayIndex = 0;
    let days = [];
    while (dayIndex < 7) {
        const startOfDay = new Date(new Date().setDate(new Date().getDate() - dayIndex)).setHours(0, 0, 0, 0);
        const endOfDay = new Date(new Date().setDate(new Date().getDate() - dayIndex)).setHours(23, 59, 59, 999);
        const dayTransactions = transactions.filter((transaction) => {
            return transaction.datetime >= startOfDay / 1000 && transaction.datetime <= endOfDay / 1000;
        });
        const dayProfit = dayTransactions.reduce((acc, transaction) => {
            if (transaction.type.includes("withdraw")) {
                return acc - transaction.amount;
            }
            else {
                return acc + transaction.amount;
            }
        }, 0);
        days.push(dayProfit);
        dayIndex += 1;
    }
    return days.reverse();
}

function GetWeeklyDate() {
    let dayIndex = 0;
    let days = [];
    while (dayIndex < 7) {
        const date = new Date(new Date().setDate(new Date().getDate() - dayIndex)).toLocaleDateString("en-US");
        days.push(date)
        dayIndex += 1;
    }
    return days.reverse();
}

type ManagementTransfer = {
    type: string,
    balanceType: "balance" | "marked_balance",
    amount: number,
}

function Management({info} : {info: any}) {
    const managementGraphRef = useRef<HTMLDivElement>(null);
    const {config} = useConfig();
    const [money, setMoney] = useState<number>(info.balance || 0);
    const [dirty_money, setDirtyMoney] = useState<number>(info.marked_balance || 0);
    const [settings, setSettings] = useState<CasinoSettings>(info.settings || {});
    const [transactions, setTransactions] = useState<CasinoTransaction[]>(info.transactions || []);
    const [transfer, setTransfer] = useState<ManagementTransfer | null>(null);
    //     {"origin": {"identifier": "steam:123456789", "name": "John Doe"}, "type": "deposit", "amount: "1000, "datetime": 1745353321},
    //     {id: 1, origin: {identifier: "steam:123456789", name: "John Doe"}, type: "deposit", amount: 1000, datetime: Date.now() - 1000000},
    //     {id: 2, origin: {identifier: "steam:123456789", name: "John Doe"}, type: "withdraw", amount: 500, datetime: Date.now() - 2000000},
    // ]);
    const [sidebarSection, setSidebarSection] = useState("transactions");
    const weeklyProfit = GetWeeklyProfit(transactions);
    const profit = weeklyProfit.reduce((acc, value) => acc + value, 0);
    const sidebarConfig = [
        {id: "transactions", label: <Translate id={"casino_manage_transactions"}/>},
        {id: "settings", label: <Translate id={"casino_manage_settings"}/>},
    ]
    const colors = {
        positive: "#05df72",
        negative: "#ff6467",
        neutral: "white",
    }
    useNuiEvent("updateCasinoBalance", (data: any) => {
        if (data.casinoId !== info.casinoId) return;
        setMoney(data.balance);
        setDirtyMoney(data.marked_balance);
    })
    useEffect(() => {
        if (managementGraphRef.current) {
            const ctx = document.createElement('canvas');
            managementGraphRef.current.innerHTML = ''; // Clear previous content
            managementGraphRef.current.appendChild(ctx);
            const chart = new Chart(ctx, {
                type: 'line',
                data: {
                    labels: GetWeeklyDate(),
                    datasets: [
                        {
                            data: weeklyProfit,
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
            {transfer && (
                <div className="absolute top-0 left-0 w-full h-full bg-background/50 flex flex-col items-center justify-center z-10">
                    <Card className="flex flex-col gap-2 items-center justify-center">
                        <div className="flex flex-row gap-2 items-center justify-between w-full">
                            <div className="text-sm font-bold whitespace-nowrap"><Translate id={"casino_manage_transfer_balancetype"}/></div>
                            <select value={transfer.balanceType} onChange={(e) => {
                                setTransfer((prevState: any) => ({
                                    ...prevState,
                                    balanceType: e.target.value,
                                }));
                            }} className="bg-background/50 rounded-md p-1 text-right">
                                <option value="balance"><Translate id={"casino_manage_balance"}/></option>
                                <option value="marked_balance"><Translate id={"casino_manage_markedbalance"}/></option>
                            </select>
                        </div>
                        <div className="flex flex-row gap-2 items-center justify-between w-full">
                            <div className="text-sm font-bold whitespace-nowrap"><Translate id={"casino_manage_transfer_type"}/></div>
                            <select value={transfer.type} onChange={(e) => {
                                setTransfer((prevState: any) => ({
                                    ...prevState,
                                    type: e.target.value,
                                }));
                            }} className="bg-background/50 rounded-md p-1 text-right">
                                <option value="withdraw"><Translate id={"casino_manage_transfer_withdraw"}/></option>
                                <option value="deposit"><Translate id={"casino_manage_transfer_deposit"}/></option>
                            </select>
                        </div>
                        <div className="flex flex-row gap-2 items-center justify-between w-full">
                            <div className="text-sm font-bold whitespace-nowrap"><Translate id={"casino_manage_transfer_amount"}/></div>
                            <input type="number" min={1} value={transfer.amount} onChange={(e) => {
                                setTransfer((prevState: any) => ({
                                    ...prevState,
                                    amount: parseInt(e.target.value),
                                }));
                            }} className="bg-background/50 rounded-md p-1 text-right" />
                        </div>
                        <Button className="w-full" variant={"default"} onClick={() => {
                            fetchNui("startCasinoTransfer", {
                                balanceType: transfer.balanceType,
                                type: transfer.type,
                                amount: transfer.amount,
                            });
                            setTransfer(null);
                        }}><Translate id={"casino_manage_transfer"}/></Button>
                        <Button className="w-full" variant={"destructive"} onClick={() => {
                            setTransfer(null);
                        }}><Translate id={"casino_manage_transfer_cancel"}/></Button>
                    </Card>
                </div>
            )}
            <div className="flex flex-col gap-2 relative p-2 h-full">
                <div className="grid grid-cols-2 gap-2 h-full">
                    <div className="flex flex-col gap-2">
                        <Card className="flex flex-col gap-2 items-center justify-center">
                            <div className="w-full">
                                <div className="flex flex-row gap-8 justify-between items-center w-full">
                                    <div className="text-md font-bold"><Translate id={"casino_manage_balance"}/></div>
                                    <div className="flex flex-row gap-2 items-center">
                                        <div className="text-md font-bold" style={{color: colors.positive}}><DisplayCurrency value={money} /></div>
                                    </div>
                                </div>
                                <div className="flex flex-row gap-8 justify-between items-center w-full">
                                    <div className="text-md font-bold"><Translate id={"casino_manage_markedbalance"}/></div>
                                    <div className="flex flex-row gap-2 items-center">
                                        <div className="text-md font-bold" style={{color: colors.negative}}><DisplayCurrency value={dirty_money} /></div>
                                    </div>
                                </div>
                            </div>
                            <Button className="w-full" size={"sm"} variant={"default"} onClick={() => {
                                setTransfer({type: "deposit", balanceType: "balance", amount: 0});
                            }}><Translate id={"casino_manage_transfer"}/></Button>
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
                            <DisplaySettings casinoId={info.casinoId} settings={settings} />
                        )}
                    </Card>
                </div>
            </div>
        </div>
    )
}

export default function ManagementDisplay() {
    const [managementInfo, setManagementInfo] = useState<any>(null);
    useNuiEvent("setManagementInfo", (data: any) => {
        setManagementInfo(data.info);
    })
    useEffect(() => {
        const handleKeyDown = (event: KeyboardEvent) => {
            if (!managementInfo) return;
            if (event.key === "Escape") {
                fetchNui("exitManagement", {});
            }
        };

        window.addEventListener("keydown", handleKeyDown);

        return () => {
            window.removeEventListener("keydown", handleKeyDown);
        };
    });
    return (
        <>
            {managementInfo && <Management info={managementInfo} />}
        </>
    )
}