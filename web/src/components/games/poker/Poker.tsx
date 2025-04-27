import { Card, CardsDisplay, CasinoGame, DisplayCurrency } from "@/components/casino/Casino"
import { Button } from "@/components/ui/button"
import { Translate } from "@/providers/locale/Locale"
import { fetchNui } from "@/providers/nui/fetchNui"
import { useNuiEvent } from "@/providers/nui/useNui"
import { useEffect, useState } from "react"

const SEAT_OFFSETS = [
    { x: 400, y: 100 },
    { x: 200, y: 300 },
    { x: 200, y: 650 },
    { x: 400, y: 850 },
    { x: 650, y: 900 },
    { x: 950, y: 900 },
    { x: 1300, y: 850 },
    { x: 1500, y: 650 },
    { x: 1500, y: 300 },
    { x: 1300, y: 100 },
    // { x: 100, y: 100 },
    // { x: 100, y: 100 },
    // { x: 100, y: 100 },
    // { x: 100, y: 100 },
    // { x: 100, y: 100 },
    // { x: 100, y: 100 },
    // { x: 100, y: 100 },
    // { x: 100, y: 100 },
]

type PokerBet = {
    wagered?: number,
    amount?: number,
    type: "all" | "call" | "check" | "raise" | "fold",
}

type PokerSeats = {
    source?: number,
    name: string,
    cards: Card[],
    balance: number,
    totalWager: number,
    bet?: PokerBet,
    blind?: "big" | "small" | "none",
    rank?: string,
}

function DisplayPokerBet({bet} : {bet: PokerBet}) {
    return (
        <div className="text-zinc-400 text-sm font-semibold whitespace-nowrap">
            {(bet.type == "all" || bet.type == "call" || bet.type == "raise") && (
                <><Translate id={"poker_" + bet.type}/> <DisplayCurrency value={bet.amount || -1}/></>
            )}
            {(bet.type == "check" || bet.type == "fold") && (
                <Translate id={"poker_" + bet.type}/>
            )}
        </div>
    )
}

