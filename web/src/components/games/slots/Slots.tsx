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
    spinIndex: number;
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
                            new Audio("/nui/audio/bananabonanza/reel.mp3").play();
                            if (onSpinComplete) {
                                onSpinComplete();
                            }
                            return;
                        }
                    }
                    if (rotations >= 3) {
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
            }, (!isShowingCurrent ? 200 * index : 0));
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

function GenerateSpin(reelLength: number, reelSymbols: number, forceBonus?: boolean, removeBonus?: boolean): SlotSpin {
    let reelResults = [];
    for (let i=0; i<reelLength; i++) {
        let reelResult = []
        let hasAddedBonus = false;
        for (let j=0; j<reelSymbols; j++) {
            let symbols = [];
            for (const [slotSymbol, data] of Object.entries(slotSymbols)) {
                for (let k = 0; k < data.reels[i]; k++) {
                    if (removeBonus && slotSymbol == BonusSymbol) {
                        continue;
                    }
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
        if (forceBonus) {
            reelResult[0] = BonusSymbol;
        }
        reelResults.push(reelResult);
    }
    let additionalSpins: SlotSpin[] = [];
    if (forceBonus) {
        for (let i=0; i<3; i++) {
            additionalSpins.push(GenerateSpin(reelLength, reelSymbols, undefined, true));
        }
    }
    return {
        spinIndex: 0,
        spins: [
            reelResults,
            ...additionalSpins.map(spin => spin.spins[0]),
        ]
    }
}

export default function Slots({game} : {game: CasinoGame}) {
    const reelLength = 5;
    const [currentSpin, setCurrentSpin] = useState<SlotSpin | null>(null);
    const [spinning, setSpinning] = useState<boolean>(false);
    const [allowSpin, setAllowSpin] = useState<boolean>(true);
    const [fakeReels, setFakeReels] = useState<SlotReel[]>(GenerateFakeReels(reelLength, reelSymbols));
    const [balance, setBalance] = useState<number>(1000);
    const [bet, setBet] = useState<number>(10);
    const [inBonus, setInBonus] = useState<boolean>(false);
    const audio = useRef<HTMLAudioElement | null>(null);
    const bonusAudio = useRef<HTMLAudioElement | null>(null);
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
    useEffect(() => {
        if (inBonus) {
            if (!bonusAudio.current) {
                bonusAudio.current = new Audio("/nui/audio/bananabonanza/bonus_loop.mp3");
                bonusAudio.current.loop = true;
                bonusAudio.current.play();
            }
        }
        else {
            if (bonusAudio.current) {
                bonusAudio.current.pause();
                bonusAudio.current = null;
            }
        }
    }, [inBonus]);
    let bonusSymbols = 0;
    if (currentSpin) {
        const spin = currentSpin.spins[currentSpin.spinIndex];
        for (let i = 0; i < spin.length; i++) {
            if (spin[i].includes(BonusSymbol)) {
                bonusSymbols += 1;
            }
        }
    }
    const startNextSpin = (spinIndex: number) => {
        if (!currentSpin || !currentSpin.spins[spinIndex]) {
            return;
        }
        setCurrentSpin({
            spinIndex: spinIndex,
            spins: currentSpin.spins
        });
    }
    console.log("CURRENT SPIN: ", currentSpin?.spinIndex)
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
                            const spin = currentSpin?.spins[currentSpin.spinIndex];
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
                            return <Reel bonusIndex={bonusIndex} spinning={spinning} index={index} key={index} fakeReel={reel} reel={currentSpin?.spins[currentSpin.spinIndex][index]} onSpinComplete={index == (fakeReels.length - 1) ? () => {
                                if (bonusSymbols >= BonusTriggerCount) {
                                    setTimeout(() => {
                                        new Audio("/nui/audio/bananabonanza/bonus_win.mp3").play();
                                    }, 500);
                                    setTimeout(() => {
                                        setInBonus(true);
                                        setAllowSpin(true);
                                    }, 2500);
                                }
                                else {
                                    setAllowSpin(true);
                                    if (currentSpin?.spins && currentSpin?.spinIndex == currentSpin?.spins.length - 1) {
                                        setCurrentSpin(null);
                                        setInBonus(false);
                                    }
                                }
                                setSpinning(false);
                                setFakeReels(currentSpin?.spins[currentSpin.spinIndex] || fakeReels);
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
                    <div className="font-bold text-4xl">
                        {(currentSpin?.spins && inBonus && currentSpin?.spins.length > 0) && <div className="flex flex-row items-center gap-2">
                            <div className="text-yellow-600">FREE SPINS:</div>
                            <div>{(currentSpin?.spins.length - 1) - currentSpin.spinIndex}</div>
                        </div>}
                    </div>
                    <div className="flex flex-row items-center gap-2">
                        <div className="rounded-full border p-2 bg-background/50 hover:scale-105 cursor-pointer transition-transform">
                            <Minus size={24} className="text-primary" />
                        </div>
                        <div className={`rounded-full border p-4 bg-background/95 transition-transform ${!allowSpin ? "brightness-50" : "cursor-pointer hover:rotate-[45deg] hover:scale-105"}`} onClick={() => {
                            if (!spinning) {
                                if (currentSpin) {
                                    if (currentSpin.spinIndex == 0) {
                                        setCurrentSpin({
                                            spinIndex: currentSpin.spinIndex + 1,
                                            spins: currentSpin.spins
                                        });
                                    }
                                    else {
                                        startNextSpin(currentSpin.spinIndex + 1);
                                    }
                                }
                                else {
                                    setCurrentSpin(GenerateSpin(reelLength, reelSymbols, true));
                                }
                                setAllowSpin(false);
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