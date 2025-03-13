import { Card, CardsDisplay, CasinoGame, DisplayCurrency, GameIcon, GetCurrencyString, WagerComponent } from "@/components/casino/Casino";
import { Button } from "@/components/ui/button";
import { useConfig } from "@/providers/config";
import { Translate } from "@/providers/locale/Locale";
import { fetchNui } from "@/providers/nui/fetchNui";
import { useState } from "react";

type BlackjackStage = any;

type BlackjackSeat = {
    source?: string | number;
    name: string;
    currentHand: number;
    hands: [Card[]];
}

export default function Blackjack() {
    const { config } = useConfig();
    const [currentSeat, setCurrentSeat] = useState<number>(1);
    const [seats, setSeats] = useState<BlackjackSeat[]>([
        {
          name: "Dealer",
          currentHand: 0,
          hands: [
            [
              {class: "clubs", value: "ace"},
              {class: "clubs", value: "2"},
            ]
          ]
        },
        {
          name: "Jane Doe",
          currentHand: 0,
          hands: [
            [
              {class: "clubs", value: "ace"},
              {class: "clubs", value: "2"},
            ]
          ]
        },
        {
          source: 1,
          currentHand: 0,
          name: "Johnathaneeeeeeeeeeeeeeeeeeeeeeeeeeeee Doe",
          hands: [
            [
              {class: "clubs", value: "ace"},
              {class: "clubs", value: "2"},
            ]
          ]
        },
        {
          name: "Jennifer Doe",
          currentHand: 0,
          hands: [
            [
              {class: "clubs", value: "ace"},
              {class: "clubs", value: "2"},
            ]
          ]
        },
        {
          source: 1,
          currentHand: 0,
          name: "Janel Doe",
          hands: [
            [
              {class: "clubs", value: "ace"},
              {class: "clubs", value: "2"},
            ]
          ]
        }
    ]);
    const [stage, setStage] = useState<BlackjackStage>({
        type: "waiting",
        seatId: 1,
    });
    const canPlayerPerformAction = (action: "hit" | "stand" | "double" | "split") => {
        if (stage.type !== "turn") return true;
        if (currentSeat !== stage.seatId) return true;
        return false
    }
    const performAction = (action: "hit" | "stand" | "double" | "split") => {
        fetchNui("performBlackjackAction", {
            action: action,
        });
    }
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
                            {stage.type === "turn" && (currentSeat == stage.seatId ? <Translate id="blackjack_playerturn" args={[10]} /> : <Translate id="blackjack_otherturn" args={[stage.seatId]} />)}
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
                <div className="flex flex-row items-center justify-between w-full gap-2">
                    <div className='flex flex-col gap-2 w-full'>
                        <div className="flex flex-row gap-2 justify-between items-center min-w-64">
                            <div className='font-bold text-xl'><Translate id="blackjack_hand" args={[1]} /></div>
                            <div className='font-bold text-xl text-zinc-400'>10/20</div>
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
                    <CardsDisplay cards={seats[1].hands[seats[1].currentHand]} direction="right" height={108} />
                </div>
            </div>
            <div className="flex flex-col gap-2 items-center w-[33.333333%] p-8">
                {stage.type === "waiting" ? (
                    <WagerComponent betRange={[10, 2000]} wager={0} setWager={(value) => console.log(value)} />
                ) : (
                    <div className='flex flex-row items-center justify-between gap-2 border p-2 rounded-md w-full'>
                        <div className="flex flex-row gap-2 items-center">
                            <div className="font-bold text-lg">Dealer's Hand:</div>
                            <div className="font-bold text-zinc-400"> 10/20</div>
                        </div>
                        <CardsDisplay cards={seats[0].hands[seats[0].currentHand]} stacked={false} direction="right" height={72} />
                    </div>
                )}
            </div>
            <div className="flex flex-col gap-2 w-[33.333333%]">
                <div className="grid grid-cols-2 gap-2 w-full">
                {seats.map((player, index) => (index > 0 ? 
                    (player.source ? (<div className="flex flex-row gap-2 justify-between items-center w-full border p-2 rounded-md" key={index}>
                        <div className="flex flex-col gap-2 w-full">
                            <div className="flex flex-row gap-2 justify-between items-center">
                                <div className='font-bold text-lg truncate' style={{
                                maxWidth: 200 - (8 * (player.hands[player.currentHand].length - 1)),
                                }}>{player.name}</div>
                            </div>
                            <div className="font-semibold text-md text-zinc-400">$10,000</div>
                        </div>
                        <div className="flex flex-row justify-end gap-2 items-center">
                            <div className="font-semibold text-sm text-zinc-400">9/19</div>
                            <CardsDisplay cards={player.hands[player.currentHand]} height={48} direction="right" />
                        </div>
                    </div>) : (
                        <div className="flex flex-row gap-2 justify-center items-center w-full border p-2 rounded-md" key={index}>
                            <div className="font-bold text-lg truncate text-zinc-600" style={{
                                maxWidth: 200 - (8 * (player.hands[player.currentHand].length - 1)),
                            }}>Empty Seat</div>
                        </div>
                    )
                ) : null))}
                </div>
            </div>
        </div>
    )
}