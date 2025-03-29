import { AnimatedValue, CasinoGame, DisplayCurrency } from "@/components/casino/Casino"
import { Button } from "@/components/ui/button";
import { InfoIcon, Minus, Plus, PlusCircle, RotateCw, X } from "lucide-react";
import { useRef, useState } from "react"
import { useEffect } from "react"

import  "./Slots.modules.css"
import { fetchNui } from "@/providers/nui/fetchNui";
import { useNuiEvent } from "@/providers/nui/useNui";

type SlotReel = string[]

type SlotSymbols = {
    [key: string]: {
        image: string;
        reels: number[];
        pay: number[];
    }
}

type SlotGame = {
    data: {
        foldername: string;
        backgroundImage: string;
        headerTextImage: string;
        reelCount: number;
        reelSymbols: number;
        paylineWinThreshold: number;
        slotSymbols: SlotSymbols;
        bonusTriggerCount: number,
        bonusFreeSpins: number,
        bonusSymbol: string,
        paylines: number[][],
        money: number,
        bets: number[],
    }
}

type SlotSpin = {
    id?: number;
    spinIndex: number;
    spins: SlotReel[][];
}

function Reel({winningRows, spinning, index, bonusIndex, fakeReel, reel, onSpinComplete, game}: {winningRows: boolean[], spinning: boolean, index: number, bonusIndex?: number, fakeReel: SlotReel, reel?: SlotReel, onSpinComplete?: () => void, game: SlotGame}) {
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
                            let hasBonus = currentReel.includes(game.data.bonusSymbol);
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
            style={{ height: 133 * game.data.reelSymbols }}
        >
            {currentReel.concat(fakeReel).concat(fakeReel).map((symbol, index) => {
                const isCurrentReel = (currentReel.length > 0 && index < currentReel.length);
                let isWin = isCurrentReel && (currentReel[index] == game.data.bonusSymbol);
                return (
                    <img draggable={false} key={index} src={`/nui/images/${game.data.foldername}/${game.data.slotSymbols[symbol].image}`} style={{
                        animation: (!spinning && (isWin || winningRows[index])) ? "shake 2s" : "unset",
                        animationIterationCount: (!spinning && (isWin || winningRows[index])) ? "infinite" : "unset",
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

function GenerateFakeReels(game: SlotGame): SlotReel[] {
    const fakeReels: SlotReel[] = [];
    for (let i = 0; i < game.data.reelCount; i++) {
        const reel: SlotReel = [];
        for (let j = 0; j < game.data.reelSymbols; j++) {
            const symbolKeys = Object.keys(game.data.slotSymbols);
            reel.push(symbolKeys[Math.floor(Math.random() * symbolKeys.length)]);
        }
        fakeReels.push(reel);
    }
    return fakeReels;
}

function GenerateDebugSpin(game: SlotGame, forceBonus?: boolean, removeBonus?: boolean): SlotSpin {
    let reelResults = [];
    let totalBonuses = 0;
    for (let i=0; i<game.data.reelCount; i++) {
        let reelResult = []
        let hasAddedBonus = false;
        for (let j=0; j<game.data.reelSymbols; j++) {
            let symbols = [];
            for (const [slotSymbol, data] of Object.entries(game.data.slotSymbols)) {
                for (let k = 0; k < data.reels[i]; k++) {
                    if (removeBonus && slotSymbol == game.data.bonusSymbol) {
                        continue;
                    }
                    symbols.push(slotSymbol);
                }
            }
            let symbolIndex = Math.floor(Math.random() * symbols.length);
            let symbol = symbols[symbolIndex];
            if (symbol == game.data.bonusSymbol) {
                if (hasAddedBonus) {
                    while (symbol == game.data.bonusSymbol) {
                        symbolIndex = Math.floor(Math.random() * symbols.length);
                        symbol = symbols[symbolIndex];
                    }
                }
                else {               
                    totalBonuses += 1; 
                    hasAddedBonus = true;
                }
            }
            reelResult.push(symbol);
        }
        if (forceBonus) {
            reelResult[0] = game.data.bonusSymbol;
        }
        reelResults.push(reelResult);
    }
    let additionalSpins: SlotSpin[] = [];
    if (forceBonus || totalBonuses >= game.data.bonusTriggerCount) { 
        for (let i=0; i<game.data.bonusTriggerCount; i++) {
            additionalSpins.push(GenerateDebugSpin(game, undefined, true));
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

function GetPaylineResults(slotSpin: SlotSpin, game: SlotGame): {symbol: string | null, count: number}[] {
    let paylineResults: {symbol: string | null, count: number}[] = [];
    let hasWin = false;
    for (let i = 0; i < game.data.paylines.length; i++) {
        const payline = game.data.paylines[i];
        const spin = (slotSpin ? slotSpin.spins[slotSpin.spinIndex] : null);
        if (spin) {
            let firstSymbol = spin[0][payline[0]];
            let count = 1;
            for (let j=1; j < payline.length; j++) {
                const spinColumn = spin[j];
                if (!spinColumn) {
                    continue;
                }
                const symbol = spinColumn[payline[j]];
                if (symbol == firstSymbol) {
                    count += 1;
                }
                else {
                    break;
                }
            }
            if (count >= game.data.paylineWinThreshold) {
                hasWin = true;
                console.log("PAYLINE WIN:", i, firstSymbol, spin, payline);
                paylineResults.push({
                    symbol: firstSymbol,
                    count: count,
                });
            }
            else {
                paylineResults.push({
                    symbol: null,
                    count: 0,
                });
            }
        }
        else {
            paylineResults.push({
                symbol: null,
                count: 0,
            });
        }
    }
    return paylineResults; // Return the array of results
}

export default function Slots({game} : {game: SlotGame}) {
    const [currentSpin, setCurrentSpin] = useState<SlotSpin | null>(null);
    const [spinning, setSpinning] = useState<boolean>(false);
    const [allowSpin, setAllowSpin] = useState<boolean>(true);
    const [fakeReels, setFakeReels] = useState<SlotReel[]>(GenerateFakeReels(game));
    const [paylineResults, setPaylineResults] = useState<{symbol: string | null, count: number}[]>([]);
    const [totalWin, setTotalWin] = useState<number>(0);
    const [balance, setBalance] = useState<number>(game.data.money || 0);
    const [bets, setBets] = useState<number[]>(game.data.bets || []);
    const [betIndex, setBetIndex] = useState<number>(0);
    const [inBonus, setInBonus] = useState<boolean>(false);
    const [showInfo, setShowInfo] = useState<boolean>(false);
    const audio = useRef<HTMLAudioElement | null>(null);
    const bonusAudio = useRef<HTMLAudioElement | null>(null);
    const bet = bets[betIndex] || 0;
    useNuiEvent("updateBalance", (data: any) => {
        setBalance(data.balance);
    });
    useEffect(() => {
        if (audio.current) {
            if (spinning) {
                audio.current.currentTime = 0;
                audio.current.play();
            }
            else {
                audio.current.pause();
            }
        }
    }, [spinning]);
    useEffect(() => {
        if (bonusAudio.current) {
            if (inBonus) {
                bonusAudio.current.currentTime = 0;
                bonusAudio.current.play();
            }
            else {
                bonusAudio.current.pause();
            }
        }
    }, [inBonus]);
    useEffect(() => {
        if (currentSpin) {
            setPaylineResults(GetPaylineResults(currentSpin, game));
            setTotalWin(0);
        }
    }, [currentSpin]);
    let bonusSymbols = 0;
    if (currentSpin) {
        const spin = currentSpin.spins[currentSpin.spinIndex];
        for (let i = 0; i < spin.length; i++) {
            if (spin[i].includes(game.data.bonusSymbol)) {
                bonusSymbols += 1;
            }
        }
    }
    const startNextSpin = (spinIndex: number) => {
        if (!currentSpin || !currentSpin.spins[spinIndex]) {
            return;
        }
        setCurrentSpin({
            ...currentSpin,
            spinIndex: spinIndex,
        });
    }
    let requestingSpin = false;
    const requestSpin = async () => {
        if (requestingSpin) {
            return;
        }
        requestingSpin = true;
        if (!spinning && allowSpin) {
            if (currentSpin) {
                if (currentSpin.spinIndex == 0) {
                    setCurrentSpin({
                        ...currentSpin,
                        spinIndex: currentSpin.spinIndex + 1
                    });
                }
                else {
                    startNextSpin(currentSpin.spinIndex + 1);
                }
                setAllowSpin(false);
                setSpinning(true);
            }
            else {
                // setCurrentSpin(GenerateDebugSpin(game, false));
                const spinResult = await fetchNui("spinSlot", {betIndex: betIndex + 1});
                if (spinResult) {
                    setCurrentSpin(spinResult as SlotSpin);
                    setAllowSpin(false);
                    setSpinning(true);
                }
            }
        }
        requestingSpin = false;
    }
    useEffect(() => {
        const handleKeyPress = (event: KeyboardEvent) => {
            if (event.code === "Space") {
                requestSpin();
            }
        };

        window.addEventListener("keydown", handleKeyPress);
        return () => {
            window.removeEventListener("keydown", handleKeyPress);
        };
    }, [allowSpin, spinning]);
    let calculatedWin = 0;
    for (let i=0; i<paylineResults.length; i++) {
        const paylineResult = paylineResults[i];
        if (paylineResult.symbol && paylineResult.count >= game.data.paylineWinThreshold) {
            let winningSymbol = paylineResult.symbol;
            calculatedWin += game.data.slotSymbols[winningSymbol].pay[paylineResult.count - 1] * bet;
        }
    }
    return (
        <div className="absolute top-[50%] left-[50%] transform translate-x-[-50%] translate-y-[-50%] select-none">
            <audio src={`/nui/audio/${game.data.foldername}/spin.mp3`} ref={audio} loop/>
            <audio src={`/nui/audio/${game.data.foldername}/bonus_loop.mp3`} ref={bonusAudio} loop/>
            <div className="absolute top-6 right-6 rounded-full border p-2 bg-background/50 hover:scale-105 cursor-pointer transition-transform"  onClick={() => {
                setShowInfo(true);
            }} >
                <InfoIcon size={32} className="text-primary"/>                                
            </div>
            <div className="flex flex-col items-center px-16 gap-2" style={{
                backgroundImage: `url("/nui/images/${game.data.foldername}/${game.data.backgroundImage}")`,
                backgroundSize: "cover",
                backgroundPosition: "center",
            }}>
                {showInfo && <div className="z-[20] absolute top-0 left-0 w-full h-full bg-background/85">
                    <div className="absolute top-0 right-0 p-2" onClick={() => {
                        setShowInfo(false);
                    }}>
                        <X size={32} className="text-primary cursor-pointer hover:scale-95 transition-transform"/>
                    </div>
                    <div className="flex flex-row items-start justify-between p-8">
                        <div className="flex flex-col gap-2 items-center">
                            <div className="font-bold text-4xl">Paylines</div>
                            <div className="grid grid-cols-4 gap-4">
                                {game.data.paylines.map((payline, index) => {
                                    return (
                                        <div key={index} className="flex flex-col items-center gap-2">
                                            <div className="font-bold text-2xl">{index + 1}</div>
                                            <div className="flex flex-row gap-1">
                                                {Array(game.data.reelCount).fill(0).map((_, reelIndex) => {
                                                    return (
                                                        <div className="flex flex-col items-center gap-1" key={reelIndex}>
                                                            {Array(game.data.reelSymbols).fill(0).map((_, symbolIndex) => {
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
                                    <div>You must get {game.data.bonusTriggerCount}</div>
                                    <img src={`/nui/images/${game.data.foldername}/${game.data.slotSymbols[game.data.bonusSymbol].image}`} className="h-12" />
                                    <div>symbol(s) to trigger {game.data.bonusSymbol} free spin(s).</div>
                                </div>    
                            </div>
                            <div className="grid grid-cols-3 gap-0 max-w-[600px]">
                                {Object.entries(game.data.slotSymbols).map(([symbol, data], index) => {
                                    const totalPay = data.pay.reduce((sum, pay) => sum + pay, 0);
                                    if (totalPay <= 0) return null;
                                    return (
                                        <div key={index} className="flex flex-col items-center gap-0">
                                            <img src={`/nui/images/${game.data.foldername}/${data.image}`} alt={symbol} className="h-16" />
                                            <div className="font-bold text-lg text-center">{symbol}</div>
                                            <div className="flex flex-col gap-0 items-center">
                                                {data.pay.map((pay, payIndex) => (pay > 0) && (
                                                    <div key={payIndex} className="text-md font-normal text-center">{payIndex + 1} - <DisplayCurrency value={pay * bet}/></div>
                                                ))}
                                            </div>
                                        </div>
                                    );
                                })}
                            </div>
                        </div>
                    </div>
                </div>}
                <div className="flex flex-col items-center">
                    <img src={`/nui/images/${game.data.foldername}/${game.data.headerTextImage}`} className="max-h-24" />
                    <div className="flex flex-row relative p-2 bg-background/95">
                        <div className="absolute top-0 left-0 w-full h-full z-10" style={{
                            background: "linear-gradient(0deg, rgba(0,0,0,0.5) 0%, rgba(0,0,0,0) 5%, rgba(0,0,0,0) 95%, rgba(0,0,0,0.5) 100%)",
                        }}/>
                        {fakeReels.map((reel, index) => {
                            const spin = currentSpin?.spins[currentSpin.spinIndex];
                            const actualReel = spin ? spin[index] : undefined;
                            let hasBonus = actualReel?.includes(game.data.bonusSymbol);
                            let bonusIndex = undefined;
                            if (hasBonus && spin) {
                                bonusIndex = 0;
                                for (let i = 0; i <= index; i++) {
                                    if (spin[i] && spin[i].includes(game.data.bonusSymbol)) {
                                        bonusIndex += 1;
                                    }
                                }
                                if (bonusIndex > 4) {
                                    bonusIndex = 4;
                                }
                            }
                            let winningRows = Array(game.data.reelSymbols).fill(false);
                            for (let i=0; i<paylineResults.length; i++) {
                                const paylineResult = paylineResults[i];
                                const payline = game.data.paylines[i];
                                if (paylineResult.count >= game.data.paylineWinThreshold && paylineResult.count >= (index + 1)) {
                                    let columnIndex = payline[index]
                                    let winningSymbol = paylineResult.symbol;
                                    if (reel[columnIndex] == winningSymbol) {
                                        winningRows[columnIndex] = true;
                                    }
                                }
                            }
                            return <Reel game={game} winningRows={winningRows} bonusIndex={bonusIndex} spinning={spinning} index={index} key={index} fakeReel={reel} reel={currentSpin?.spins[currentSpin.spinIndex][index]} onSpinComplete={index == (fakeReels.length - 1) ? () => {
                                fetchNui("finishSpin", {id: currentSpin?.id, spinIndex: (currentSpin?.spinIndex || 0) + 1});
                                if (calculatedWin > 0) {
                                    new Audio(`/nui/audio/${game.data.foldername}/win.mp3`).play();
                                    setTotalWin(0.01);
                                    setTimeout(() => {
                                        setTotalWin(calculatedWin);
                                    }, 150);
                                }
                                if (bonusSymbols >= game.data.bonusTriggerCount) {
                                    setTimeout(() => {
                                        new Audio(`/nui/audio/${game.data.foldername}/bonus_win.mp3`).play();
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
                    <div className="font-bold text-4xl flex flex-col items-center gap-2">
                        {(!spinning && totalWin > 0) && (
                            <div className="flex flex-row items-center gap-2">
                                <div className="text-yellow-600">WIN:</div>
                                <div><AnimatedValue value={totalWin}/></div>
                            </div>
                        )}
                        {(currentSpin?.spins && inBonus && currentSpin?.spins.length > 0) && <div className="flex flex-row items-center gap-2">
                            <div className="text-yellow-600">FREE SPINS:</div>
                            <div>{(currentSpin?.spins.length - 1) - currentSpin.spinIndex}</div>
                        </div>}
                    </div>
                    <div className="flex flex-row items-center gap-2">
                        <div className="rounded-full border p-2 bg-background/50 hover:scale-105 cursor-pointer transition-transform" onClick={() => {
                            console.log("BALLS", betIndex)
                            if (betIndex > 0) {
                                setBetIndex(betIndex - 1);
                            }
                        }}>
                            <Minus size={24} className="text-primary" />
                        </div>
                        <div className={`rounded-full border p-4 bg-background/95 transition-transform ${!allowSpin ? "brightness-50" : "cursor-pointer hover:rotate-[45deg] hover:scale-105"}`} onClick={() => {
                            requestSpin();
                        }}>
                            <RotateCw size={64} className={`text-primary ${spinning ? "animate-spin" : ""}`} />
                        </div>
                        <div className="rounded-full border p-2 bg-background/50 hover:scale-105 cursor-pointer transition-transform" onClick={() => {
                            console.log("BALLS 2", betIndex, bets.length, bets)
                            if (betIndex < bets.length - 1) {
                                setBetIndex(betIndex + 1);
                            }
                        }}>
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