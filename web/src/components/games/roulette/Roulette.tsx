import { AnimatedValue, Card, CardsDisplay, CasinoGame, ChipDisplay, DisplayCurrency, GameIcon, GetChipForValue, GetCurrencyString, WagerComponent } from "@/components/casino/Casino";
import { Button } from "@/components/ui/button";
import { useConfig } from "@/providers/config";
import { Translate } from "@/providers/locale/Locale";
import { fetchNui } from "@/providers/nui/fetchNui";
import { useNuiEvent } from "@/providers/nui/useNui";
import { useEffect, useState } from "react";
import ReactSparkle from "react-sparkle";

type RouletteStage = any;

type RouletteSeat = {
    source?: string | number;
    wager: number;
    name: string;
    currentHand: number;
    hands: Card[][];
}

type RouletteComponentProps = {
    green: {
        isWinner: boolean,
        wager: number,
        value: number,
        color: string
    },
    rows: {
        isWinner: boolean,
        wager: number,
        value: string | number,
        color: string
    }[][],
    sections: {
        wager: number,
        component: JSX.Element,
        backgroundColor?: string
    }[][],
    onClick: (type: "green" | "row" | "section", index: number, row?: number) => void
}

export function GetRouletteColor(number: number) {
    if (number == 0) {
        return "green";
    }
    const red = [1, 3, 5, 7, 9, 12, 14, 16, 18, 19, 21, 23, 25, 27, 30, 32, 34, 36];
    if (red.includes(number)) {
        return "red";
    }
    return "black";
}

export function GetDefaultRouletteRows() {
    let rows = [];
    for (let i=0; i <= 2; i++) {
        let isBlack = true;
        if (i == 0 || i == 2) {
            isBlack = false;
        }
        let row = [];
        for (let j=0; j <= 11; j++) {
            row.push({
                isWinner: (Math.random() > 0.5),
                wager: 0,
                value: (3 - i) + (j * 3),
                color: GetRouletteColor((3 - i) + (j * 3)),
            });
            isBlack = !isBlack;
        }
        row.push({
            wager: 0,
            value: "2:1",
            color: "none",
            isWinner: false,
        });
        rows.push(row);
    }
    return rows;
}

export function GetDefaultRouletteSections() {
    return [
        [
            // 1st, 2nd, 3rd
            {wager: 0, component: <div className="font-bold text-xs"><Translate id="roulette_section_1"/></div>},
            {wager: 0, component: <div className="font-bold text-xs"><Translate id="roulette_section_2"/></div>},
            {wager: 0, component: <div className="font-bold text-xs"><Translate id="roulette_section_3"/></div>},
        ],
        [
            // 1-18
            {wager: 0, component: <div className="font-bold text-xs"><Translate id="roulette_section_4"/></div>},
            // Even
            {wager: 0, component: <div className="font-bold text-xs"><Translate id="roulette_section_6"/></div>},
            // Red
            {wager: 0, backgroundColor: "red", component: (<></>)},
            // Black
            {wager: 0, backgroundColor: "black", component: (<></>)},
            // Odd
            {wager: 0, component: <div className="font-bold text-xs"><Translate id="roulette_section_7"/></div>},
            // 19-36
            {wager: 0, component: <div className="font-bold text-xs"><Translate id="roulette_section_5"/></div>},
        ]
    ];
}

