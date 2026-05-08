import { AnimatedValue, CasinoGame, ChipDisplay, GameIcon, GetChipForValue, GetCurrencyString, WagerComponent } from "@/components/casino/Casino";
import { useConfig } from "@/providers/config";
import { Translate } from "@/providers/locale/Locale";
import { fetchNui } from "@/providers/nui/fetchNui";
import { useNuiEvent } from "@/providers/nui/useNui";
import { useState } from "react";
import ReactSparkle from "react-sparkle";
import {
    GetDefaultRouletteRows,
    GetDefaultRouletteSections,
    GetDefaultRouletteConnections,
    GetRouletteColor,
    IsConnectWinner,
} from "../roulette/Roulette";

type ThunderRouletteStage = any;

type ThunderRouletteSeat = {
    source?: string | number;
    wager: number;
    name: string;
    connects: any[];
}

type ThunderRouletteComponentProps = {
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
    thunder?: Record<string, number>,
    onClick: (type: "row" | "section" | "connect", index: number, row?: number) => void
}

// Highlight + multiplier badge for a single thunder cell. Rendered in the absolute
// overlay layer (after chip overlays) so the badge isn't covered by chips.
function ThunderCellOverlay({connect, multiplier}: {connect: {x: number, y: number, width?: number, height?: number}, multiplier: number}) {
    return (
        <div className="absolute pointer-events-none" style={{
            top: connect.y,
            left: connect.x,
            width: connect.width || 30,
            height: connect.height || 30,
            zIndex: 40,
        }}>
            <div className="absolute inset-0 rounded-md ring-2 ring-cyan-400 shadow-[0_0_12px_rgba(100,200,255,0.9)]" />
            <div className="absolute inset-0" style={{ transformOrigin: "center" }}>
                <ReactSparkle color="#A6E3FF" count={10} />
            </div>
            <div className="absolute text-[10px] leading-none font-extrabold px-1 py-[1px] rounded-sm bg-cyan-500 text-white border border-cyan-200 shadow-[0_0_6px_rgba(100,200,255,0.95)]" style={{
                top: 1,
                right: 1,
            }}>
                x{multiplier}
            </div>
        </div>
    )
}

