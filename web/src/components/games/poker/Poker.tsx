import { Card, CardsDisplay, CasinoGame, DisplayCurrency } from "@/components/casino/Casino"
import { Button } from "@/components/ui/button"
import { Translate } from "@/providers/locale/Locale"
import { useNuiEvent } from "@/providers/nui/useNui"
import { useState } from "react"

const SEAT_OFFSETS = [
    { x: 400, y: 100 },
    { x: 200, y: 300 },
    { x: 200, y: 650 },
    { x: 400, y: 850 },
    { x: 650, y: 960 },
    { x: 950, y: 960 },
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
    bet?: PokerBet,
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
    const [seats, setSeats] = useState<PokerSeats[]>([
        {source: 1, name: "Pickle Modington", cards: [{class: "hrt", value: "ace"}, {class: "hidden", value: ""}], balance: 0},
        {source: 1, name: "Pickle Modington", cards: [{class: "hrt", value: "ace"}, {class: "hidden", value: ""}], balance: 0},
        {source: 1, name: "Pickle Modington", cards: [{class: "hrt", value: "ace"}, {class: "hidden", value: ""}], balance: 0},
        {source: 1, name: "Pickle Modington", cards: [{class: "hrt", value: "ace"}, {class: "hidden", value: ""}], balance: 0},
        {source: 1, name: "Pickle Modington", cards: [{class: "hrt", value: "ace"}, {class: "hidden", value: ""}], balance: 0},
        {source: 1, name: "Pickle Modington", cards: [{class: "hrt", value: "ace"}, {class: "hidden", value: ""}], balance: 0},
        {source: 1, name: "Pickle Modington", cards: [{class: "hrt", value: "ace"}, {class: "hidden", value: ""}], balance: 0},
        {source: 1, name: "Pickle Modington", cards: [{class: "hrt", value: "ace"}, {class: "hidden", value: ""}], balance: 0},
        {source: 1, name: "Pickle Modington", cards: [{class: "hrt", value: "ace"}, {class: "hidden", value: ""}], balance: 0},
        {source: 1, name: "Pickle Modington", cards: [{class: "hrt", value: "ace"}, {class: "hidden", value: ""}], balance: 0},
    ])
    const [stage, setStage] = useState<any>({type: "seatTurn", seatId: 1, minimumBet: 0})//game.data.stage || {type: "UNK"})
    const [bet, setBet] = useState<{value: number, type: "bet" | "raise"} | null>(null)
    const currentSeat = game.data.seatId ? game.data.seatId - 1 : 0
    useNuiEvent("updatePokerSeats", (data) => {
        setSeats(data.seats)
    })
    useNuiEvent("updatePokerStage", (data) => {
        setStage(data.stage)
    })
    return (
        <div className='flex flex-col absolute w-full h-full px-8 py-8' style={{
            bottom: 0, 
            left: '0', 
            transition: "opacity 0.25s ease-in-out",
            backgroundImage: (`url("/nui/images/poker/debug.png")`),
        }}>
            {SEAT_OFFSETS.map((offset, index) => seats[index]?.source && (
                <div className="absolute" style={{
                    left: `${offset.x}px`,
                    top: `${offset.y}px`,
                }} key={index}>
                    <div className="flex flex-row gap-2 items-center">
                        <div className="flex flex-col gap-2 p-2 bg-background/95 rounded-md">
                            <div className="flex flex-row items-center gap-4 justify-between">
                                <div className="text-xl font-bold">{seats[index].name}</div>
                                <div className="text-zinc-400 text-sm font-semibold"><DisplayCurrency value={seats[index].balance} /></div>
                            </div>
                            <div className="flex flex-row items-center gap-2 justify-between">
                                <div className="flex flex-row items-center w-full">
                                    {seats[index].cards.map((card, cardIndex) => (
                                        <CardsDisplay key={cardIndex} direction="right" height={50} cards={[card]} />
                                    ))}
                                </div>
                                <div className="flex flex-col gap-0 items-start">
                                    <div className="flex flex-row gap-2 items-center">
                                        <div className="text-zinc-400 text-xs font-semibold">Flush</div>
                                        <div className="text-zinc-400 text-sm font-bold">82%</div>
                                    </div>
                                    <div className="flex flex-row items-center gap-4 justify-between">
                                        {seats[index].bet && <DisplayPokerBet bet={seats[index].bet} />}
                                    </div>
                                </div>
                            </div>
                        </div>
                        <div className="w-6 h-6 relative rounded-full text-red-600 font-bold bg-white/95 border-2 border-zinc-800 flex items-center justify-center">
                            <span className="absolute left-[4.5px]">D</span>
                        </div>
                    </div>
                </div>
            ))}
            <div className="absolute top-[50%] left-[50%] -translate-x-[50%] -translate-y-[50%]">
                <div className="flex flex-col gap-2">
                    <div className="flex flex-row min-w-[200px] justify-between items-center gap-2 p-2 bg-background/95 rounded-md">
                        <div className="text-zinc-400 text-sm font-bold">POT</div>
                        <div className="text-sm font-semibold">$100,000,000</div>
                    </div>
                    <div className="flex flex-row min-w-[200px] justify-between items-center gap-2 p-2 bg-background/95 rounded-md">
                        {bet ? (
                            <div className="flex flex-col gap-2 w-full">
                                <div className="flex flex-row items-center gap-2  text-sm font-bold justify-between w-full">
                                    <div className="text-zinc-400"><Translate id={"poker_" + bet.type}/></div>
                                    <div><DisplayCurrency value={bet.value}/></div>
                                </div>
                                <div className="flex flex-row items-center gap-2">
                                    <input 
                                        type="range" 
                                        min={stage.minimumBet <= 0 ? 1 : stage.minimumBet} 
                                        max={seats[currentSeat].balance} 
                                        value={bet.value}
                                        onChange={(e) => setBet({type: bet.type, value: parseInt(e.target.value)})}
                                        className="w-full h-2 bg-zinc-700 rounded-lg appearance-none cursor-pointer accent-zinc-400"
                                    />
                                </div>
                                <div className="flex flex-row items-center gap-2">
                                    <Button variant="secondary" className="w-full"><Translate id={"poker_" + bet.type}/> </Button>
                                    <Button variant="secondary" className="w-full" onClick={() => {
                                        setBet(null)
                                    }}><Translate id="poker_back"/></Button>
                                </div>
                            </div>
                        ) : (
                            <>
                                {seats[currentSeat].balance <= stage.minimumBet ? <Button variant="secondary"><Translate id="poker_all"/> </Button> : <Button variant="secondary"><Translate id="poker_call"/> </Button>}
                                <Button variant="secondary" disabled={seats[currentSeat].balance <= stage.minimumBet} onClick={() => {
                                    setBet({type: (stage.minimumBet <= 0 ? "bet" : "raise"), value: (stage.minimumBet <= 0 ? 1 : stage.minimumBet)})
                                }}><Translate id={"poker_" + (stage.minimumBet <= 0 ? "bet" : "raise")}/> </Button>
                                <Button variant="secondary" disabled={stage.minimumBet > 0}><Translate id="poker_check"/> </Button>
                                <Button variant="secondary"><Translate id="poker_fold"/> </Button>
                            </>
                        )}
                    </div>
                </div>
            </div>
        </div>
    )
}