export function RouletteComponent({roulette} : {roulette: RouletteComponentProps}) {
    const { config } = useConfig();
    const green = roulette.green;
    const rows = roulette.rows;
    const sections = roulette.sections;
    const chips = config.chips || [];
    return (
        <div className="flex flex-col gap-2 items-center justify-center">
            <div className="flex flex-col gap-1 items-center">
                <div className="flex flex-row gap-1">
                    <div className="rounded-md border relative p-2 cursor-pointer" style={{
                        width: 50, 
                        height: 158,
                        backgroundColor: "green",
                    }} onClick={() => {
                        roulette.onClick("green", 0);
                    }}>
                        {green.wager > 0 && (
                            <div className="absolute z-10 top-[50%] left-[50%] rounded-full z-1" style={{transform: "translate(-50%, -50%)"}}>
                                <ChipDisplay chip={GetChipForValue(green.wager, chips, true)} size={48} />
                            </div>
                        )}
                        <div className="absolute top-[50%] left-[50%] rounded-full z-1" style={{transform: "translate(-50%, -50%)"}}>
                            <div className="font-bold text-xl">{green.value}</div>
                        </div>
                        {!green.isWinner && (
                            <div className="scale-90 h-full" style={{ transformOrigin: "center" }}><ReactSparkle count={100}/></div>
                        )}
                    </div>
                    <div className="flex relative flex-col gap-1">
                        {rows.map((row, rowIndex) => (
                            <div className="flex flex-row gap-1 items-center" key={rowIndex}>
                                {row.map((value, index) => (index < row.length - 1) && (
                                    <div className="rounded-md border relative p-2 cursor-pointer" style={{
                                        width: 50, 
                                        height: 50,
                                        backgroundColor: value.color,
                                    }} key={index} onClick={() => {
                                        roulette.onClick("row", index, rowIndex);
                                    }}>
                                        {value.wager > 0 && (
                                            <div className="absolute z-10 top-[50%] left-[50%] rounded-full z-1" style={{transform: "translate(-50%, -50%)"}}>
                                                <ChipDisplay chip={GetChipForValue(value.wager, chips, true)} size={48} />
                                            </div>
                                        )}
                                        <div className="absolute top-[50%] left-[50%] rounded-full z-1" style={{transform: "translate(-50%, -50%)"}}>
                                            <div className="font-bold text-xl">{value.value}</div>
                                        </div>
                                        {value.isWinner && (
                                            <div className="scale-90 h-full" style={{ transformOrigin: "center" }}><ReactSparkle/></div>
                                        )}
                                    </div>
                                ))}
                                <div className="rounded-md border relative p-2 cursor-pointer bg-background/95" style={{
                                    width: 30, 
                                    height: 50,
                                }} key={rowIndex} onClick={() => {
                                    roulette.onClick("row", rows[rowIndex].length - 1, rowIndex);
                                }}>
                                    {rows[rowIndex][rows[rowIndex].length - 1].wager > 0 && (
                                        <div className="absolute z-10 top-[50%] left-[50%] rounded-full z-1" style={{transform: "translate(-50%, -50%)"}}>
                                            <ChipDisplay chip={GetChipForValue(rows[rowIndex][rows[rowIndex].length - 1].wager, chips, true)} size={48} />
                                        </div>
                                    )}
                                    <div className="absolute top-[50%] left-[50%] rounded-full z-1" style={{transform: "translate(-50%, -50%)"}}>
                                        <div className="font-bold text-xs rotate-[270deg]">2:1</div>
                                    </div>
                                </div>
                            </div>
                        ))}
                    </div>
                </div>
                {sections.map((section, sectionIndex) => (
                    <div className="flex flex-row justify-between items-center w-full" key={sectionIndex}>
                        {section.map((value, index) => (
                            <div className="rounded-md border relative p-2 cursor-pointer bg-background/95" style={{
                                width: "100%", 
                                height: 40,
                                backgroundColor: value?.backgroundColor || "unset",
                            }} key={index} onClick={() => {
                                roulette.onClick("section", index, sectionIndex);
                            }}>
                                {value.wager > 0 && (
                                    <div className="absolute z-10 top-[50%] left-[50%] rounded-full z-1" style={{transform: "translate(-50%, -50%)"}}>
                                        <ChipDisplay chip={GetChipForValue(value.wager, chips, true)} size={48} />
                                    </div>
                                )}
                                <div className="absolute top-[50%] left-[50%] rounded-full z-1" style={{
                                    transform: "translate(-50%, -50%)",
                                }}>
                                    {value.component}
                                </div>
                            </div>    
                        ))}
                    </div>
                ))}
            </div>
        </div>
    )
}

