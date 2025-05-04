import { AnimatedValue, Card, CardsDisplay, CasinoGame, ChipDisplay, DisplayCurrency, GameIcon, GetCurrencyString, WagerComponent } from "@/components/casino/Casino";
import { Button } from "@/components/ui/button";
import { useConfig } from "@/providers/config";
import { Translate } from "@/providers/locale/Locale";
import { fetchNui } from "@/providers/nui/fetchNui";
import { useNuiEvent } from "@/providers/nui/useNui";
import { useEffect, useState } from "react";

type BlackjackStage = any;

type BlackjackSeat = {
    source?: string | number;
    wager: number;
    name: string;
    currentHand: number;
    hands: Card[][];
}

function IsSplittable(cards: Card[]) {
    if (cards.length != 2) return false;
    let card1 = BlackjackCardValue([cards[0]]);
    let card2 = BlackjackCardValue([cards[1]]);
    return (card1.value == card2.value)
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
    if (secondaryValue == 21) {
        value = 21
        secondaryValue = 0
    }
    return {value, secondaryValue}
}

export default function Blackjack({game} : {game: CasinoGame}) {
    const { config } = useConfig();
    const wagerLimit = game.data.wagerLimit;
    const currentSeat = game.data.seatId;
    const [money, setMoney] = useState<number>(game.data.money || 0);
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
    useNuiEvent("updateBalance", (data) => {
        setMoney(data.balance);
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
    const canPlayerPerformAction = (action: "hit" | "stand" | "double" | "split") => {
        if (stage.type !== "turn") return false;
        if (currentSeat !== stage.seat) return false;
        let seat = seats[currentSeat];
        if (action == "split" && !(IsSplittable(seat.hands[seat.currentHand]) && seat.hands[1].length == 0)) return false;
        if (action == "double" && seat.hands[seat.currentHand].length > 2) return false;
        return true
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
                                <div className='font-bold text-2xl'><Translate id="blackjack_title" /></div>
                            </div>
                            <div className='font-bold text-md text-zinc-400'>
                                {stage.type === "waiting" && <Translate id="blackjack_nextround" args={[stage.time]} />}
                                {stage.type === "dealing" && <Translate id="blackjack_dealing" />}
                                {stage.type === "displayCard" && <Translate id="blackjack_displaycard" />}
                                {stage.type === "turn" && (currentSeat == stage.seat ? <Translate id="blackjack_playerturn" args={[turnTimeLeft]} /> : <Translate id="blackjack_otherturn" args={[stage.seat]} />)}
                                {/* {stage.type === "results" && (
                                    stage.seatResults[currentSeat].won > 0 ? (
                                        <div className="text-green-400">
                                            <Translate id="blackjack_won" args={[GetCurrencyString(stage.seatResults[currentSeat].won, config)]} />
                                        </div>
                                    ) : (
                                        <div className="text-red-400">
                                            <Translate id="blackjack_lost" />
                                        </div>
                                    )
                                )} */}
                            </div>
                        </div>
                        <div className="font-semibold text-md text-zinc-400"><Translate id="blackjack_desc" /></div>
                    </div>
                    {(currentSeat && stage.type !== "waiting") && (<div className="flex flex-row items-center justify-between w-full gap-2">
                        <div className='flex flex-col gap-2 w-full'>
                            <div className="flex flex-row gap-2 justify-between items-center min-w-64">
                                <div className='font-bold text-xl'><Translate id="blackjack_hand" args={[seats[currentSeat].currentHand + 1]} /></div>
                                {playerHand.value > 0 && <div className='font-bold text-xl text-zinc-400'>
                                    {playerHand.value}{playerHand.secondaryValue > 0 && `/${playerHand.secondaryValue}`}
                                </div>}
                            </div>
                            <div className='grid grid-cols-2 gap-1 w-full'>
                                <Button variant={"secondary"} disabled={!canPlayerPerformAction("hit")} onClick={() => {
                                    performAction("hit");
                                }}><Translate id="blackjack_hit" /></Button>
                                <Button variant={"secondary"} disabled={!canPlayerPerformAction("stand")} onClick={() => {
                                    performAction("stand");
                                }}><Translate id="blackjack_stand" /></Button>
                                <Button variant={"secondary"} disabled={!canPlayerPerformAction("double")} onClick={() => {
                                    performAction("double");
                                }}><Translate id="blackjack_double" /></Button>
                                <Button variant={"secondary"} disabled={!canPlayerPerformAction("split")} onClick={() => {
                                    performAction("split");
                                }}><Translate id="blackjack_split" /></Button>
                            </div>
                        </div>
                        <CardsDisplay cards={seats[currentSeat].hands[seats[currentSeat].currentHand]} direction="right" height={108} />
                    </div>)}
                </div>
                <div className="flex flex-col gap-2 items-center w-[33.333333%] px-8">
                    {stage.type === "waiting" ? (
                        <WagerComponent wagerData={{ game: "blackjack" }} betRange={wagerLimit} money={money} wager={0} setWager={(value) => {
                            fetchNui("setBlackjackWager", {
                                wager: value
                            });
                        }} />
                    ) : (
                        <div className='flex flex-row items-center justify-between gap-2 border p-2 rounded-md w-full'>
                            <div className="flex flex-row gap-2 items-center">
                                <div className="font-bold text-lg"><Translate id="blackjack_dealerhand"/>:</div>
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
                                    <div className="font-semibold text-md text-zinc-400"><AnimatedValue value={player.wager} /></div>
                                </div>
                                <div className="flex flex-row justify-end gap-2 items-center">
                                    {playerHand.value > 0 && <div className="font-semibold text-sm text-zinc-400">{playerHand.value}{playerHand.secondaryValue > 0 && `/${playerHand.secondaryValue}`}</div>}
                                    <CardsDisplay cards={player.hands[player.currentHand]} height={48} direction="right" />
                                </div>
                            </div>) : (
                                <div className="flex flex-row gap-2 justify-center items-center w-full border p-2 rounded-md" key={index}>
                                    <div className="font-bold text-lg truncate text-zinc-600" style={{
                                        maxWidth: 200 - (8 * (player.hands[player.currentHand].length - 1)),
                                    }}><Translate id="empty_seat"/></div>
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