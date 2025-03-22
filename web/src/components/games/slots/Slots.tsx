import { AnimatedValue, CasinoGame } from "@/components/casino/Casino"
import { Button } from "@/components/ui/button";
import { Minus, Plus, PlusCircle, RotateCw, X } from "lucide-react";
import { useRef, useState } from "react"
import { useEffect } from "react"

import  "./Slots.modules.css"

type SlotReel = string[]

type SlotSymbols = {
    [key: string]: {
        image: string;
        reels: number[];
    }
}

const reelSymbols = 3;

const slotSymbols: SlotSymbols = {
    "Bonus Symbol": {
        image: "/nui/images/bananabonanza/bonus.png",
        reels: [5, 5, 1, 1, 1],
    },
    "Monkey": {
        image: "/nui/images/bananabonanza/monkey.png",
        reels: [2, 2, 2, 2, 2],
    },
    "Coconut": {
        image: "/nui/images/bananabonanza/coconut.png",
        reels: [3, 3, 3, 3, 3],
    },
    "Coconut Tree Bundle": {
        image: "/nui/images/bananabonanza/tree_2.png",
        reels: [4, 4, 4, 4, 4],
    },
    "Coconut Tree": {
        image: "/nui/images/bananabonanza/tree_1.png",
        reels: [5, 5, 5, 5, 5],
    },
    "Banana Bunch": {
        image: "/nui/images/bananabonanza/banana_2.png",
        reels: [6, 6, 6, 6, 6],
    },
    "Banana": {
        image: "/nui/images/bananabonanza/banana_1.png",
        reels: [7, 7, 7, 7, 7],
    },
}

const paylines = [
    [1, 1, 1, 1, 1],
    [0, 0, 0, 0, 0],
    [2, 2, 2, 2, 2],
    [0, 1, 2, 1, 0],
    [2, 1, 0, 1, 2],
    [1, 0, 0, 0, 1],
    [1, 2, 2, 2, 1],
    [0, 0, 1, 2, 2],
    [2, 2, 1, 0, 0],
    [1, 2, 1, 0, 1],
    [1, 0, 1, 2, 1],
    [0, 1, 1, 1, 0],
    [2, 1, 1, 1, 2],
    [0, 1, 0, 1, 0],
    [2, 1, 2, 1, 2],
    [1, 1, 0, 1, 1],
    [1, 1, 2, 1, 1],
    [0, 0, 2, 0, 0],
    [2, 2, 0, 2, 2],
    [0, 2, 2, 2, 0],
]

const Bonus = {
    symbol: "Bonus Symbol",
    triggerCount: 3,
    freeSpins: 10,
}

const BonusSymbol = Bonus.symbol;
const BonusTriggerCount = Bonus.triggerCount;

type SlotSpin = {
    spins: SlotReel[][];
}

function Reel({spinning, index, bonusIndex, fakeReel, reel, onSpinComplete}: {spinning: boolean, index: number, bonusIndex?: number, fakeReel: SlotReel, reel?: SlotReel, onSpinComplete?: () => void}) {
    const reelRef = useRef<HTMLDivElement | null>(null);
    const [currentReel, setCurrentReel] = useState<SlotReel>([]);
    const [fakeReelScroll, setFakeReelScroll] = useState<number>(0);
    const [isShowingCurrent, setIsShowingCurrent] = useState<boolean>(false);

    useEffect(() => {
        if (!reel || !spinning) {
            return;
        };
        if (reelRef.current) {
            const reelElement = reelRef.current;
            let fakeReelScrollHeight = 0;
            if (!isShowingCurrent) {
                setFakeReelScroll(reelElement.scrollHeight / 2);
                fakeReelScrollHeight = reelElement.scrollHeight / 2;
            }
            else {
                fakeReelScrollHeight = fakeReelScroll;
            }
            setTimeout(() => {
                let rotations = 0;
                let scrollAmount = (!isShowingCurrent ? reelElement.scrollHeight / 2 : fakeReelScrollHeight);
                const scrollReel = () => {
                    scrollAmount -= 20;
                    reelElement.scrollTop = scrollAmount;
                    if (scrollAmount <= 0) {
                        rotations += 1;
                        if (!isShowingCurrent) {
                            scrollAmount = reelElement.scrollHeight / 2;
                        }
                        else {
                            let hasBonus = currentReel.includes(BonusSymbol);
                            if (hasBonus) {
                                new Audio("/nui/audio/bananabonanza/bonus_"+ (bonusIndex || 1) +".mp3").play();
                            }
                            console.log("STOPPED", index)
                            new Audio("/nui/audio/bananabonanza/reel.mp3").play();
                            if (onSpinComplete) {
                                onSpinComplete();
                            }
                            return;
                        }
                    }
                    if (rotations >= 5) {
                        if (!isShowingCurrent) {
                            setIsShowingCurrent(true);
                            setCurrentReel(reel);
                            return;
                        }
                        else {
                            return;
                        }
                    }
                    requestAnimationFrame(scrollReel);
                };
                scrollReel();
            }, (!isShowingCurrent ? 300 * index : 0));
        }
    }, [reel, isShowingCurrent]);
    useEffect(() => {
        if (spinning) {
        }
        else {
            if (isShowingCurrent) {
                setCurrentReel([]);
                setFakeReelScroll(0);
                setIsShowingCurrent(false);
            }
        }
    }, [spinning]);
    return (
        <div
            className="flex flex-col overflow-hidden"
            ref={reelRef}
            style={{ height: 133 * reelSymbols }}
        >
            {currentReel.concat(fakeReel).concat(fakeReel).map((symbol, index) => {
                const isCurrentReel = (currentReel.length > 0 && index < currentReel.length);
                const isWin = isCurrentReel && currentReel[index] == BonusSymbol;
                return (
                    <img draggable={false} key={index} src={slotSymbols[symbol].image} style={{
                        animation: isWin ? "shake 2s" : "unset",
                        animationIterationCount: isWin ? "infinite" : "unset",
                        width: 200,
                        height: 133,
                        minWidth: 200,
                        minHeight: 133,
                    }} />
                )
            })}
        </div>
    )
}