export function ThunderRouletteComponent({roulette}: {roulette: ThunderRouletteComponentProps}) {
    const { config } = useConfig();
    const rows = GetDefaultRouletteRows();
    const sections = GetDefaultRouletteSections();
    const connects = roulette.connects || [];
    const isPlaying = roulette.isPlaying;
    const chips = config.chips || [];
    const winningNumber = roulette.winningNumber != undefined ? roulette.winningNumber : "-1";
    const thunder = roulette.thunder || {};
    const [hoveringNumbers, setHoveringNumbers] = useState<any[]>([]);
    return (
        <div className="flex flex-col gap-2 items-center justify-center">
            <div className="flex flex-col gap-1 items-center">
                <div className="flex flex-row relative">
                    <div className="flex flex-col items-center">
                        {rows[0].map((value, index) => {
                            const key = value.value.toString();
                            return (
                                <div className="rounded-md border relative p-2" style={{
                                    width: 30,
                                    height: "100%",
                                    backgroundColor: value.color,
                                    filter: ((isPlaying && winningNumber != value.value) || (!isPlaying && hoveringNumbers.includes(key))) ? "brightness(0.5)" : "unset",
                                    cursor: (!isPlaying) ? "pointer" : "unset",
                                }} onMouseEnter={() => {
                                    setHoveringNumbers([key]);
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
                            );
                        })}
                    </div>
                    <div className="flex relative flex-col">
                        {rows.map((row, rowIndex) => (rowIndex > 0) && (
                            <div className="flex flex-row items-center" key={rowIndex}>
                                {row.map((value, index) => {
                                    if (index >= row.length - 1) return null;
                                    const key = value.value.toString();
                                    return (
                                        <div className="rounded-md border relative p-2" style={{
                                            width: 35,
                                            height: 35,
                                            backgroundColor: value.color,
                                            filter: ((isPlaying && winningNumber != value.value) || hoveringNumbers.includes(key)) ? "brightness(0.5)" : "unset",
                                        }} key={index} onMouseEnter={() => {
                                            setHoveringNumbers([key]);
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
                                    );
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
                                        {connects[rowIndex - 1] && connects[rowIndex - 1].wager > 0 && (
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
                    {/* Thunder cell overlays — drawn AFTER chip overlays so the multiplier badge & glow sit above any placed chips.
                        Once the round resolves (winningNumber set), only the winning thunder number keeps its overlay. */}
                    {connects.map((connect, index) => {
                        if (connect.x < 0) return null;
                        if (connect.numbers.length !== 1) return null;
                        const number = connect.numbers[0];
                        const mult = thunder[number];
                        if (mult === undefined) return null;
                        const winningSet = winningNumber !== undefined && winningNumber !== "-1" && winningNumber !== -1;
                        if (winningSet && number != winningNumber) return null;
                        return <ThunderCellOverlay key={"thunder-" + index} connect={connect} multiplier={mult} />;
                    })}
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
                                if (sectionData) setHoveringNumbers(sectionData.numbers);
                            }} onMouseLeave={() => {
                                setHoveringNumbers([]);
                            }} onClick={() => {
                                roulette.onClick("connect", ((index) + 3) + (sectionIndex * 3));
                            }}>
                                <div className="absolute top-[50%] left-[50%] w-full rounded-full z-1" style={{transform: "translate(-50%, -50%)"}}>
                                    <div className="font-bold text-xs text-nowrap text-center">{value.component}</div>
                                </div>
                                <div className="absolute pointer-events-none top-[50%] left-[50%] z-10" style={{transform: "translate(-50%, -50%)"}}>
                                    {connects[((index) + 3) + (sectionIndex * 3)] && connects[((index) + 3) + (sectionIndex * 3)].wager > 0 && (
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

export default function ThunderRoulette({game}: {game: CasinoGame}) {
    const wagerLimit = game.data.wagerLimit
    const [money, setMoney] = useState<number>(game.data.money || 0);
    const [seats, setSeats] = useState<ThunderRouletteSeat[]>(game.data.seats);
    const [stage, setStage] = useState<ThunderRouletteStage>(game.data.stage);
    const [performingAction, setPerformingAction] = useState<boolean>(false);
    const [rows] = useState(GetDefaultRouletteRows());
    const [sections] = useState(GetDefaultRouletteSections());
    const [connects, setConnects] = useState(GetDefaultRouletteConnections());
    const winningNumber = stage.winningNumber != undefined ? stage.winningNumber : -1;
    const thunder: Record<string, number> = stage.thunder || {};
    const [lastNumbers, setLastNumbers] = useState<any[]>(game.data.history || []);
    useNuiEvent("updateThunderRouletteWagers", (data) => {
        setConnects(data.data.connects);
    });
    useNuiEvent("updateBalance", (data) => {
        setMoney(data.balance);
    });
    useNuiEvent("updateThunderRouletteStage", (data) => {
        setStage(data.stage);
        setPerformingAction(false);
    });
    useNuiEvent("updateThunderRouletteSeats", (data) => {
        setSeats(data.seats);
    });
    useNuiEvent("updateThunderRouletteHistory", (data) => {
        setLastNumbers(data.history);
    });
    return (
        <div className='flex flex-col bg-background/95 absolute w-full px-8 py-8' style={{
            bottom: 0,
            left: '0',
            transition: "opacity 0.25s ease-in-out",
        }}>
            <div className="flex justify-between h-full items-center w-full select-none">
                <div className='flex flex-col gap-2 h-full w-[33.333333%]'>
                    <div className="flex flex-col gap-2">
                        <div className='flex flex-row items-center gap-2'>
                            <GameIcon name='thunder_roulette' style={{fill: "#A6E3FF", width: 30, height: 30}} />
                            <div className='font-bold text-2xl whitespace-nowrap'><Translate id="thunder_roulette_title" /></div>
                        </div>
                        <div className='font-bold text-xl text-zinc-400 flex flex-row items-center flex-wrap gap-2'>
                            {stage.type === "waiting" && <span className="whitespace-nowrap"><Translate id="thunder_roulette_nextround" args={[stage.time]} /></span>}
                            {stage.type === "rolling" && <span className="whitespace-nowrap"><Translate id="thunder_roulette_rolling" /></span>}
                            {stage.type === "winningNumber" && (
                                <>
                                    <span className="whitespace-nowrap"><Translate id="thunder_roulette_numberwinner" /></span>
                                    <div className="rounded-md border relative p-2 text-white shrink-0" style={{
                                        width: 40,
                                        height: 40,
                                        backgroundColor: GetRouletteColor(winningNumber),
                                    }}>
                                        <div className="absolute top-[50%] left-[50%] rounded-full z-1" style={{transform: "translate(-50%, -50%)"}}>
                                            <div className="font-bold text-xl">{winningNumber}</div>
                                        </div>
                                        <div className="scale-90 h-full" style={{ transformOrigin: "center" }}><ReactSparkle/></div>
                                    </div>
                                    {thunder[winningNumber.toString()] !== undefined && (
                                        <div className="font-extrabold text-cyan-300 text-2xl drop-shadow-[0_0_8px_rgba(100,200,255,0.9)] whitespace-nowrap">
                                            <Translate id="thunder_roulette_struck" /> x{thunder[winningNumber.toString()]}
                                        </div>
                                    )}
                                </>
                            )}
                        </div>
                        <div className="font-semibold text-md text-zinc-400"><Translate id="thunder_roulette_desc" /></div>
                        {lastNumbers.length > 0 && (
                            <div className="flex flex-row gap-2 items-center">
                                <div className="font-semibold text-xl text-zinc-400"><Translate id="thunder_roulette_lastnumbers" /></div>
                                <div className="flex flex-row gap-2 max-w-[500px] overflow-x-hidden">
                                    {lastNumbers.map((entry, index) => {
                                        const number = (entry && typeof entry === "object" && entry.number !== undefined) ? entry.number : entry;
                                        const mult = (entry && typeof entry === "object") ? entry.multiplier : undefined;
                                        return (
                                            <div className="rounded-md border relative p-2 text-white" style={{
                                                width: 38,
                                                height: 38,
                                                minWidth: 38,
                                                backgroundColor: GetRouletteColor(number),
                                            }} key={index}>
                                                <div className="absolute top-[50%] left-[50%] rounded-full z-1" style={{transform: "translate(-50%, -50%)"}}>
                                                    <div className="font-bold text-xl">{number}</div>
                                                </div>
                                                {mult !== undefined && (
                                                    <div className="absolute -top-1 -right-1 text-[9px] font-extrabold px-1 rounded-sm bg-cyan-500 text-white border border-cyan-200">x{mult}</div>
                                                )}
                                            </div>
                                        );
                                    })}
                                </div>
                            </div>
                        )}
                    </div>
                </div>
                <div className="flex flex-col gap-2 h-full items-center w-[33.333333%] px-8">
                    {stage.type === "waiting" ? (
                        <WagerComponent wagerData={{
                            type: "thunder_roulette",
                            connects: connects,
                        }} betRange={wagerLimit} money={money} wager={0} setWager={(value, data) => {
                            fetchNui("updateThunderRouletteWagers", {
                                wager: value,
                                data: data,
                            });
                        }} />
                    ) : (
                        <ThunderRouletteComponent roulette={{
                            winningNumber: winningNumber,
                            isPlaying: true,
                            rows: rows,
                            sections: sections,
                            connects: connects,
                            thunder: thunder,
                            onClick: (type, index, row) => {
                                if (performingAction) return;
                                setPerformingAction(true);
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
                                    <div className="font-bold text-lg truncate text-zinc-600"><Translate id="empty_seat"/></div>
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
