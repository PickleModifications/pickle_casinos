import { CasinoGame } from "@/components/casino/Casino"
import { Button } from "@/components/ui/button";
import { Minus, Plus, PlusCircle, RotateCw } from "lucide-react";
import { useRef, useState } from "react"
import { useEffect } from "react"

import  "./Slots.modules.css"

type SlotReel = string[]
const reelCount = 5;
const reelSymbols = 3;

const symbols: { [key: string]: { image: string } } = {
    "Bonus Symbol": {
        "image": "/nui/images/bananabonanza/bonus.png",
    },
    "Monkey": {
        "image": "/nui/images/bananabonanza/monkey.png",
    },
    "Coconut": {
        "image": "/nui/images/bananabonanza/coconut.png",
    },
    "Coconut Tree Bundle": {
        "image": "/nui/images/bananabonanza/tree_2.png",
    },
    "Coconut Tree": {
        "image": "/nui/images/bananabonanza/tree_1.png",
    },
    "Banana Bunch": {
        "image": "/nui/images/bananabonanza/banana_2.png",
    },
    "Banana": {
        "image": "/nui/images/bananabonanza/banana_1.png",
    },
}

const BonusSymbol = "Bonus Symbol";

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
                    <img draggable={false} key={index} src={symbols[symbol].image} style={{
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
            const symbolKeys = Object.keys(symbols);
            reel.push(symbolKeys[Math.floor(Math.random() * symbolKeys.length)]);
        }
        fakeReels.push(reel);
    }
    return fakeReels;
}

export default function Slots({game} : {game: CasinoGame}) {
    const [currentSpin, setCurrentSpin] = useState<SlotSpin | null>(null);
    const [spinning, setSpinning] = useState<boolean>(false);
    const [fakeReels, setFakeReels] = useState<SlotReel[]>(GenerateFakeReels(reelCount, reelSymbols));
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
                    <div className="flex flex-col items-center">
                        <div className="flex flex-row items-center gap-2">
                            <div className="font-bold text-3xl text-yellow-600">Bet</div>
                            <div className="font-bold text-3xl">$10</div>
                        </div>
                        <div className="flex flex-row items-center gap-2">
                            <div className="font-bold text-3xl text-yellow-600">Balance</div>
                            <div className="font-bold text-3xl">$10,000</div>
                        </div>
                    </div>
                    <div className="flex flex-row items-center gap-2">
                        <div className="rounded-full border p-2 bg-background/50 hover:scale-105 cursor-pointer transition-transform">
                            <Minus size={24} className="text-primary" />
                        </div>
                        <div className="rounded-full border p-4 bg-background/95 hover:rotate-[45deg] hover:scale-105 cursor-pointer transition-transform" onClick={() => {
                            if (!spinning) {
                                setCurrentSpin({
                                    spins: [
                                        GenerateFakeReels(reelCount, reelSymbols),
                                    ]
                                });
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