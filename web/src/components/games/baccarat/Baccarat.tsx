import { AnimatedValue, Card, CardsDisplay, CasinoGame, ChipDisplay, GameIcon, GetChipForValue, WagerComponent } from "@/components/casino/Casino";
import { useConfig } from "@/providers/config";
import { Translate } from "@/providers/locale/Locale";
import { fetchNui } from "@/providers/nui/fetchNui";
import { useNuiEvent } from "@/providers/nui/useNui";
import { useEffect, useState } from "react";

type BaccaratStage = any;

type BaccaratSeat = {
    source?: string | number;
    wager: number;
    name: string;
    connects: any[];
}

type BaccaratCards = {
    player: Card[];
    banker: Card[];
}

type BaccaratWager = {
    player: number;
    banker: number;
    tie: number;
    suitedPair: number;
    playerPair: number;
    bankerPair: number;
    eitherPair: number;
}

type BaccaratStructure = {
    cards: BaccaratCards;
    wager: BaccaratWager;
    isPlaying: boolean;
}

export function BaccaratComponent({baccarat, onClick} : {baccarat: BaccaratStructure, onClick?: (data: any) => void}) {
    const { config } = useConfig();
    const cards = baccarat.cards;
    const baccaratWager = baccarat.wager;
    const isPlaying = baccarat.isPlaying;
    const chips = config.chips || [];
    return (
        <div className="flex flex-row relative gap-[2px]" style={{cursor: !isPlaying ? "pointer" : "default"}}>
            <div className="flex flex-col w-[120px] bg-background/95 rounded-tl-md rounded-bl-md">
                <div className="relative flex flex-col items-center justify-center h-full border-b p-2" onClick={() => onClick && onClick({type: "suited"})}>
                    <div className="font-bold text-lg"><Translate id="baccarat_suited" /></div>
                    <div className="font-semibold text-xs text-zinc-400"><Translate id="baccarat_suited_desc1" /></div>
                    <div className="font-semibold text-xs text-zinc-400"><Translate id="baccarat_suited_desc2" /></div>
                    <div className="absolute pointer-events-none top-[50%] left-[50%] z-10" style={{transform: "translate(-50%, -50%)"}}>
                        {baccaratWager.suitedPair > 0 && (
                            <div className="p-2 rounded-full shadow-lg" style={{
                                zIndex: 10,
                            }}>
                                <ChipDisplay chip={GetChipForValue(baccaratWager.suitedPair, chips, true)} size={42} />
                            </div>
                        )}
                    </div>
                </div>
                <div className="relative flex flex-col items-center justify-center p-2" onClick={() => onClick && onClick({type: "playerpair"})}>
                    <div className="font-bold text-lg"><Translate id="baccarat_playerpair" /></div>
                    <div className="font-semibold text-xs text-zinc-400"><Translate id="baccarat_playerpair_desc" /></div>
                    <div className="absolute pointer-events-none top-[50%] left-[50%] z-10" style={{transform: "translate(-50%, -50%)"}}>
                        {baccaratWager.playerPair > 0 && (
                            <div className="p-2 rounded-full shadow-lg" style={{
                                zIndex: 10,
                            }}>
                                <ChipDisplay chip={GetChipForValue(baccaratWager.playerPair, chips, true)} size={42} />
                            </div>
                        )}
                    </div>
                </div>
            </div>
            <div className="relative flex flex-col w-[150px] justify-between bg-blue-600/50" onClick={() => onClick && onClick({type: "player"})}>
                <div className="flex flex-col justify-center px-2 py-1 gap-0">
                    <div className="flex flex-row items-center justify-between">
                        <div className="font-bold text-lg"><Translate id="baccarat_player" /></div>
                        <div className="font-semibold text-sm text-zinc-400"><Translate id="baccarat_player_desc" /></div>
                    </div>
                    <div className="font-semibold text-lg text-zinc-400">9</div>
                </div>
                <div className="p-2">
                    <CardsDisplay cards={cards.player} direction="right" height={80} />
                </div>
                <div className="absolute pointer-events-none top-[50%] left-[50%] z-10" style={{transform: "translate(-50%, -50%)"}}>
                        {baccaratWager.player > 0 && (
                            <div className="p-2 rounded-full" style={{
                                zIndex: 10,
                            }}>
                                <ChipDisplay chip={GetChipForValue(baccaratWager.player, chips, true)} size={42} />
                            </div>
                        )}
                    </div>
            </div>
            <div className="flex flex-col absolute top-1/2 left-1/2 z-[20] transform -translate-x-1/2 -translate-y-1/2 rounded-full w-[75px] h-[75px] shadow-lg bg-green-600/95" onClick={() => onClick && onClick({type: "tie"})}>
                <div className="flex flex-col items-center justify-center h-full px-2">
                    <div className="font-bold text-lg"><Translate id="baccarat_tie" /></div>
                    <div className="font-semibold text-sm text-zinc-800/50"><Translate id="baccarat_tie_desc" /></div>
                </div>
                <div className="absolute pointer-events-none top-[50%] left-[50%] z-10" style={{transform: "translate(-50%, -50%)"}}>
                    {baccaratWager.tie > 0 && (
                        <div className="p-2 rounded-full shadow-lg" style={{
                            zIndex: 10,
                        }}>
                            <ChipDisplay chip={GetChipForValue(baccaratWager.tie, chips, true)} size={42} />
                        </div>
                    )}
                </div>
            </div>
            <div className="relative flex flex-col w-[150px] bg-red-600/50" onClick={() => onClick && onClick({type: "banker"})}>
                <div className="flex flex-col justify-center px-2 py-1 gap-0">
                    <div className="flex flex-row items-center justify-between">
                        <div className="font-semibold text-sm text-zinc-400"><Translate id="baccarat_banker_desc" /></div>
                        <div className="font-bold text-lg"><Translate id="baccarat_banker" /></div>
                    </div>
                    <div className="flex justify-end">
                        <div className="font-semibold text-lg text-zinc-400">9</div>
                    </div>
                </div>
                <div className="flex justify-end p-2">
                    <CardsDisplay cards={cards.player} direction="left" height={80} />
                </div>
                <div className="absolute pointer-events-none top-[50%] left-[50%] z-10" style={{transform: "translate(-50%, -50%)"}}>
                    {baccaratWager.banker > 0 && (
                        <div className="p-2 rounded-full shadow-lg" style={{
                            zIndex: 10,
                        }}>
                            <ChipDisplay chip={GetChipForValue(baccaratWager.banker, chips, true)} size={42} />
                        </div>
                    )}
                </div>
            </div>
            <div className="flex flex-col w-[120px] bg-background/95 rounded-tr-md rounded-br-md">
                <div className="relative flex flex-col items-center justify-center h-full border-b p-2" onClick={() => onClick && onClick({type: "eitherpair"})}>
                    <div className="font-bold text-lg"><Translate id="baccarat_eitherpair" /></div>
                    <div className="font-semibold text-xs text-zinc-400"><Translate id="baccarat_eitherpair_desc" /></div>
                    <div className="absolute pointer-events-none top-[50%] left-[50%] z-10" style={{transform: "translate(-50%, -50%)"}}>
                        {baccaratWager.eitherPair > 0 && (
                            <div className="p-2 rounded-full shadow-lg" style={{
                                zIndex: 10,
                            }}>
                                <ChipDisplay chip={GetChipForValue(baccaratWager.eitherPair, chips, true)} size={42} />
                            </div>
                        )}
                    </div>
                </div>
                <div className="relative flex flex-col items-center justify-center p-2" onClick={() => onClick && onClick({type: "bankerpair"})}>
                    <div className="font-bold text-lg"><Translate id="baccarat_bankerpair" /></div>
                    <div className="font-semibold text-xs text-zinc-400"><Translate id="baccarat_bankerpair_desc" /></div>
                    <div className="absolute pointer-events-none top-[50%] left-[50%] z-10" style={{transform: "translate(-50%, -50%)"}}>
                        {baccaratWager.bankerPair > 0 && (
                            <div className="p-2 rounded-full shadow-lg" style={{
                                zIndex: 10,
                            }}>
                                <ChipDisplay chip={GetChipForValue(baccaratWager.bankerPair, chips, true)} size={42} />
                            </div>
                        )}
                    </div>
                </div>
            </div>
        </div>
    )
}

