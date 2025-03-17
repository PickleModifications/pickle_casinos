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
}

type RouletteComponentProps = {
    winningNumber: number,
    isPlaying: boolean,
    green: {
        wager: number,
        value: number,
        color: string
    },
    rows: {
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

export function IsSectionWinner(winningNumber: number, sectionIndex: number, index: number) {
    if (winningNumber == 0) return false;
    if (sectionIndex == 0 && index == 0) {
        return winningNumber >= 1 && winningNumber <= 12;
    }
    if (sectionIndex == 0 && index == 1) {
        return winningNumber >= 13 && winningNumber <= 24;
    }
    if (sectionIndex == 0 && index == 2) {
        return winningNumber >= 25 && winningNumber <= 36;
    }
    if (sectionIndex == 1 && index == 0) {
        return winningNumber >= 1 && winningNumber <= 18;
    }
    if (sectionIndex == 1 && index == 1) {
        return winningNumber % 2 == 0;
    }
    if (sectionIndex == 1 && index == 2) {
        return GetRouletteColor(winningNumber) == "red";
    }
    if (sectionIndex == 1 && index == 3) {
        return GetRouletteColor(winningNumber) == "black";
    }
    if (sectionIndex == 1 && index == 4) {
        return winningNumber % 2 != 0;
    }
    if (sectionIndex == 1 && index == 5) {
        return winningNumber >= 19 && winningNumber <= 36;
    }
    return false;
}

export function RouletteComponent({roulette} : {roulette: RouletteComponentProps}) {
    const { config } = useConfig();
    const green = roulette.green;
    const rows = roulette.rows;
    const sections = roulette.sections;
    const isPlaying = roulette.isPlaying;
    const chips = config.chips || [];
    const winningNumber = roulette.winningNumber != undefined ? roulette.winningNumber : -1;
    return (
        <div className="flex flex-col gap-2 items-center justify-center">
            <div className="flex flex-col gap-1 items-center">
                <div className="flex flex-row gap-1">
                    <div className="rounded-md border relative p-2" style={{
                        width: 50, 
                        height: 158,
                        backgroundColor: "green",
                        filter: (isPlaying && winningNumber != 0) ? "brightness(0.5)" : "unset",
                        cursor: (!isPlaying) ? "pointer" : "unset",
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
                        {winningNumber == 0 && (
                            <div className="scale-90 h-full" style={{ transformOrigin: "center" }}><ReactSparkle count={100}/></div>
                        )}
                    </div>
                    <div className="flex relative flex-col gap-1">
                        {rows.map((row, rowIndex) => (
                            <div className="flex flex-row gap-1 items-center" key={rowIndex}>
                                {row.map((value, index) => (index < row.length - 1) && (
                                    <div className="rounded-md border relative p-2" style={{
                                        width: 50, 
                                        height: 50,
                                        backgroundColor: value.color,
                                        filter: (isPlaying && winningNumber != value.value) ? "brightness(0.5)" : "unset",
                                        cursor: (!isPlaying) ? "pointer" : "unset",
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
                                        {(value.value == winningNumber) && (
                                            <div className="scale-90 h-full" style={{ transformOrigin: "center" }}><ReactSparkle/></div>
                                        )}
                                    </div>
                                ))}
                                <div className="rounded-md border relative p-2 bg-background/95" style={{
                                    width: 30, 
                                    height: 50,
                                    cursor: (!isPlaying) ? "pointer" : "unset",
                                    filter: (isPlaying) ? "brightness(0.5)" : "unset",
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
                            <div className="rounded-md border relative p-2 bg-background/95" style={{
                                width: "100%", 
                                height: 40,
                                backgroundColor: value?.backgroundColor || "unset",
                                filter: (isPlaying && !IsSectionWinner(winningNumber, sectionIndex, index)) ? "brightness(0.5)" : "unset",
                                cursor: (!isPlaying) ? "pointer" : "unset",
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
                                {IsSectionWinner(winningNumber, sectionIndex, index) && (
                                    <div className="scale-90 h-full" style={{ transformOrigin: "center" }}><ReactSparkle/></div>
                                )}
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
    const [performingAction, setPerformingAction] = useState<boolean>(false);
    const [green, setGreen] = useState({
        wager: 0,
        value: 0,
        color: "green",
    });
    const [rows, setRows] = useState(GetDefaultRouletteRows());
    const [sections, setSections] = useState(GetDefaultRouletteSections());
    const winningNumber = stage.winningNumber != undefined ? stage.winningNumber : -1;
    const [lastNumbers, setLastNumbers] = useState<number[]>([24, 1, 0, 11, 8, 24, 1, 0, 11, 8]);
    useNuiEvent("updateMoney", (data) => {
        setMoney(data.money);
    });
    useNuiEvent("updateRouletteStage", (data) => {
        setStage(data.stage);
        setPerformingAction(false);
    });
    useNuiEvent("updateRouletteSeats", (data) => {
        setSeats(data.seats);
    });
    useNuiEvent("updateRouletteSeat", (data) => {
        setCurrentSeat(data.seatId);
    });
    return (
        <div className='flex flex-col bg-background/95 absolute w-full px-8 py-8' style={{ 
            height: "460px",
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
                        {lastNumbers.length > 0 && (
                            <div className="flex flex-row gap-2 items-center">
                                <div className="font-semibold text-xl text-zinc-400"><Translate id="roulette_lastnumbers" /></div>
                                <div className="flex flex-row gap-2 max-w-[475px] overflow-x-hidden">
                                    {lastNumbers.map((number, index) => (
                                        <div className="rounded-md border relative p-2 text-white" style={{
                                            width: 40, 
                                            height: 40,
                                            minWidth: 40,
                                            backgroundColor: GetRouletteColor(number),
                                        }} key={index}>
                                            <div className="absolute top-[50%] left-[50%] rounded-full z-1" style={{transform: "translate(-50%, -50%)"}}>
                                                <div className="font-bold text-xl">{number}</div>
                                            </div>
                                        </div>
                                    ))}
                                </div>
                            </div>
                        )}
                    </div>
                </div>
                <div className="flex flex-col gap-2 items-center w-[33.333333%] px-8">
                    <div className='font-bold text-xl text-zinc-400'>
                        {stage.type === "waiting" && <Translate id="roulette_nextround" args={[stage.time]} />}
                        {stage.type === "rolling" && <Translate id="roulette_rolling" />}
                        {stage.type === "winningNumber" && (
                            <div className="flex flex-row gap-2 items-center">
                                <Translate id="roulette_numberwinner" />
                                <div className="rounded-md border relative p-2 text-white" style={{
                                    width: 40, 
                                    height: 40,
                                    backgroundColor: GetRouletteColor(winningNumber),
                                }}>
                                    <div className="absolute top-[50%] left-[50%] rounded-full z-1" style={{transform: "translate(-50%, -50%)"}}>
                                        <div className="font-bold text-xl">{winningNumber}</div>
                                    </div>
                                    <div className="scale-90 h-full" style={{ transformOrigin: "center" }}><ReactSparkle/></div>
                                </div>
                            </div>
                            )
                        }
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
                        <RouletteComponent roulette={{
                            winningNumber: winningNumber,
                            isPlaying: true,
                            green: green,
                            rows: rows,
                            sections: sections,
                            onClick: (type, index, row) => {
                                if (performingAction) return;
                                setPerformingAction(true);
                                fetchNui("placeRouletteWager", {
                                    type: type,
                                    index: index,
                                    row: row,
                                });
                            }
                        }} />
                    )}
                </div>
                <div className="flex flex-col gap-2 w-[33.333333%]">
                    <div className="grid grid-cols-2 gap-2 w-full">
                        {seats.map((player, index) => {
                            return ((player.source ? (<div className="flex flex-row gap-2 justify-between items-center w-full border p-2 rounded-md" key={index}>
                                <div className="flex flex-col gap-2 w-full">
                                    <div className="flex flex-row gap-2 justify-between items-center">
                                        <div className='font-bold text-lg truncate'>{player.name}</div>
                                    </div>
                                    <div className="font-semibold text-md text-zinc-400"><AnimatedValue value={player.wager} /></div>
                                </div>
                            </div>) : (
                                <div className="flex flex-row gap-2 justify-center items-center w-full border p-2 rounded-md" key={index}>
                                    <div className="font-bold text-lg truncate text-zinc-600">Empty Seat</div>
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