function GenerateFakeReels(reelCount: number, reelSymbols: number): SlotReel[] {
    const fakeReels: SlotReel[] = [];
    for (let i = 0; i < reelCount; i++) {
        const reel: SlotReel = [];
        for (let j = 0; j < reelSymbols; j++) {
            const symbolKeys = Object.keys(slotSymbols);
            reel.push(symbolKeys[Math.floor(Math.random() * symbolKeys.length)]);
        }
        fakeReels.push(reel);
    }
    return fakeReels;
}

function GenerateSpin(reelLength: number, reelSymbols: number) {
    let reelResults = [];
    for (let i=0; i<reelLength; i++) {
        let reelResult = []
        let hasAddedBonus = false;
        for (let j=0; j<reelSymbols; j++) {
            let symbols = [];
            for (const [slotSymbol, data] of Object.entries(slotSymbols)) {
                for (let k = 0; k < data.reels[i]; k++) {
                    symbols.push(slotSymbol);
                }
            }
            let symbolIndex = Math.floor(Math.random() * symbols.length);
            let symbol = symbols[symbolIndex];
            if (symbol == BonusSymbol) {
                if (hasAddedBonus) {
                    while (symbol == BonusSymbol) {
                        symbolIndex = Math.floor(Math.random() * symbols.length);
                        symbol = symbols[symbolIndex];
                    }
                }
                else {                
                    hasAddedBonus = true;
                }
            }
            reelResult.push(symbol);
        }
        reelResults.push(reelResult);
    }
    return {
        spins: [
            reelResults,
        ]
    }
}

