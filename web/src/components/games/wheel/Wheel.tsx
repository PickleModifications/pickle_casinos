import { CasinoGame, ChipDisplay, GameIcon, GetChipForValue, playAudio, WagerControls } from "@/components/casino/Casino";
import { useConfig } from "@/providers/config";
import { Translate } from "@/providers/locale/Locale";
import { fetchNui } from "@/providers/nui/fetchNui";
import { useEffect, useState } from "react";
import BonusWheel from "./BonusWheel";
import ReactSparkle from "react-sparkle";
import { useNuiEvent } from "@/providers/nui/useNui";

type WheelStage = any;
type WheelWager = {
    two: number;
    three: number;
    five: number;
    eleven: number;
    twentyThree: number;
    bonus: number;
}

function CalculateWheelWagers(wheelWagers: WheelWager) {
    let total = 0;
    Object.keys(wheelWagers).forEach((key) => {
        total += wheelWagers[key as keyof WheelWager] || 0;
    });
    return total;
}

function WheelNumber({numberKey, style}: {numberKey: string, style: "selection" | "history"}) {
    const numbers = {
        two: {
            string: 2,
            background: "#cdc600"
        },
        three: {
            string: 3,
            background: "#35d200"
        },
        five: {
            string: 5,
            background: "#ff3a00"
        },
        eleven: {
            string: 11,
            background: "#2d99a3"
        },
        twentyThree: {
            string: 23,
            background: "#0a0a0a"
        },
        bonus: {
            string: "Bonus",
            background: "radial-gradient(circle, white, yellow, green, blue, purple 90%)"
        }
    }
    let str = numbers[numberKey as keyof typeof numbers] || -1;
    return (
        <>
            {style == "selection" && (
                <div className="flex justify-center items-center p-2 w-[150px] h-[75px] rounded-md" style={{
                    background: numbers[numberKey as keyof typeof numbers].background,
                }}>
                    {numbers[numberKey as keyof typeof numbers].string == "Bonus" ? (
                        <img src="/nui/images/wheel/bonus.png" className="w-10 h-10" alt="Bonus" />
                    ) : (
                        <div className="bg-white w-14 h-10 rounded-full text-black font-bold text-2xl flex items-center justify-center">
                            {numbers[numberKey as keyof typeof numbers].string}
                        </div>
                    )}
                </div>
            )}
            {style == "history" && (
                <div className="flex justify-center items-center p-2 w-[100%] h-[35px] rounded-md" style={{
                    background: numbers[numberKey as keyof typeof numbers].background,
                }}>
                    {numbers[numberKey as keyof typeof numbers].string == "Bonus" ? (
                        <img src="/nui/images/wheel/bonus.png" className="w-6 h-6" alt="Bonus" />
                    ) : (
                        <div className="bg-white w-10 h-6 rounded-full text-black font-bold text-lg flex items-center justify-center">
                            {numbers[numberKey as keyof typeof numbers].string}
                        </div>
                    )}
                </div>
            )}
        </>
    )
}

function WheelComponent({wheelWagers, isPlaying, onClick, winningSection} : {wheelWagers: WheelWager, isPlaying: boolean, winningSection?: string, onClick: (data: any) => void}) {
    const {config} = useConfig();
    const chips = config.chips || [];
    const wheelStructure = [
        [
            {
                id: "two",
                display: <WheelNumber style="selection" numberKey="two"/>
            },
            {
                id: "three",
                display: <WheelNumber style="selection" numberKey="three"/>
            },
            {
                id: "twentyThree",
                display: <WheelNumber style="selection" numberKey="twentyThree"/>
            },
        ],
        [
            {
                id: "five",
                display: <WheelNumber style="selection" numberKey="five"/>
            },
            {
                id: "eleven",
                display: <WheelNumber style="selection" numberKey="eleven"/>
            },
            {
                id: "bonus",
                display: <WheelNumber style="selection" numberKey="bonus"/>
            },
        ]
    ]
    return (
        <div className="flex flex-col gap-2" style={{
            pointerEvents: isPlaying ? "none" : "auto",
        }}>
            {wheelStructure.map((row, rowIndex) => (
                <div key={rowIndex} className="flex flex-row gap-2">
                    {row.map((column, columnIndex) => (
                        <div key={columnIndex} className="flex flex-col gap-2">
                            <div className="relative flex flex-row items-center justify-center gap-2 cursor-pointer scale-100 hover:scale-95 transition-transform" style={{
                                filter: (isPlaying && winningSection != column.id) ? "brightness(0.5)" : "none",
                            }} onClick={() => {
                                onClick({
                                    type: "attemptWager",
                                    id: column.id,
                                });
                            }}>
                                {winningSection == column.id && (
                                    <div className="absolute top-0 left-0 w-full scale-90 h-full" style={{ transformOrigin: "center" }}><ReactSparkle/></div>
                                )}
                                {column.display}
                                {wheelWagers[column.id as keyof WheelWager] > 0 && (
                                    <div className="absolute top-[50%] right-[2%] translate-x-[-2%] translate-y-[-50%]">
                                        <ChipDisplay chip={GetChipForValue(wheelWagers[column.id as keyof WheelWager], chips, true)} />
                                    </div>
                                )}
                            </div>
                        </div>
                    ))}
                </div>
            ))}
        </div>
    )
}