export default function Roulette({game} : {game: CasinoGame}) {
    const { config } = useConfig();
    const wagerLimit = game.data.wagerLimit
    const [money, setMoney] = useState<number>(game.data.money || 1000);
    const [currentSeat, setCurrentSeat] = useState<number>(game.data.seatId);
    const [seats, setSeats] = useState<RouletteSeat[]>(game.data.seats);
    const [stage, setStage] = useState<RouletteStage>(game.data.stage);
    const [turnTimeLeft, setTurnTimeLeft] = useState<number>(0);
    const [performingAction, setPerformingAction] = useState<boolean>(false);
    useEffect(() => {
        if (stage.type == "turn") {
            if (turnTimeLeft > 0) {
                const interval = setInterval(() => {
                    setTurnTimeLeft(turnTimeLeft - 1);
                }, 1000);
                return () => clearInterval(interval);
            }
        }
    }, [turnTimeLeft]);
    useNuiEvent("updateMoney", (data) => {
        setMoney(data.money);
    });
    useNuiEvent("updateRouletteStage", (data) => {
        setStage(data.stage);
        setPerformingAction(false);
        if (data.stage.type == "turn") {
            setTurnTimeLeft(data.stage.timeLeft);
        }
    });
    useNuiEvent("updateRouletteSeats", (data) => {
        setSeats(data.seats);
    });
    useNuiEvent("updateRouletteSeat", (data) => {
        setCurrentSeat(data.seatId);
    });
    const canPlayerPerformAction = (action: "hit" | "stand" | "double" | "split") => {
        if (stage.type !== "turn") return false;
        if (currentSeat !== stage.seatId) return false;
        let seat = seats[currentSeat];
        return true
    }
    const performAction = (action: "hit" | "stand" | "double" | "split") => {
        setPerformingAction(true);
        fetchNui("performRouletteAction", {
            action: action,
        });
    }
    return (
        <div className='flex flex-col bg-background/95 absolute w-full px-8 py-8' style={{ 
            bottom: 0, 
            left: '0', 
            transition: "opacity 0.25s ease-in-out",
        }}>
            <div className="flex justify-between h-full items-center justify-between items-center w-full select-none">
                <div className='flex flex-col gap-2 w-[33.333333%]'>
                    <div className="flex flex-col gap-2">
                        <div className='flex flex-row items-center justify-between gap-2'>
                            <div className='flex flex-row items-center gap-2'>
                                <GameIcon name='roulette' style={{fill: "yellow", width: 30, height: 30}} />
                                <div className='font-bold text-2xl'><Translate id="roulette_title" /></div>
                            </div>

                        </div>
                        <div className="font-semibold text-md text-zinc-400"><Translate id="roulette_desc" /></div>
                    </div>
                </div>
                <div className="flex flex-col gap-2 items-center w-[33.333333%] px-8">
                    <div className='font-bold text-md text-zinc-400'>
                        {stage.type === "waiting" && <Translate id="roulette_nextround" args={[stage.time]} />}
                        {stage.type === "dealing" && <Translate id="roulette_dealing" />}
                        {stage.type === "displayCard" && <Translate id="roulette_displaycard" />}
                        {stage.type === "turn" && (currentSeat == stage.seatId ? <Translate id="roulette_playerturn" args={[turnTimeLeft]} /> : <Translate id="roulette_otherturn" args={[stage.seatId]} />)}
                        {/* {stage.type === "results" && (
                            stage.seatResults[currentSeat].won > 0 ? (
                                <div className="text-green-400">
                                    <Translate id="roulette_won" args={[GetCurrencyString(stage.seatResults[currentSeat].won, config)]} />
                                </div>
                            ) : (
                                <div className="text-red-400">
                                    <Translate id="roulette_lost" />
                                </div>
                            )
                        )} */}
                    </div>
                    {stage.type === "waiting" ? (
                        <WagerComponent wagerType={"roulette"} betRange={wagerLimit} money={money} wager={0} setWager={(value) => {
                            fetchNui("setRouletteWager", {
                                wager: value
                            });
                        }} />
                    ) : (
                        <div className='flex flex-row items-center justify-between gap-2 border p-2 rounded-md w-full'>
                            <div className="flex flex-row gap-2 items-center">
                                <div className="font-bold text-lg">Dealer's Hand:</div>
                            </div>
                            {seats[0].hands[seats[0].currentHand].length > 0 ? <CardsDisplay cards={seats[0].hands[seats[0].currentHand]} stacked={false} direction="right" height={72} /> : <div style={{height: 72}}></div>}
                        </div>
                    )}
                </div>
                <div className="flex flex-col gap-2 w-[33.333333%]">
                    <div className="grid grid-cols-2 gap-2 w-full">
                        {seats.map((player, index) => {
                            return (index > 0 && (player.source ? (<div className="flex flex-row gap-2 justify-between items-center w-full border p-2 rounded-md" key={index}>
                                <div className="flex flex-col gap-2 w-full">
                                    <div className="flex flex-row gap-2 justify-between items-center">
                                        <div className='font-bold text-lg truncate' style={{
                                        maxWidth: 200 - (8 * (player.hands[player.currentHand].length - 1)),
                                        }}>{player.name}</div>
                                    </div>
                                    <div className="font-semibold text-md text-zinc-400"><AnimatedValue value={player.wager} /></div>
                                </div>
                                <div className="flex flex-row justify-end gap-2 items-center">
                                    <CardsDisplay cards={player.hands[player.currentHand]} height={48} direction="right" />
                                </div>
                            </div>) : (
                                <div className="flex flex-row gap-2 justify-center items-center w-full border p-2 rounded-md" key={index}>
                                    <div className="font-bold text-lg truncate text-zinc-600" style={{
                                        maxWidth: 200 - (8 * (player.hands[player.currentHand].length - 1)),
                                    }}>Empty Seat</div>
                                </div>
                            )
                        ))
                    })}
                    </div>
                </div>
            </div>
        </div>
    )
}