export default function Slots({game} : {game: CasinoGame}) {
    const reelLength = 5;
    const [currentSpin, setCurrentSpin] = useState<SlotSpin | null>(null);
    const [spinning, setSpinning] = useState<boolean>(false);
    const [fakeReels, setFakeReels] = useState<SlotReel[]>(GenerateFakeReels(reelLength, reelSymbols));
    const [balance, setBalance] = useState<number>(1000);
    const [bet, setBet] = useState<number>(10);
    const audio = useRef<HTMLAudioElement | null>(null);
    useEffect(() => {
        if (audio.current) {
            audio.current.pause();
        }
        if (spinning) {
            audio.current = new Audio("/nui/audio/bananabonanza/spin.mp3");
            audio.current.loop = true;
            audio.current.play();
        }
        else {
            if (audio.current) {
                audio.current.pause();
                audio.current = null;
            }
        }
    }, [spinning]);
    return (
        <div className="absolute top-[50%] left-[50%] transform translate-x-[-50%] translate-y-[-50%] select-none">
            <div className="flex flex-col items-center px-16 gap-2" style={{
                backgroundImage: `url(${game.data.backgroundImage})`,
                backgroundSize: "cover",
                backgroundPosition: "center",
            }}>
                {/* <div className="z-[20] absolute top-0 left-0 w-full h-full bg-background/85">
                    <div className="absolute top-0 right-0 p-2">
                        <X size={32} className="text-primary cursor-pointer hover:scale-95 transition-transform"/>
                    </div>
                    <div className="flex flex-row items-start justify-between p-8">
                        <div className="flex flex-col gap-2 items-center">
                            <div className="font-bold text-4xl">Paylines</div>
                            <div className="grid grid-cols-4 gap-4">
                                {paylines.map((payline, index) => {
                                    return (
                                        <div key={index} className="flex flex-col items-center gap-2">
                                            <div className="font-bold text-2xl">{index + 1}</div>
                                            <div className="flex flex-row gap-1">
                                                {Array(reelLength).fill(0).map((_, reelIndex) => {
                                                    return (
                                                        <div className="flex flex-col items-center gap-1" key={reelIndex}>
                                                            {Array(reelSymbols).fill(0).map((_, symbolIndex) => {
                                                                return (
                                                                    <div
                                                                        key={symbolIndex}
                                                                        style={{
                                                                            width: 12,
                                                                            height: 12,
                                                                            background: payline[reelIndex] === symbolIndex ? "rgba(255,255,255,0.75)" : "rgba(64, 64, 64, 0.75)",
                                                                            borderRadius: 2,
                                                                        }}
                                                                    ></div>
                                                                );
                                                            })}
                                                        </div>
                                                    );
                                                })}
                                            </div>
                                        </div>
                                    );
                                })}
                            </div>
                        </div>    
                        <div className="flex font-semibold flex-col gap-2 items-center">
                            <div className="font-bold text-4xl">Game Rules</div>
                            <div className="flex flex-col gap-2 items-center">
                                <div>Symbols pay left to right.</div>
                                <div className="flex flex-row items-center gap-2">
                                    <div>You must get {BonusTriggerCount}</div>
                                    <img src={slotSymbols[BonusSymbol].image} className="h-12" />
                                    <div>symbol(s) to trigger {Bonus.freeSpins} free spin(s).</div>
                                </div>    
                            </div>
                        </div>
                    </div>
                </div> */}
                <div className="flex flex-col items-center">
                    <img src={game.data.headerTextImage} className="max-h-24" />
                    <div className="flex flex-row relative p-2 bg-background/95">
                        <div className="absolute top-0 left-0 w-full h-full z-10" style={{
                            background: "linear-gradient(0deg, rgba(0,0,0,0.5) 0%, rgba(0,0,0,0) 5%, rgba(0,0,0,0) 95%, rgba(0,0,0,0.5) 100%)",
                        }}/>
                        {fakeReels.map((reel, index) => {
                            const spin = currentSpin?.spins[0];
                            const actualReel = spin ? spin[index] : undefined;
                            let hasBonus = actualReel?.includes(BonusSymbol);
                            let bonusIndex = undefined;
                            if (hasBonus && spin) {
                                bonusIndex = 0;
                                for (let i = 0; i <= index; i++) {
                                    if (spin[i] && spin[i].includes(BonusSymbol)) {
                                        bonusIndex += 1;
                                    }
                                }
                                if (bonusIndex > 4) {
                                    bonusIndex = 4;
                                }
                            }
                            console.log("BONUS INDEX", bonusIndex);
                            return <Reel bonusIndex={bonusIndex} spinning={spinning} index={index} key={index} fakeReel={reel} reel={currentSpin?.spins[0][index]} onSpinComplete={index == (fakeReels.length - 1) ? () => {
                                setSpinning(false);
                                setFakeReels(currentSpin?.spins[0] || fakeReels);
                            }: undefined}/>
                        })}
                    </div>
                </div>
                <div className="flex flex-row items-center justify-between w-full p-2">
                    <div className="flex flex-row items-end gap-2">
                        <div className="flex flex-col items-end gap-2">
                            <div className="font-bold text-3xl text-yellow-600">Bet</div>
                            <div className="font-bold text-3xl text-yellow-600">Balance</div>
                        </div>
                        <div className="flex flex-col items-start gap-2">
                            <div className="font-bold text-3xl"><AnimatedValue value={bet} /></div>
                            <div className="font-bold text-3xl"><AnimatedValue value={balance} /></div>
                        </div>
                    </div>
                    <div className="flex flex-row items-center gap-2 font-bold text-4xl">
                        <div className="text-yellow-600">WIN</div>
                        <div><AnimatedValue value={1000}/></div>
                    </div>
                    <div className="flex flex-row items-center gap-2">
                        <div className="rounded-full border p-2 bg-background/50 hover:scale-105 cursor-pointer transition-transform">
                            <Minus size={24} className="text-primary" />
                        </div>
                        <div className="rounded-full border p-4 bg-background/95 hover:rotate-[45deg] hover:scale-105 cursor-pointer transition-transform" onClick={() => {
                            if (!spinning) {
                                setCurrentSpin(GenerateSpin(reelLength, reelSymbols));
                                setSpinning(true);
                            }
                        }}>
                            <RotateCw size={64} className={`text-primary ${spinning ? "animate-spin" : ""}`} />
                        </div>
                        <div className="rounded-full border p-2 bg-background/50 hover:scale-105 cursor-pointer transition-transform">
                            <Plus size={24} className="text-primary" />
                        </div>
                    </div>
                </div>
                {/* {currentSpin && (
                    <>
                        <div className="font-bold text-2xl w-full text-center">Expected Output (SSR)</div>
                        <div className="flex flex-row border relative p-1 bg-yellow-400">
                            <div className="absolute top-0 left-0 w-full h-full z-10" style={{
                                background: "linear-gradient(0deg, rgba(0,0,0,0.5) 0%, rgba(0,0,0,0) 5%, rgba(0,0,0,0) 95%, rgba(0,0,0,0.5) 100%)",
                            }}/>
                            {currentSpin.spins[0].map((reel, index) => {
                                return <Reel spinning={false} index={index} key={index} fakeReel={currentSpin.spins[0][index]} reel={reel} />
                            })}
                        </div>
                    </>
                )} */}
                </div>
        </div>
    )
}