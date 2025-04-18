import { useEffect, useRef, useState } from "react"
import Chart from 'chart.js/auto';
import { DisplayCurrency, GetCurrencyString } from "../casino/Casino";
import { useConfig } from "@/providers/config";
import { Button } from "../ui/button";

const DEFAULT_CASINO_BALANCE = {
    money: 0,
    dirty_money: 0,
}

type CasinoBalance = {
    money: number;
    dirty_money: number;
}

function Card({className, children} : {className?: string, children?: React.ReactNode}) {
    return (
        <div className={`bg-secondary rounded-lg flex flex-col p-4 ${className}`}>
            {children}
        </div>
    )
}

function Management() {
    const managementGraphRef = useRef<HTMLDivElement>(null);
    const {config} = useConfig();
    const [profit, setProfit] = useState(10100);
    const [balance, setBalance] = useState<CasinoBalance>(DEFAULT_CASINO_BALANCE);
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
        <div className="absolute top-[50%] left-[50%] translate-x-[-50%] translate-y-[-50%] w-[800px] h-[500px] bg-background/95 p-2">
            <div className="flex flex-col gap-2 relative">
                <Card>
                    <div className="flex flex-row gap-2 w-full justify-between items-center">
                        <div className="flex flex-row gap-8 justify-between items-center">
                            <div className="text-lg font-bold">Cash Balance:</div>
                            <div className="flex flex-row gap-2 items-center">
                                <div className="text-md font-bold" style={{color: colors.positive}}><DisplayCurrency value={balance.money} /></div>
                                <Button variant={"default"}>Transfer</Button>
                            </div>
                        </div>
                        <div className="flex flex-row gap-8 justify-between items-center">
                            <div className="text-lg font-bold">Dirty Balance:</div>
                            <div className="flex flex-row gap-2 items-center">
                                <div className="text-md font-bold" style={{color: colors.negative}}><DisplayCurrency value={balance.dirty_money} /></div>
                                <Button variant={"default"}>Transfer</Button>
                            </div>
                        </div>
                    </div>
                </Card>
                <div className="grid grid-cols-2 gap-2">
                    <Card className="gap-2">
                        <div className="flex flex-row justify-between items-center">
                            <div className="text-lg font-bold">Weekly Profit</div>
                            <div className="text-lg font-bold" style={{
                                color: (profit > 0 ? colors.positive : profit < 0 ? colors.negative : colors.neutral)
                            }}><DisplayCurrency value={profit} /></div>
                        </div>
                        <div ref={managementGraphRef}></div>
                    </Card>
                    <Card></Card>
                </div>
            </div>
        </div>
    )
}

export default function ManagementDisplay() {
    const [visible, setVisible] = useState(true)
    return (
        <>
            {visible && <Management />}
        </>
    )
}