export default function Poker({game} : {game: CasinoGame}) {
    const [seats, setSeats] = useState<PokerSeats[]>(game.data.seats || [])
    const [stage, setStage] = useState<any>(game.data.stage || {type: "waiting"})
    const [bet, setBet] = useState<{value: number, type: "bet" | "raise"} | null>(null)
    const [pot, setPot] = useState<number>(0)
    const [timer, setTimer] = useState<number>(0)
    const [dealerCards, setDealerCards] = useState<Card[]>(game.data.dealerCards || [])
    const bigBlind = game.data.bigBlind || 0
    const smallBlind = game.data.smallBlind || 0
    const currentSeat = game.data.seatId ? game.data.seatId - 1 : 0
    useNuiEvent("updatePokerSeats", (data) => {
        setSeats(data.seats)
    })
    useNuiEvent("updatePokerStage", (data) => {
        console.log(JSON.stringify(data))
        setStage(data.stage)
        if (data.stage.type == "seatTurn") {
            setTimer(data.stage.time)
        }
    })
    useNuiEvent("updatePokerDealerCards", (data) => {
        setDealerCards(data.cards)
    })
    useNuiEvent("updatePokerPot", (data) => {
        setPot(data.pot)
    })
    useNuiEvent("updatePokerSeatAction", (data) => {
        setSeats((prev) => {
            const newSeats = [...prev]
            const seatId = data.seatId - 1
            if (seatId >= 0 && seatId < newSeats.length) {
                newSeats[seatId] = {
                    ...newSeats[seatId],
                    bet: data.bet,
                    balance: data.balance == undefined ? newSeats[seatId].balance : data.balance,
                }
            }
            return newSeats
        });
    });
    useEffect(() => {
        const interval = setInterval(() => {
            if (timer > 0) {
                setTimer((prev) => prev - 1)
            }
        }, 1000)
        return () => clearInterval(interval)
    }, [timer])
    return (
        <div className='flex flex-col absolute w-full h-full px-8 py-8' style={{
            bottom: 0, 
            left: '0', 
            transition: "opacity 0.25s ease-in-out",
            // backgroundImage: (`url("/nui/images/poker/debug.png")`),
        }}>
            {stage.type !== "waiting" && (<div className="absolute top-0 left-[50%] -translate-x-[50%] -translate-y-[0%] pt-8">
                <div className="flex flex-row items-center w-full p-2 bg-background/95 rounded-md">
                    {Array.from({length: 5}).map((_, index) => (
                        <CardsDisplay key={index} direction="right" height={75} cards={[dealerCards[4 - index] || {class: "hidden", value: "hidden"}]} />
                    ))}
                </div>
            </div>)}
            {SEAT_OFFSETS.map((offset, index) => seats[index]?.source && (
                <div className="absolute" style={{
                    left: `${offset.x}px`,
                    top: `${offset.y}px`,
                }} key={index}>
                    <div className="flex flex-row gap-2">
                        <div className="flex flex-col gap-2 p-2 bg-background/95 rounded-md">
                            <div className="flex flex-row items-center gap-4 justify-between">
                                <div className="flex flex-row gap-2 items-center">
                                    <div className="text-xl font-bold">{seats[index].name}</div>
                                    {(seats[index].blind && seats[index].blind != "none") && (
                                        <div className="text-zinc-400 text-sm font-bold"><Translate id={"poker_blind_" + seats[index].blind}/></div>
                                    )}
                                </div>
                                <div className="text-zinc-400 text-sm font-semibold"><DisplayCurrency value={seats[index].balance} /></div>
                            </div>
                            {seats[index].cards.length > 0 && (
                                <div className="flex flex-row items-center gap-2 justify-between">
                                <div className="flex flex-row items-center w-full">
                                    {seats[index].cards.map((card, cardIndex) => (
                                        <CardsDisplay key={cardIndex} direction="right" height={75} cards={[card]} />
                                    ))}
                                </div>
                                <div className="flex flex-col gap-0 items-start">
                                    {(seats[index].rank != undefined) && (<div className="flex flex-row gap-2 items-center">
                                        <div className="text-zinc-400 text-xs font-semibold">{seats[index].rank}</div>
                                    </div>)}
                                    <div className="flex flex-row items-center gap-4 justify-between">
                                        {seats[index].bet && <DisplayPokerBet bet={seats[index].bet} />}
                                    </div>
                                </div>
                                </div>
                            )}
                        </div>
                        <div className="flex flex-col gap-2 p-2">
                            {(stage.type == "seatTurn" && stage.seat == index + 1) && (
                                <div className="font-bold text-zinc-400 text-md">
                                    {timer}
                                </div>
                            )}
                            {(seats[index].blind && seats[index].blind == "small") && (
                                <div className="mt-2 w-6 h-6 relative rounded-full text-red-600 font-bold bg-white/95 border-2 border-zinc-800 flex items-center justify-center">
                                    <span className="absolute left-[4px]">D</span>
                                </div>
                            )}
                        </div>
                    </div>
                </div>
            ))}
            <div className="absolute top-[50%] left-[50%] -translate-x-[50%] -translate-y-[50%]">
                <div className="flex flex-col gap-2">
                    {stage.type == "waiting" ? (
                        <div className="flex flex-row min-w-[200px] justify-center items-center gap-2 p-2 bg-background/95 rounded-md">
                            <div className="text-zinc-400 text-sm font-bold"><Translate id="poker_nextround" args={[stage.time]}/></div>
                        </div>
                    ) : (
                        <div className="flex flex-row min-w-[200px] justify-between items-center gap-2 p-2 bg-background/95 rounded-md">
                            <div className="text-zinc-400 text-sm font-bold">POT</div>
                            <div className="text-sm font-semibold"><DisplayCurrency value={pot}/></div>
                        </div>
                    )}
                    {(stage.type == "seatTurn" && currentSeat == stage.seat - 1) && (
                        <div className="flex flex-row min-w-[200px] justify-between items-center gap-2 p-2 bg-background/95 rounded-md">
                            {(stage.minimumBet > 0) && (<div className="text-zinc-400 text-sm font-bold"><Translate id={"poker_min_bet"} args={[stage.minimumBet]}/></div>)}
                            {bet ? (
                                <div className="flex flex-col gap-2 w-full">
                                    <div className="flex flex-row items-center gap-2  text-sm font-bold justify-between w-full">
                                        <div className="text-zinc-400"><Translate id={"poker_" + bet.type}/></div>
                                        <div><DisplayCurrency value={bet.value}/></div>
                                    </div>
                                    <div className="flex flex-row items-center gap-2">
                                        <input 
                                            type="range" 
                                            min={stage.minimumBet <= 0 ? smallBlind : stage.minimumBet + smallBlind} 
                                            max={seats[currentSeat].balance} 
                                            value={bet.value}
                                            onChange={(e) => setBet({type: bet.type, value: parseInt(e.target.value)})}
                                            className="w-full h-2 bg-zinc-700 rounded-lg appearance-none cursor-pointer accent-zinc-400"
                                        />
                                    </div>
                                    <div className="flex flex-row items-center gap-2">
                                        <Button variant="secondary" className="w-full" onClick={() => {
                                            fetchNui("sendPokerAction", {
                                                type: "raise",
                                                value: bet.value,
                                            })
                                            setBet(null)
                                        }} ><Translate id={"poker_" + bet.type}/> </Button>
                                        <Button variant="secondary" className="w-full" onClick={() => {
                                            setBet(null)
                                        }}><Translate id="poker_back"/></Button>
                                    </div>
                                </div>
                            ) : (
                                <>
                                    {seats[currentSeat].balance <= stage.minimumBet ? <Button variant="secondary" disabled={
                                        stage.minimumBet <= 0
                                    } onClick={() => {
                                        fetchNui("sendPokerAction", {
                                            type: "all",
                                        })
                                    }}><Translate id="poker_all"/> </Button> : <Button variant="secondary" disabled={
                                        stage.minimumBet <= 0
                                    } onClick={() => {
                                        fetchNui("sendPokerAction", {
                                            type: "call",
                                        })
                                    }}><Translate id="poker_call"/> </Button>}
                                    <Button variant="secondary" disabled={seats[currentSeat].balance <= stage.minimumBet} onClick={() => {
                                        setBet({type: (stage.minimumBet <= 0 ? "bet" : "raise"), value: (stage.minimumBet <= 0 ? smallBlind : stage.minimumBet + smallBlind)})
                                    }}><Translate id={"poker_" + (stage.minimumBet <= 0 ? "bet" : "raise")}/> </Button>
                                    <Button variant="secondary" disabled={stage.minimumBet > 0} onClick={() => {
                                        fetchNui("sendPokerAction", {
                                            type: "check",
                                        })
                                    }}><Translate id="poker_check"/> </Button>
                                    <Button variant="secondary"><Translate id="poker_fold"/> </Button>
                                </>
                            )}
                        </div>
                    )}
                </div>
            </div>
        </div>
    )
}