export default function Baccarat({game}: {game: CasinoGame}) {
    const wagerLimit = game.data.wagerLimit;
    const currentSeat = game.data.seatId;
    const [money, setMoney] = useState<number>(game.data.money || 0);
    const [seats, setSeats] = useState<BaccaratSeat[]>(game.data.seats);
    const [stage, setStage] = useState<BaccaratStage>(game.data.stage);
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
    useNuiEvent("updateBlackjackStage", (data) => {
        setStage(data.stage);
        setPerformingAction(false);
        if (data.stage.type == "turn") {
            setTurnTimeLeft(data.stage.timeLeft);
        }
    });
    useNuiEvent("updateBlackjackSeats", (data) => {
        setSeats(data.seats);
    });
    return (
        <div className='flex flex-col bg-background/95 absolute w-full px-8 py-8' style={{ 
            height: 272,
            bottom: 0, 
            left: '0', 
            transition: "opacity 0.25s ease-in-out",
        }}>
            <div className="flex justify-between h-full items-center justify-between items-center w-full select-none">
                <div className='flex flex-col gap-2 w-[33.333333%]'>
                    <div className="flex flex-col gap-2">
                        <div className='flex flex-row items-center justify-between gap-2'>
                            <div className='flex flex-row items-center gap-2'>
                                <GameIcon name='blackjack' style={{fill: "yellow", width: 30, height: 30}} />
                                <div className='font-bold text-2xl'><Translate id="baccarat_title" /></div>
                            </div>
                            <div className='font-bold text-md text-zinc-400'>
                                {stage.type === "waiting" && <Translate id="baccarat_nextround" args={[stage.time]} />}
                                {stage.type === "dealing" && <Translate id="baccarat_dealing" />}
                                {stage.type === "displayCard" && <Translate id="baccarat_displaycard" />}
                                {stage.type === "turn" && (currentSeat == stage.seat ? <Translate id="baccarat_playerturn" args={[turnTimeLeft]} /> : <Translate id="baccarat_otherturn" args={[stage.seatId]} />)}
                                {/* {stage.type === "results" && (
                                    stage.seatResults[currentSeat].won > 0 ? (
                                        <div className="text-green-400">
                                            <Translate id="baccarat_won" args={[GetCurrencyString(stage.seatResults[currentSeat].won, config)]} />
                                        </div>
                                    ) : (
                                        <div className="text-red-400">
                                            <Translate id="baccarat_lost" />
                                        </div>
                                    )
                                )} */}
                            </div>
                        </div>
                        <div className="font-semibold text-md text-zinc-400"><Translate id="baccarat_desc" /></div>
                    </div>
                    {(currentSeat && stage.type !== "waiting") && (<div className="flex flex-row items-center justify-between w-full gap-2">
                    </div>)}
                </div>
                <div className="flex flex-col gap-2 items-center w-[33.333333%] px-8">
                    {<BaccaratComponent baccarat={{
                        cards: {
                            player: [],
                            banker: []
                        },
                        wager: {
                            player: 0,
                            banker: 0,
                            tie: 0,
                            suitedPair: 0,
                            playerPair: 0,
                            bankerPair: 0,
                            eitherPair: 0
                        },
                        isPlaying: stage.type !== "waiting"
                    }} onClick={(data: any) => {
                        if (stage.type !== "waiting") return;
                    }}/>}
                    {/* {stage.type === "waiting" ? (
                        <WagerComponent betRange={wagerLimit} money={money} wager={0} setWager={(value) => {
                            fetchNui("setBlackjackWager", {
                                wager: value
                            });
                        }} />
                    ) : (
                        <div className='flex flex-row items-center justify-between gap-2 border p-2 rounded-md w-full'>
                            <div className="flex flex-row gap-2 items-center">
                                <div className="font-bold text-lg">Dealer's Hand:</div>
                            </div>
                        </div>
                    )} */}
                </div>
                <div className="flex flex-col gap-2 w-[33.333333%]">
                    <div className="grid grid-cols-2 gap-2 w-full">
                        {seats.map((player, index) => {
                            return player.source ? (<div className="flex flex-row gap-2 justify-between items-center w-full border p-2 rounded-md" key={index}>
                                <div className="flex flex-col gap-2 w-full">
                                    <div className="flex flex-row gap-2 justify-between items-center">
                                        <div className='font-bold text-lg truncate' style={{
                                        }}>{player.name}</div>
                                    </div>
                                    <div className="font-semibold text-md text-zinc-400"><AnimatedValue value={player.wager} /></div>
                                </div>
                            </div>) : (
                                <div className="flex flex-row gap-2 justify-center items-center w-full border p-2 rounded-md" key={index}>
                                    <div className="font-bold text-lg truncate text-zinc-600" style={{
                                    }}>Empty Seat</div>
                                </div>
                            )
                        })}
                    </div>
                </div>
            </div>
        </div>
    )
}