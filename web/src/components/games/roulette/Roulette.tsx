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
    connects: any[];
}

type RouletteComponentProps = {
    winningNumber: string,
    isPlaying: boolean,
    rows: {
        value: string | number,
        color: string
    }[][],
    sections: {
        wager: number,
        component: JSX.Element,
        backgroundColor?: string
    }[][],
    connects: {
        wager: number,
        numbers: string[],
        x: number,
        y: number,
        width?: number,
        height?: number,
    }[],
    onClick: (type: "row" | "section" | "connect", index: number, row?: number) => void
}

export function GetRouletteColor(number: string | number) {
    if (number == "0" || number == "00") {
        return "green";
    }
    const red = [1, 3, 5, 7, 9, 12, 14, 16, 18, 19, 21, 23, 25, 27, 30, 32, 34, 36];
    if (typeof number == "string" && red.includes(parseInt(number))) {
        return "red";
    }
    if (typeof number == "number" && red.includes(number)) {
        return "red";
    }
    return "black";
}

export function GetDefaultRouletteRows() {
    let rows = [
        [
            {value: "00", color: "green"},
            {value: "0", color: "green"},
        ]
    ];
    for (let i=0; i <= 2; i++) {
        let isBlack = true;
        if (i == 0 || i == 2) {
            isBlack = false;
        }
        let row = [];
        for (let j=0; j <= 11; j++) {
            row.push({
                value: ((3 - i) + (j * 3)).toString(),
                color: GetRouletteColor((3 - i) + (j * 3)),
            });
            isBlack = !isBlack;
        }
        row.push({
            value: "2:1",
            color: "none",
        });
        rows.push(row as any);
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

export function GetDefaultRouletteConnections() {
    let connects =  [
        // 2:1 Rows
        {
            wager: 0,
            numbers: ["3", "6", "9", "12", "15", "18", "21", "24", "27", "30", "33", "36"],
            x: -2000,
            y: 0,
            width: 0,
            height: 0,
        },
        {
            wager: 0,
            numbers: ["2", "5", "8", "11", "14", "17", "20", "23", "26", "29", "32", "35"],
            x: -2000,
            y: 0,
            width: 0,
            height: 0,
        },
        {
            wager: 0,
            numbers: ["1", "4", "7", "10", "13", "16", "19", "22", "25", "28", "31", "34"],
            x: -2000,
            y: 0,
            width: 0,
            height: 0,
        },
        // Section Row 1 (1-12, 13-24, 25-36)
        {
            wager: 0,
            numbers: ["1", "2", "3", "4", "5", "6", "7", "8", "9", "10", "11", "12"],
            x: -2000,
            y: 0,
            width: 0,
            height: 0,
        },
        {
            wager: 0,
            numbers: ["13", "14", "15", "16", "17", "18", "19", "20", "21", "22", "23", "24"],
            x: -2000,
            y: 0,
            width: 0,
            height: 0,
        },
        {
            wager: 0,
            numbers: ["25", "26", "27", "28", "29", "30", "31", "32", "33", "34", "35", "36"],
            x: -2000,
            y: 0,
            width: 0,
            height: 0,
        },
        // Section Row 2 (1-18, Even, Red, Black, Odd, 19-36)
        {
            wager: 0,
            numbers: ["1", "2", "3", "4", "5", "6", "7", "8", "9", "10", "11", "12", "13", "14", "15", "16", "17", "18"],
            x: -2000,
            y: 0,
            width: 0,
            height: 0,
        },
        {
            wager: 0,
            numbers: ["2", "4", "6", "8", "10", "12", "14", "16", "18", "20", "22", "24", "26", "28", "30", "32", "34", "36"],
            x: -2000,
            y: 0,
            width: 0,
            height: 0,
        },
        {
            wager: 0,
            numbers: ["1", "3", "5", "7", "9", "12", "14", "16", "18", "19", "21", "23", "25", "27", "30", "32", "34", "36"],
            x: -2000,
            y: 0,
            width: 0,
            height: 0,
        },
        {
            wager: 0,
            numbers: ["2", "4", "6", "8", "10", "11", "13", "15", "17", "20", "22", "24", "26", "28", "29", "31", "33", "35"],
            x: -2000,
            y: 0,
            width: 0,
            height: 0,
        },
        {
            wager: 0,
            numbers: ["1", "3", "5", "7", "9", "11", "13", "15", "17", "19", "21", "23", "25", "27", "29", "31", "33", "35"],
            x: -2000,
            y: 0,
            width: 0,
            height: 0,
        },
        {
            wager: 0,
            numbers: ["19", "20", "21", "22", "23", "24", "25", "26", "27", "28", "29", "30", "31", "32", "33", "34", "35", "36"],
            x: -2000,
            y: 0,
            width: 0,
            height: 0,
        },
        // 0's
        {
            wager: 0,
            numbers: ["0", "00"],
            x: 0,
            y: 50,
            width: 30,
            height: 5,
        },
        {
            wager: 0,
            numbers: ["00"],
            x: 0,
            y: 0,
            width: 26,
            height: 48,
        },
        {
            wager: 0,
            numbers: ["0"],
            x: 0,
            y: 57,
            width: 26,
            height: 48,
        },
    ];
    let numbers = [
        [
            ["3"],
            ["6"],
            ["9"],
            ["12"],
            ["15"],
            ["18"],
            ["21"],
            ["24"],
            ["27"],
            ["30"],
            ["33"],
            ["36"],
        ],
        [
            ["2"],
            ["5"],
            ["8"],
            ["11"],
            ["14"],
            ["17"],
            ["20"],
            ["23"],
            ["26"],
            ["29"],
            ["32"],
            ["35"],
        ],
        [
            ["1"],
            ["4"],
            ["7"],
            ["10"],
            ["13"],
            ["16"],
            ["19"],
            ["22"],
            ["25"],
            ["28"],
            ["31"],
            ["34"],
        ]
    ]
    for (let i=0; i < numbers.length; i++) {
        for (let j=0; j < numbers[i].length; j++) {
            connects.push({
                wager: 0,
                numbers: numbers[i][j],
                x: 32 + (j * 35),
                y: 3 + (i * 35),
                width: 30,
                height: 30,
            });
        }
    }
    let splits = [
        [
            ["00", "3"],
            ["3", "6"],
            ["6", "9"],
            ["9", "12"],
            ["12", "15"],
            ["15", "18"],
            ["18", "21"],
            ["21", "24"],
            ["24", "27"],
            ["27", "30"],
            ["30", "33"],
            ["33", "36"],
        ],
        [
            ["00", "0", "2"],
            ["2", "5"],
            ["5", "8"],
            ["8", "11"],
            ["11", "14"],
            ["14", "17"],
            ["17", "20"],
            ["20", "23"],
            ["23", "26"],
            ["26", "29"],
            ["29", "32"],
            ["32", "35"],
        ],
        [
            ["0", "1"],
            ["1", "4"],
            ["4", "7"],
            ["7", "10"],
            ["10", "13"],
            ["13", "16"],
            ["16", "19"],
            ["19", "22"],
            ["22", "25"],
            ["25", "28"],
            ["28", "31"],
            ["31", "34"],
        ]
    ]
    for (let i=0; i < splits.length; i++) {
        for (let j=0; j < splits[i].length; j++) {
            connects.push({
                wager: 0,
                numbers: splits[i][j],
                x: 28 + (j * 35),
                y: 5 + (i * 35),
                width: 5,
                height: 25,
            });
        }
    }
    let verticalSplits = [
        [
            ["3", "2"],
            ["6", "5"],
            ["9", "8"],
            ["12", "11"],
            ["15", "14"],
            ["18", "17"],
            ["21", "20"],
            ["24", "23"],
            ["27", "26"],
            ["30", "29"],
            ["33", "32"],
            ["36", "35"],
        ],
        [
            ["2", "1"],
            ["5", "4"],
            ["8", "7"],
            ["11", "10"],
            ["14", "13"],
            ["17", "16"],
            ["20", "19"],
            ["23", "22"],
            ["26", "25"],
            ["29", "28"],
            ["32", "31"],
            ["35", "34"],
        ],
        [
            ["1", "2", "3"],
            ["4", "5", "6"],
            ["7", "8", "9"],
            ["10", "11", "12"],
            ["13", "14", "15"],
            ["16", "17", "18"],
            ["19", "20", "21"],
            ["22", "23", "24"],
            ["25", "26", "27"],
            ["28", "29", "30"],
            ["31", "32", "33"],
            ["34", "35", "36"],
        ]
    ]
    for (let i=0; i < verticalSplits.length; i++) {
        for (let j=0; j < verticalSplits[i].length; j++) {
            connects.push({
                wager: 0,
                numbers: verticalSplits[i][j],
                x: 34 + (j * 35),
                y: 34 + (i * 35),
                width: 28,
                height: 5,
            });
        }
    }
    let intersections = [
        [
            ["00", "3", "2"],
            ["3", "6", "5", "2"],
            ["6", "9", "8", "5"],
            ["9", "12", "11", "8"],
            ["12", "15", "14", "11"],
            ["15", "18", "17", "14"],
            ["18", "21", "20", "17"],
            ["21", "24", "23", "20"],
            ["24", "27", "26", "23"],
            ["27", "30", "29", "26"],
            ["30", "33", "32", "29"],
            ["33", "36", "35", "32"],
        ],
        [
            ["0", "2", "1"],
            ["2", "5", "4", "1"],
            ["5", "8", "7", "4"],
            ["8", "11", "10", "7"],
            ["11", "14", "13", "10"],
            ["14", "17", "16", "13"],
            ["17", "20", "19", "16"],
            ["20", "23", "22", "19"],
            ["23", "26", "25", "22"],
            ["26", "29", "28", "25"],
            ["29", "32", "31", "28"],
            ["32", "35", "34", "31"],
        ],
        [
            ["0", "00", "3", "2", "1"],
            ["1", "2", "3", "6", "5", "4"],
            ["4", "5", "6", "9", "8", "7"],
            ["7", "8", "9", "12", "11", "10"],
            ["10", "11", "12", "15", "14", "13"],
            ["13", "14", "15", "18", "17", "16"],
            ["16", "17", "18", "21", "20", "19"],
            ["19", "20", "21", "24", "23", "22"],
            ["22", "23", "24", "27", "26", "25"],
            ["25", "26", "27", "30", "29", "28"],
            ["28", "29", "30", "33", "32", "31"],
            ["31", "32", "33", "36", "35", "34"],
        ]
    ]
    for (let i=0; i < intersections.length; i++) {
        for (let j=0; j < intersections[i].length; j++) {
            connects.push({
                wager: 0,
                numbers: intersections[i][j],
                x: 28 + (j * 35),
                y: 33 + (i * 35),
                width: 5,
                height: 5,
            });
        }
    }
    return connects;
}

export function IsConnectWinner(winningNumber: string, connectIndex: number) {
    const connect = GetDefaultRouletteConnections()[connectIndex];
    return connect.numbers.includes(winningNumber);
}

export function RouletteComponent({roulette} : {roulette: RouletteComponentProps}) {
    const { config } = useConfig();
    const rows = GetDefaultRouletteRows();
    const sections = GetDefaultRouletteSections();
    const connects = roulette.connects || [];
    const isPlaying = roulette.isPlaying;
    const chips = config.chips || [];
    const winningNumber = roulette.winningNumber != undefined ? roulette.winningNumber : "-1";
    const [hoveringNumbers, setHoveringNumbers] = useState<any[]>([]);
    const sectionOffset = 3;
    return (
        <div className="flex flex-col gap-2 items-center justify-center">
            <div className="flex flex-col gap-1 items-center">
                <div className="flex flex-row relative">
                    <div className="flex flex-col items-center">
                        {rows[0].map((value, index) => (
                            <div className="rounded-md border relative p-2" style={{
                                width: 30, 
                                height: "100%",
                                backgroundColor: value.color,
                                filter: ((isPlaying && winningNumber != value.value) || (!isPlaying && hoveringNumbers.includes(value.value.toString()))) ? "brightness(0.5)" : "unset",
                                cursor: (!isPlaying) ? "pointer" : "unset",
                            }} onMouseEnter={() => {
                                setHoveringNumbers([value.value.toString()]);
                            }} onMouseLeave={() => {
                                setHoveringNumbers([]);
                            }} key={index} onClick={() => {
                                roulette.onClick("row", index, 0);
                            }}>
                                <div className="absolute top-[50%] left-[50%] rounded-full z-1" style={{transform: "translate(-50%, -50%)"}}>
                                    <div className="font-bold text-lg rotate-90">{value.value}</div>
                                </div>
                                {(value.value == winningNumber) && (
                                    <div className="scale-90 h-full" style={{ transformOrigin: "center" }}><ReactSparkle/></div>
                                )}
                            </div>
                        ))}
                    </div>
                    <div className="flex relative flex-col">
                        {rows.map((row, rowIndex) => (rowIndex > 0) && (
                            <div className="flex flex-row items-center" key={rowIndex}>
                                {row.map((value, index) => {
                                    return (index < row.length - 1) && (
                                        <div className="rounded-md border relative p-2" style={{
                                            width: 35, 
                                            height: 35,
                                            backgroundColor: value.color,
                                            filter: ((isPlaying && winningNumber != value.value) || hoveringNumbers.includes(value.value.toString()) ) ? "brightness(0.5)" : "unset",
                                        }} key={index} onMouseEnter={() => {
                                            setHoveringNumbers([value.value.toString()]);
                                        }} onMouseLeave={() => {
                                            setHoveringNumbers([]);
                                        }}>
                                            <div className="absolute top-[50%] left-[50%] rounded-full z-1" style={{transform: "translate(-50%, -50%)"}}>
                                                <div className="font-bold text-md">{value.value}</div>
                                            </div>
                                            {(value.value == winningNumber) && (
                                                <div className="scale-90 h-full" style={{ transformOrigin: "center" }}><ReactSparkle/></div>
                                            )}
                                        </div>
                                    )
                                })}
                                <div className="rounded-md border relative p-2 bg-background/95" style={{
                                    width: 30, 
                                    height: 35,
                                    cursor: (!isPlaying) ? "pointer" : "unset",
                                    filter: (isPlaying && !IsConnectWinner(winningNumber, rowIndex - 1)) ? "brightness(0.5)" : "unset",
                                }} key={rowIndex} onClick={() => {
                                    roulette.onClick("connect", rowIndex - 1);
                                }}>
                                    <div className="absolute top-[50%] left-[50%] rounded-full z-1" style={{transform: "translate(-50%, -50%)"}}>
                                        <div className="font-bold text-xs rotate-[270deg]">2:1</div>
                                    </div>
                                    <div className="absolute pointer-events-none top-[50%] left-[50%] z-10" style={{transform: "translate(-50%, -50%)"}}>
                                        {connects[rowIndex - 1].wager > 0 && (
                                            <div className="p-2 rounded-full shadow-lg" style={{
                                                zIndex: connects[rowIndex - 1].numbers.length == 1 ? 10 : 20
                                            }}>
                                                <ChipDisplay chip={GetChipForValue(connects[rowIndex - 1].wager, chips, true)} size={30} />
                                            </div>
                                        )}
                                    </div>
                                    {(IsConnectWinner(winningNumber, rowIndex - 1)) && (
                                        <div className="scale-90 h-full" style={{ transformOrigin: "center" }}><ReactSparkle/></div>
                                    )}
                                </div>
                            </div>
                        ))}
                    </div>
                    {connects.map((connect, index) => (connect.x >= 0) && (
                        <div className="absolute cursor-pointer" style={{
                            top: connect.y,
                            left: connect.x,
                            width: connect.width || 2,
                            height: connect.height || 2
                        }} onClick={() => {
                            roulette.onClick("connect", index);
                        }} onMouseEnter={() => {
                            setHoveringNumbers(connect.numbers);
                        }
                        } onMouseLeave={() => {
                            setHoveringNumbers([]);
                        }} key={index}>
                            <div className="absolute pointer-events-none top-[50%] left-[50%] z-10" style={{transform: "translate(-50%, -50%)"}}>
                                {connect.wager > 0 && (
                                    <div className="p-2 rounded-full shadow-lg" style={{
                                        zIndex: connect.numbers.length == 1 ? 10 : 20
                                    }}>
                                        <ChipDisplay chip={GetChipForValue(connect.wager, chips, true)} size={30} />
                                    </div>
                                )}
                            </div>
                        </div>
                    ))}
                </div>
                {sections.map((section, sectionIndex) => (
                    <div className="flex flex-row justify-between items-center w-full" key={sectionIndex}>
                        {section.map((value, index) => (
                            <div className="flex items-center justify-center rounded-md border relative py-2 bg-background/95" style={{
                                width: "100%", 
                                height: 30,
                                backgroundColor: value?.backgroundColor || "unset",
                                filter: (isPlaying && !IsConnectWinner(winningNumber, ((index) + 3) + (sectionIndex * 3))) ? "brightness(0.5)" : "unset",
                                cursor: (!isPlaying) ? "pointer" : "unset",
                            }} key={index} onMouseEnter={() => {
                                const sectionData = connects[((index) + 3) + (sectionIndex * 3)];
                                setHoveringNumbers(sectionData.numbers);
                            }} onMouseLeave={() => {
                                setHoveringNumbers([]);
                            }} onClick={() => {
                                roulette.onClick("connect", ((index) + 3) + (sectionIndex * 3));
                            }}>
                                <div className="absolute top-[50%] left-[50%] w-full rounded-full z-1" style={{transform: "translate(-50%, -50%)"}}>
                                    <div className="font-bold text-xs text-nowrap text-center">{value.component}</div>
                                </div>
                                <div className="absolute pointer-events-none top-[50%] left-[50%] z-10" style={{transform: "translate(-50%, -50%)"}}>
                                    {connects[((index) + 3) + (sectionIndex * 3)].wager > 0 && (
                                        <div className="p-2 rounded-full shadow-lg" style={{
                                            zIndex: connects[((index) + 3) + (sectionIndex * 3)].numbers.length == 1 ? 10 : 20
                                        }}>
                                            <ChipDisplay chip={GetChipForValue(connects[((index) + 3) + (sectionIndex * 3)].wager, chips, true)} size={30} />
                                        </div>
                                    )}
                                </div>
                                {(IsConnectWinner(winningNumber, ((index) + 3) + (sectionIndex * 3))) && (
                                    <div className="scale-90 w-full h-full" style={{ transformOrigin: "center" }}><ReactSparkle/></div>
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
    const [rows, setRows] = useState(GetDefaultRouletteRows());
    const [sections, setSections] = useState(GetDefaultRouletteSections());
    const [connects, setConnects] = useState(GetDefaultRouletteConnections());
    const winningNumber = stage.winningNumber != undefined ? stage.winningNumber : -1;
    const [lastNumbers, setLastNumbers] = useState<number[]>([24, 1, 0, 11, 8, 24, 1, 0, 11, 8]);
    useNuiEvent("updateRouletteWagers", (data) => {
        setConnects(data.data.connects);
    });
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
            bottom: 0, 
            left: '0', 
            transition: "opacity 0.25s ease-in-out",
        }}>
            <div className="flex justify-between h-full items-center justify-between items-center w-full select-none">
                <div className='flex flex-col gap-2 h-full w-[33.333333%]'>
                    <div className="flex flex-col gap-2">
                        <div className='flex flex-row items-center justify-between gap-2'>
                            <div className='flex flex-row items-center gap-2'>
                                <GameIcon name='roulette' style={{fill: "yellow", width: 30, height: 30}} />
                                <div className='font-bold text-2xl'><Translate id="roulette_title" /></div>
                            </div>
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
                            </div>
                        </div>
                        <div className="font-semibold text-md text-zinc-400"><Translate id="roulette_desc" /></div>
                        {lastNumbers.length > 0 && (
                            <div className="flex flex-row gap-2 items-center">
                                <div className="font-semibold text-xl text-zinc-400"><Translate id="roulette_lastnumbers" /></div>
                                <div className="flex flex-row gap-2 max-w-[500px] overflow-x-hidden">
                                    {lastNumbers.map((number, index) => (
                                        <div className="rounded-md border relative p-2 text-white" style={{
                                            width: 38, 
                                            height: 38,
                                            minWidth: 38,
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
                <div className="flex flex-col gap-2 h-full items-center w-[33.333333%] px-8">
                    {stage.type === "waiting" ? (
                        <WagerComponent wagerData={{
                            type: "roulette",
                            connects: connects,
                        }} betRange={wagerLimit} money={money} wager={0} setWager={(value, data) => {
                            fetchNui("updateRouletteWagers", {
                                wager: value,
                                data: data,
                            });
                        }} />
                    ) : (
                        <RouletteComponent roulette={{
                            winningNumber: winningNumber,
                            isPlaying: true,
                            rows: rows,
                            sections: sections,
                            connects: connects,
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
                <div className="flex flex-col gap-2 h-full items-end w-[33.333333%]">
                    <div className="grid grid-cols-2 gap-2 w-[80%]">
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