import { CardsDisplay, CasinoGame } from "@/components/casino/Casino"

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

export default function Poker({game} : {game: CasinoGame}) {
    return (
        <div className='flex flex-col absolute w-full h-full px-8 py-8' style={{
            bottom: 0, 
            left: '0', 
            transition: "opacity 0.25s ease-in-out",
            backgroundImage: (`url("/nui/images/poker/debug.png")`),
        }}>
            {SEAT_OFFSETS.map((offset, index) => (
                <div className="absolute" style={{
                    left: `${offset.x}px`,
                    top: `${offset.y}px`,
                    transition: "opacity 0.25s ease-in-out",
                }} key={index}>
                    <div className="flex flex-row gap-2 items-center">
                        <div className="flex flex-col p-2 bg-background/95 rounded-md">
                            <div className="flex flex-row items-center">
                                <div className="text-primary text-2xl font-bold">Pickle</div>
                                <div className="flex flex-row items-center pl-2 justify-end w-full">
                                    <CardsDisplay direction="right" height={50} cards={[
                                        { class: "hrt", value: "ace" },
                                    ]} />
                                    <CardsDisplay direction="right" height={50} cards={[
                                        { class: "hrt", value: "ace" },
                                    ]} />
                                    <div className="pl-2 text-zinc-400 text-lg font-bold">82%</div>
                                </div>
                            </div>
                            <div className="flex flex-row items-center gap-4 justify-end">
                                <div className="text-zinc-400 text-lg font-semibold">$100,000</div>
                                <div className="text-zinc-400 text-lg font-semibold">ALL-IN $100,000</div>
                            </div>
                        </div>
                        <div className="w-6 h-6 relative rounded-full text-red-600 font-bold bg-white/95 border-2 border-zinc-800 flex items-center justify-center">
                            <span className="absolute left-[4.5px]">D</span>
                        </div>
                    </div>
                </div>
            ))}
        </div>
    )
}