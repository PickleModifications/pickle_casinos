import { Card, CardsDisplay, CasinoGame, DisplayCurrency, GameIcon, GetCurrencyString, WagerComponent } from "@/components/casino/Casino";
import { Button } from "@/components/ui/button";
import { useConfig } from "@/providers/config";
import { Translate } from "@/providers/locale/Locale";
import { fetchNui } from "@/providers/nui/fetchNui";
import { useNuiEvent } from "@/providers/nui/useNui";
import { useEffect, useState } from "react";

type BlackjackStage = any;

type BlackjackSeat = {
    source?: string | number;
    name: string;
    currentHand: number;
    hands: [Card[]];
}

export function BlackjackCardValue(cards: Card[]) {
    let value = 0;
    let secondaryValue = 0;
    let aces = 0;
    for (let i=0; i < cards.length; i++) {
        let card = cards[i];
        if (card.value == "ace") {
            aces = aces + 1
            value = value + 1
        }
        else if (card.value == "jack" || card.value == "queen" || card.value == "king") {
            value = value + 10
        }
        else {
            value = value + parseInt(card.value)
        }
    }
    if (aces > 0 && value + 10 <= 21) {
        secondaryValue = value + 10
    }
    return {value, secondaryValue}
}

export default function Blackjack({game} : {game: CasinoGame}) {
    const { config } = useConfig();
    const wagerLimit = game.data.wagerLimit
    const [currentSeat, setCurrentSeat] = useState<number>(game.data.seatId);
    const [seats, setSeats] = useState<BlackjackSeat[]>(game.data.seats);
    const [stage, setStage] = useState<BlackjackStage>(game.data.stage);
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
    useNuiEvent("updateBlackjackSeat", (data) => {
        setCurrentSeat(data.seatId);
    });
    const canPlayerPerformAction = (action: "hit" | "stand" | "double" | "split") => {
        if (stage.type !== "turn") return true;
        if (currentSeat !== stage.seatId) return true;
        return false
    }
    const performAction = (action: "hit" | "stand" | "double" | "split") => {
        setPerformingAction(true);
        fetchNui("performBlackjackAction", {
            action: action,
        });
    }
    const playerHand = BlackjackCardValue(seats[currentSeat].hands[seats[currentSeat].currentHand]);
    const dealerHand = BlackjackCardValue(seats[0].hands[seats[0].currentHand]);
    return (
        <div className="flex row justify-between items-center w-full select-none">
            <div className='flex flex-col gap-2 w-[33.333333%]'>
                <div className="flex flex-col gap-2">
                    <div className='flex flex-row items-center justify-between gap-2'>
                        <div className='flex flex-row items-center gap-2'>
                            <GameIcon name='blackjack' style={{fill: "yellow", width: 30, height: 30}} />
                            <div className='font-bold text-2xl'><Translate id="blackjack_title" /></div>
                        </div>
                        <div className='font-bold text-md text-zinc-400'>
                            {stage.type === "waiting" && <Translate id="blackjack_nextround" args={[10]} />}
                            {stage.type === "dealing" && <Translate id="blackjack_dealing" />}
                            {stage.type === "displayCard" && <Translate id="blackjack_displaycard" />}
                            {stage.type === "turn" && (currentSeat == stage.seatId ? <Translate id="blackjack_playerturn" args={[turnTimeLeft]} /> : <Translate id="blackjack_otherturn" args={[stage.seatId]} />)}
                            {stage.type === "results" && (
                                stage.won > 0 ? (
                                    <div className="text-green-400">
                                        <Translate id="blackjack_won" args={[GetCurrencyString(stage.won, config)]} />
                                    </div>
                                ) : (
                                    <div className="text-red-400">
                                        <Translate id="blackjack_lost" />
                                    </div>
                                )
                            )}
                        </div>
                    </div>
                    <div className="font-semibold text-md text-zinc-400"><Translate id="blackjack_desc" /></div>
                </div>
                {currentSeat && (<div className="flex flex-row items-center justify-between w-full gap-2">
                    <div className='flex flex-col gap-2 w-full'>
                        <div className="flex flex-row gap-2 justify-between items-center min-w-64">
                            <div className='font-bold text-xl'><Translate id="blackjack_hand" args={[1]} /></div>
                            {playerHand.value > 0 && <div className='font-bold text-xl text-zinc-400'>
                                {playerHand.value}{playerHand.secondaryValue > 0 && `/${playerHand.secondaryValue}`}
                            </div>}
                        </div>
                        <div className='grid grid-cols-2 gap-1 w-full'>
                            <Button variant={"secondary"} disabled={canPlayerPerformAction("hit")} onClick={() => {
                                performAction("hit");
                            }}><Translate id="blackjack_hit" /></Button>
                            <Button variant={"secondary"} disabled={canPlayerPerformAction("stand")} onClick={() => {
                                performAction("stand");
                            }}><Translate id="blackjack_stand" /></Button>
                            <Button variant={"secondary"} disabled={canPlayerPerformAction("double")} onClick={() => {
                                performAction("double");
                            }}><Translate id="blackjack_double" /></Button>
                            <Button variant={"secondary"} disabled={canPlayerPerformAction("split")} onClick={() => {
                                performAction("split");
                            }}><Translate id="blackjack_split" /></Button>
                        </div>
                    </div>
                    <CardsDisplay cards={seats[currentSeat].hands[seats[currentSeat].currentHand]} direction="right" height={108} />
                </div>)}
            </div>
            <div className="flex flex-col gap-2 items-center w-[33.333333%] p-8">
                {stage.type === "waiting" ? (
                    <WagerComponent betRange={wagerLimit} wager={0} setWager={(value) => console.log(value)} />
                ) : (
                    <div className='flex flex-row items-center justify-between gap-2 border p-2 rounded-md w-full'>
                        <div className="flex flex-row gap-2 items-center">
                            <div className="font-bold text-lg">Dealer's Hand:</div>
                            {dealerHand.value > 0 && <div className="font-bold text-zinc-400 text-lg">{dealerHand.value}{dealerHand.secondaryValue > 0 && `/${dealerHand.secondaryValue}`}</div>}
                        </div>
                        {seats[0].hands[seats[0].currentHand].length > 0 ? <CardsDisplay cards={seats[0].hands[seats[0].currentHand]} stacked={false} direction="right" height={72} /> : <div style={{height: 72}}></div>}
                    </div>
                )}
            </div>
            <div className="flex flex-col gap-2 w-[33.333333%]">
                <div className="grid grid-cols-2 gap-2 w-full">
                    {seats.map((player, index) => {
                        const playerHand = BlackjackCardValue(player.hands[player.currentHand]);
                        return (index > 0 && (player.source ? (<div className="flex flex-row gap-2 justify-between items-center w-full border p-2 rounded-md" key={index}>
                            <div className="flex flex-col gap-2 w-full">
                                <div className="flex flex-row gap-2 justify-between items-center">
                                    <div className='font-bold text-lg truncate' style={{
                                    maxWidth: 200 - (8 * (player.hands[player.currentHand].length - 1)),
                                    }}>{player.name}</div>
                                </div>
                                <div className="font-semibold text-md text-zinc-400">$10,000</div>
                            </div>
                            <div className="flex flex-row justify-end gap-2 items-center">
                                {playerHand.value > 0 && <div className="font-semibold text-sm text-zinc-400">{playerHand.value}{playerHand.secondaryValue > 0 && `/${playerHand.secondaryValue}`}</div>}
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
    )
}