export default function Wheel({game}: {game: CasinoGame}) {
    const {config} = useConfig();
    const [stage, setStage] = useState<WheelStage>(game.data.stage);
    const [money, setMoney] = useState<number>(game.data.money || 0);
    const [chipValue, setChipValue] = useState<number>(0);
    const chips = config.chips || [];
    const [wheelWagers, setWheelWagers] = useState<WheelWager>(game.data.wagers || {
        two: 0,
        three: 0,
        five: 0,
        eleven: 0,
        twentyThree: 0,
        bonus: 0
    });
    const [numberHistory, setNumberHistory] = useState<{
        section: string,
        multiplier?: number,
    }[]>(game.data.history || []);
    const [isBonusSpinning, setIsBonusSpinning] = useState(false);
    useNuiEvent("updateMoney", (data) => {
        setMoney(data.money);
    });
    useNuiEvent("updateWheelStage", (data) => {
        setStage(data.stage);
    });
    useNuiEvent("updateWheelHistory", (data) => {
        setNumberHistory(data.history);
    });
    useNuiEvent("updateWheelWager", (data) => {
        setWheelWagers(data.wager);
    });
    useEffect(() => {
        if (stage.type == "bonus") {
            setIsBonusSpinning(false);
            setTimeout(() => {
                setIsBonusSpinning(true);
            }, 1000);
        }
    }, [stage]);
    return (
        <>
            {stage.type == "bonus" && (
                <div className="absolute w-full h-full flex items-center justify-center">
                    <div className="absolute w-[600px]">
                        <div className="flex flex-col items-center">
                            <img style={{height: "75px"}} src="/nui/images/wheel/header.gif" />
                        </div>
                        <div className="relative">
                                <BonusWheel prizeWon={stage.prizeId} isSpinning={isBonusSpinning}/>
                            <div className="h-full w-1 z-10 bg-white absolute top-[0] left-[50%] translate-x-[-50%]"/>
                        </div>
                    </div>
                </div>
            )}
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
                                    <GameIcon name='wheel' style={{fill: "yellow", width: 30, height: 30}} />
                                    <div className='font-bold text-2xl'><Translate id="wheel_title" /></div>
                                </div>
                                <div className='font-bold text-xl text-zinc-400'>
                                    {stage.type === "waiting" && <Translate id="wheel_nextround" args={[stage.time]} />}
                                    {stage.type === "spinning" && <Translate id="wheel_spinning" />}
                                    {stage.type === "winner" && (
                                        <div className="flex flex-row items-center gap-2">
                                            <Translate id="wheel_sectionwinner"/>
                                            <div className="relative w-12">
                                                {stage.multiplier && (
                                                    <div className="flex items-center justify-center absolute top-0 left-0 text-lg w-full h-full rounded-md text-white bg-background/75">
                                                        <div>x{stage.multiplier}</div>
                                                    </div>
                                                )}
                                                <WheelNumber style="history" numberKey={stage.section} />
                                            </div>

                                        </div>
                                    )}
                                </div>
                            </div>
                            <div className="font-semibold text-md text-zinc-400"><Translate id="wheel_desc" /></div>
                        </div>
                    </div>
                    <div className="flex flex-col gap-2 h-full items-center w-[33.333333%] px-8">
                        <WheelComponent winningSection={stage.section} isPlaying={stage.type !== "waiting"} wheelWagers={wheelWagers} onClick={(data: { type: string; id: keyof WheelWager }) => {
                            if (data.type == "attemptWager") {
                                playAudio("bet");
                                let newWagers = {...wheelWagers};
                                newWagers[data.id as keyof WheelWager] = (newWagers[data.id as keyof WheelWager] || 0) + chipValue;
                                if (CalculateWheelWagers(newWagers) > money) { return; }
                                setWheelWagers(newWagers);
                                fetchNui("setWheelWager", {
                                    wager: newWagers
                                });
                            }
                        }}/>
                        {stage.type == "waiting" && (
                            <WagerControls chipValue={chipValue} money={money} wager={CalculateWheelWagers(wheelWagers)} onClick={(data: any) => {
                                if (data.type == "setCurrentChip") {
                                    playAudio("bet");
                                    setChipValue(data.value);
                                }
                                else if (data.type == "clearWager") {
                                    playAudio("clear");
                                    setWheelWagers({
                                        two: 0,
                                        three: 0,
                                        five: 0,
                                        eleven: 0,
                                        twentyThree: 0,
                                        bonus: 0
                                    });

                                    fetchNui("setWheelWager", {
                                        wager: {
                                            two: 0,
                                            three: 0,
                                            five: 0,
                                            eleven: 0,
                                            twentyThree: 0,
                                            bonus: 0
                                        }
                                    });
                                }
                                else if (data.type == "doubleWager") {
                                    let newWagers = Object.keys(wheelWagers).reduce((acc, key) => {
                                        acc[key as keyof WheelWager] = (wheelWagers[key as keyof WheelWager] || 0) * 2;
                                        return acc;
                                    }, {} as WheelWager);
                                    if (CalculateWheelWagers(newWagers) > money) { return; }
                                    setWheelWagers(newWagers);
                                    playAudio("bet");
                                    fetchNui("setWheelWager", {
                                        wager: newWagers
                                    });
                                }
                                else if (data.type == "repeatWager") {
                                    playAudio("bet");
                                    fetchNui("repeatWheelWager", {});
                                }
                            }} />
                        )}
                    </div>
                    <div className="flex flex-col gap-2 h-full items-end w-[33.333333%]">
                        <div className="flex flex-col gap-2 h-full items-center w-full">
                            <div className="grid grid-cols-8 gap-2 w-full">
                                {numberHistory.map((number, index) => index < 32 && (
                                    <div className="relative">
                                        {number.multiplier && (
                                            <div className="flex items-center justify-center absolute top-0 left-0 text-lg font-bold w-full h-full rounded-md text-white bg-background/75">
                                                <div>x{number.multiplier}</div>
                                            </div>
                                        )}
                                        <WheelNumber key={index} numberKey={number.section} style="history" />
                                    </div>
                                ))}
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </>
    );
}