import { Config, useConfig } from "@/providers/config";
import { useNuiEvent } from "@/providers/nui/useNui";
import { Repeat2Icon, RotateCw, Trash2 } from "lucide-react";
import { useState } from "react";
import { useEffect } from "react";
import Blackjack from "../games/blackjack/Blackjack";
import { Translate } from "@/providers/locale/Locale";
import Slots from "../games/slots/Slots";
import Roulette, { GetDefaultRouletteConnections, GetDefaultRouletteRows, GetDefaultRouletteSections, RouletteComponent } from "../games/roulette/Roulette";
import Results from "../games/results/Results";
import { fetchNui } from "@/providers/nui/fetchNui";
import Baccarat from "../games/baccarat/Baccarat";
import Wheel from "../games/wheel/Wheel";

export type CasinoGame = {
    visible: boolean;
    data: any;
    type: string;
}

export type Card = {
    class: string;
    value: string;
}

export type Chip = {
    color: string;
    value: number;
}

export function DisplayCurrency({value} : {value: number}) {
    const {config} = useConfig();
    return GetCurrencyString(value, config);
}

export function GetCurrencyString(value: number, config: Config) {
    return value.toLocaleString(config.countryCode || "en-US", {style: "currency", currency: config.currency || "USD", minimumFractionDigits: 0, maximumFractionDigits: 0});
}

export function GameIcon({name, style}: {name: string, style?: React.CSSProperties}) {
    if (name === "blackjack" || name === "roulette" || name === "baccarat" || name === "slots" || name === "wheel") {
      return (
        <svg xmlns="http://www.w3.org/2000/svg" width={20} height={20} viewBox="0 0 15 15" version="1.1" style={style}>
          <path xmlns="http://www.w3.org/2000/svg" d="M8.5,10c0.4561,0.6072,1.1821,1,2,1c1.3807,0,2.5-1.1193,2.5-2.5c0-0.5642-0.1938-1.0789-0.509-1.4973L12.5,7l-5-6l-5,6&#10;&#9;l0.009,0.0027C2.1938,7.4211,2,7.9358,2,8.5C2,9.8807,3.1193,11,4.5,11c0.8179,0,1.5439-0.3928,2-1&#10;&#9;C6.5997,9.8672,6.7902,9.6135,7,9.3337V11.5C7,13,4.5,13,4.5,13C4.2239,13,4,13.2238,4,13.5C4,13.7761,4.2239,14,4.5,14H7h1h2.5&#10;&#9;c0.2761,0,0.5-0.2239,0.5-0.5c0-0.2762-0.2239-0.5-0.5-0.5c0,0-2.5,0-2.5-1.5V9.3337C8.2098,9.6135,8.4003,9.8672,8.5,10z"/>
        </svg>
      )
    }
}
 
export function CardsDisplay({cards, direction, height, stacked} : {cards: Card[], direction: "left" | "right", height?: number, stacked?: boolean}) {
    const heightValue = height || 12;
    const widthValue = heightValue * 0.7;
    let spacingValue = widthValue * 1.05;
    if (stacked == undefined || stacked) {
        spacingValue = widthValue * 0.215;
    }
    const cardsList = direction === "left" ? cards : cards.slice().reverse();
    const elementWidth = (cardsList.length - 1) * spacingValue + widthValue;
    const cardClasses = {
        "hrt": "hearts",
        "dia": "diamonds",
        "spd": "spades",
        "club": "clubs",
    }
    const cardValues = {
        "ace": "ace",
        "02": "2",
        "03": "3",
        "04": "4",
        "05": "5",
        "06": "6",
        "07": "7",
        "08": "8",
        "09": "9",
        "10": "10",
        "jack": "jack",
        "queen": "queen",
        "king": "king",
    }
    return (
        <div className="flex flex-col gap-2 relative select-none" id={""+ spacingValue} style={{
            minWidth: elementWidth,
            width: elementWidth,
            alignItems: "flex-end",
        }}>
            {cardsList.map((card, index) => {
                let cardImage = "/nui/images/cards/" + cardValues[card.value as keyof typeof cardValues] + "_of_" + cardClasses[card.class as keyof typeof cardClasses] + ".png";
                if (card.class === "hidden") {
                    cardImage = "/nui/images/cards/hidden.png";
                }
                return (
                    <div className="border bg-white" key={index} style={index > 0 ? {
                        borderRadius: heightValue * 0.05,
                        position: "absolute",
                        right: spacingValue * index,
                        zIndex: (direction === "left" ? index : cards.length - index),
                        minWidth: widthValue,
                        width: widthValue,
                        height: heightValue,
                    } : {
                        borderRadius: heightValue * 0.05,
                        zIndex: (direction === "left" ? 1 : cards.length ),
                        minWidth: widthValue,
                        width: widthValue,
                        height: heightValue,
                    }}>
                        <img draggable={false} src={cardImage}  style={{
                            width: "100%",
                            height: "100%",
                            borderRadius: 5,
                        }} />
                    </div>
                )
            })}
        </div>
    )
}

export function ChipDisplay({chip, size} : {chip: Chip, size?: number}) {
    let chipLabel = chip.value.toString();
    let factor = Math.pow(10, 1);
    const brackets = ["K", "M", "B", "T"];
    for (let i=0; i < brackets.length; i++) {
        let numberStr = i > 0 ? "999".repeat(i + 1) : "999";
        let threshold = parseInt(numberStr);
        if (chip.value < threshold && i == 0) {
            break;
        }
        else if (chip.value < threshold) {
            chipLabel = (Math.floor((chip.value / ((threshold + 1) / 1000) ) * factor) / factor).toString().replace(/\.0$/, "") + brackets[i - 1];
            break;
        }
        else if (i == brackets.length - 1) {
            chipLabel = (Math.floor((chip.value / ((threshold + 1) / 1000) ) * factor) / factor).toString().replace(/\.0$/, "") + "?";
        }
    }
    return (
        <div className="relative select-none" style={{
            width: size || 40,
            height: size || 40,
        }}>
            <div className="absolute top-[50%] left-[50%] w-full h-full rounded-full z-1" style={{transform: "translate(-50%, -50%)"}}>
                <div className="flex flex-row gap-1 h-full items-center justify-center">
                    <div className="font-bold" style={{fontSize: (size || 40) / (0.9 * (chipLabel.length + 2)) }}>{chipLabel}</div>
                </div>
            </div>
            <svg xmlns="http://www.w3.org/2000/svg" width={size || 40} height={size || 40} version="1.0" viewBox="500 500 3000 3000"><div id="in-page-channel-node-id" data-channel-name="in_page_channel_eQbTt6"/>
                <g id="Ebene_x0020_1">
                <metadata id="CorelCorpID_0Corel-Layer"/>
                <circle fill={chip.color} transform="matrix(0.709526 0.40964 -0.409645 0.709518 2000.02 1999.95)" r="1831"/>
                <path fill="#FEFEFE" d="M1729 3475c181,33 365,32 542,-1l0 -328 -542 0 0 329zm833 -751l42 72c-67,51 -140,93 -217,125l-42 -73c77,-31 150,-73 217,-124zm-437 183l0 84c-82,11 -166,11 -250,1l0 -84c84,11 168,11 250,-1zm-729 -110l42 -73c32,25 67,49 104,70 36,21 74,39 112,55l-42 73c-38,-16 -75,-35 -112,-56 -37,-21 -71,-44 -104,-69zm-808 -295l284 -164 271 469 -285 165c-119,-140 -209,-300 -270,-470zm2261 -156l73 42c-16,38 -35,75 -56,112 -21,37 -44,71 -69,104l-73 -42c25,-32 49,-67 70,-104 21,-36 39,-74 55,-112zm-1646 -950l73 42c-25,32 -49,67 -70,104 -21,36 -39,74 -55,112l-73 -42c16,-38 35,-75 56,-112 21,-37 44,-71 69,-104zm410 -317l42 73c-77,31 -150,73 -217,124l-42 -72c67,-51 140,-93 217,-125zm512 -71l0 84c-84,-11 -168,-11 -250,1l0 -84c83,-11 166,-11 250,-1zm221 143l42 -73c38,16 75,35 112,56 37,21 71,44 104,69l-42 73c-32,-25 -67,-49 -104,-70 -36,-21 -74,-39 -112,-55zm561 724l84 0c11,83 11,166 1,250l-84 0c11,-83 11,-168 -1,-250zm-1899 0l84 0c-11,84 -11,168 1,250l-84 0c-11,-82 -11,-166 -1,-250zm1716 -437l72 -42c51,67 93,140 125,217l-73 42c-31,-77 -73,-150 -124,-217zm-1645 949l73 -42c31,77 73,150 124,217l-72 42c-51,-67 -93,-140 -125,-217zm2333 -889c-61,-170 -151,-330 -270,-470l-285 165 271 469 284 -164zm-1141 -973l0 329 -542 0 0 -328c178,-33 361,-34 542,-1zm-1413 503l285 165 -271 469 -285 -165c30,-84 68,-167 114,-247 46,-80 99,-154 157,-222zm2284 1944c58,-68 111,-142 157,-222 46,-80 84,-163 114,-247l-285 -165 -271 469 285 165z"/>
                </g>
            </svg>
        </div>
    )
}

export function AnimatedValue({ value, time }: { value: number, time?: number }) {
    const [displayValue, setDisplayValue] = useState(value);

    useEffect(() => {
        const increment = (value - displayValue) / 5;
        if (increment !== 0) {
            const interval = setInterval(() => {
                setDisplayValue((prev) => {
                    const newValue = prev + increment;
                    if ((increment > 0 && newValue >= value) || (increment < 0 && newValue <= value)) {
                        clearInterval(interval);
                        return value;
                    }
                    return newValue;
                });
            }, time || 5);
            return () => clearInterval(interval);
        }
    }, [value, displayValue]);

    return <DisplayCurrency value={Math.round(displayValue)} />;
}

export function DefaultWagerComponent({wager, setWager, betRange, money, chips, attemptWagerUpdate, closestChip, config} : {wager: number, setWager: (value: number) => void, betRange?: [number, number], money: number, chips: Chip[], attemptWagerUpdate: (wager: number, strictMode?: boolean) => boolean, closestChip: Chip, config: Config}) {
    return (
        <div className="flex flex-col gap-2 items-center justify-center">
            {betRange && <div className="font-semibold text-zinc-400"><Translate id="casino_betrange" args={[GetCurrencyString(betRange[0], config), GetCurrencyString(betRange[1], config)]} /></div>}
            <div className="flex relative flex-row gap-1 items-center">
                <div className="rounded-full border  p-2" style={{width: 60, height: 60}}>
                    <div className="absolute top-[50%] left-[50%] rounded-full z-1" style={{transform: "translate(-50%, -50%)"}}>
                        {wager > 0 ? <ChipDisplay chip={{
                            color: closestChip.color,
                            value: wager
                        }} size={48} /> : (
                            <div className="font-bold text-xs text-zinc-500">PLAY</div>
                        ) }
                    </div>
                </div>
            </div>
            <div className="flex flex-col gap-0 items-center">
                <div className="font-bold text-lg" style={{
                    color: (betRange ? (wager >= betRange[0] ? "white" : "var(--color-red-400)") : undefined)
                }}>
                    <AnimatedValue value={wager} />
                </div>
                <div className="font-semibold text-zinc-400"><Translate id="casino_money" args={[GetCurrencyString(money, config)]} /></div>
            </div>
            <div className="flex flex-row gap-2 items-center">
                <div className="relative rounded-full bg-yellow-600 border-zinc-400 p-2 cursor-pointer hover:scale-90 transition-transform" style={{width: 48, height: 48}} onClick={() => { attemptWagerUpdate(wager * 2); }}>
                    <div className="absolute top-[50%] left-[50%] rounded-full z-1" style={{transform: "translate(-50%, -50%)"}}>
                        <div className="font-bold text-xl">x2</div>
                    </div>
                </div>
                {chips.map((chip, index) => (
                    <div className="cursor-pointer hover:scale-90 transition-transform" onClick={() => { attemptWagerUpdate(wager + chip.value); }} key={index}>
                        <ChipDisplay chip={chip} size={48} />
                    </div>
                ))}
                <div className="relative rounded-full bg-blue-600 border-zinc-400 p-2 cursor-pointer hover:scale-90 transition-transform" style={{width: 48, height: 48}} onClick={() => { 
                    attemptWagerUpdate(0); 
                    fetchNui("repeatWager", {});
                    playAudio("bet");
                }}>
                    <div className="absolute top-[50%] left-[50%] rounded-full z-1" style={{transform: "translate(-50%, -50%)"}}>
                        <RotateCw size={24}/>
                    </div>
                </div>
                <div className="relative rounded-full bg-secondary/80 border-zinc-400 p-2 cursor-pointer hover:scale-90 transition-transform" style={{width: 48, height: 48}} onClick={() => { attemptWagerUpdate(0); }}>
                    <div className="absolute top-[50%] left-[50%] rounded-full z-1" style={{transform: "translate(-50%, -50%)"}}>
                        <Trash2 size={24}/>
                    </div>
                </div>
            </div>
        </div>
    )
}

export function WagerControls({money, wager, chipValue, onClick, betRange } : {money: number, wager: number, chipValue: number, onClick: (data: any) => void, betRange?: [number, number]}) {
    const {config} = useConfig();
    const chips = config.chips || [];
    const currentChip = chipValue > 0 ? GetChipForValue(chipValue, chips) : null;
    return (
        <div className="flex flex-col gap-2 items-center justify-center">
            <div className="flex flex-col gap-0 items-center">
                <div className="font-bold text-lg" style={{
                    color: (betRange ? (wager >= betRange[0] ? "white" : "var(--color-red-400)") : undefined)
                }}>
                    <AnimatedValue value={wager} />
                </div>
                <div className="font-semibold text-zinc-400"><Translate id="casino_money" args={[GetCurrencyString(money, config)]} /></div>
            </div>
            <div className="flex flex-row gap-2 items-center">
                <div className="relative rounded-full bg-yellow-600 border-zinc-400 p-2 cursor-pointer hover:scale-90 transition-transform" style={{width: 48, height: 48}} onClick={() => {
                    onClick({type: "doubleWager"})
                }}>
                    <div className="absolute top-[50%] left-[50%] rounded-full z-1" style={{transform: "translate(-50%, -50%)"}}>
                        <div className="font-bold text-xl">x2</div>
                    </div>
                </div>
                {chips.map((chip, index) => (
                    <div className="cursor-pointer hover:scale-90 transition-transform" style={{
                        filter: (currentChip != null && currentChip.value == chip.value) ? "brightness(1.0)" : "brightness(0.8)",
                    }} onClick={() => { onClick({type: "setCurrentChip", value: chip.value}); }} key={index}>
                        <ChipDisplay chip={chip} size={48} />
                    </div>
                ))}
                <div className="relative rounded-full bg-blue-600 border-zinc-400 p-2 cursor-pointer hover:scale-90 transition-transform" style={{width: 48, height: 48}} onClick={() => { 
                    onClick({type: "repeatWager"})
                }}>
                    <div className="absolute top-[50%] left-[50%] rounded-full z-1" style={{transform: "translate(-50%, -50%)"}}>
                        <RotateCw size={24}/>
                    </div>
                </div>
                <div className="relative rounded-full bg-secondary/80 border-zinc-400 p-2 cursor-pointer hover:scale-90 transition-transform" style={{width: 48, height: 48}} onClick={() => { onClick({type: "clearWager"}); }}>
                    <div className="absolute top-[50%] left-[50%] rounded-full z-1" style={{transform: "translate(-50%, -50%)"}}>
                        <Trash2 size={24}/>
                    </div>
                </div>
            </div>
        </div>
    )
}

export const playAudio = (name: string) => {
    const audio = new Audio('/nui/audio/chips_'+name+'.mp3');
    audio.play();
};

export function GetChipForValue(value: number, chips: Chip[], preserveNumber: boolean = false) {
    let closestChip = chips[0];
    for (let i = 0; i < chips.length; i++) {
        if (value >= chips[i].value) {
            closestChip = chips[i];
        }
    }
    if (preserveNumber) {
        return {
            ...closestChip,
            value: value,
        }
    }
    return closestChip;
}

export function RouletteWagerComponent({connects, wager, setWager, betRange, money, chips, attemptWagerUpdate, closestChip, config} : {connects: any, wager: number, setWager: (value: number, data?: any) => void, betRange?: [number, number], money: number, chips: Chip[], attemptWagerUpdate: (wager: number, strictMode?: boolean) => boolean, closestChip: Chip, config: Config}) {
    const [selectedChip, setSelectedChip] = useState<Chip | null>(null);
    const [rows, setRows] = useState(GetDefaultRouletteRows());
    const [sections, setSections] = useState(GetDefaultRouletteSections()); 
    return (
        <div className="flex flex-col gap-1 items-center justify-center">
            <RouletteComponent roulette={{
                winningNumber: "-1", 
                isPlaying: false, 
                rows, 
                sections, 
                connects,
                onClick: (type: "row" | "section" | "connect", index: number, row?: number) => {
                    if (type === "connect") {
                        if (selectedChip && attemptWagerUpdate(wager + selectedChip.value, true)) {
                            let newConnects = connects;
                            newConnects[index].wager += selectedChip.value;
                            setWager(wager + selectedChip.value, {
                                connects: newConnects,
                            });
                        }
                    }
                }
            }}/>
            {betRange && <div className="font-semibold text-zinc-400"><Translate id="casino_betrange" args={[GetCurrencyString(betRange[0], config), GetCurrencyString(betRange[1], config)]} /></div>}
            <div className="flex flex-col gap-0 items-center">
                <div className="font-bold text-lg" style={{
                    color: (betRange ? (wager >= betRange[0] ? "white" : "var(--color-red-400)") : undefined)
                }}>
                    <AnimatedValue value={wager} />
                </div>
                <div className="font-semibold text-zinc-400"><Translate id="casino_money" args={[GetCurrencyString(money, config)]} /></div>
            </div>
            <div className="flex flex-row gap-1 items-center">
                <div className="relative rounded-full bg-yellow-600 border-zinc-400 p-2 cursor-pointer hover:scale-90 transition-transform" style={{width: 30, height: 30}} onClick={() => { 
                    if (attemptWagerUpdate(wager * 2, true)) {
                        const newConnects = connects.map((connect: any) => {
                            return {
                                ...connect,
                                wager: connect.wager * 2,
                            }
                        });
                        setWager(wager * 2, {
                            connects: newConnects,
                        });
                    }
                }}>
                    <div className="absolute top-[50%] left-[50%] rounded-full z-1" style={{transform: "translate(-50%, -50%)"}}>
                        <div className="font-bold text-sm">x2</div>
                    </div>
                </div>
                {chips.map((chip, index) => (
                    <div className="cursor-pointer hover:scale-90 transition-transform" style={{
                        filter: selectedChip == chip ? "brightness(1.2)" : "brightness(0.8)",
                    }} onClick={() => { 
                        playAudio("bet");
                        setSelectedChip(chip);
                     }} key={index}>
                        <ChipDisplay chip={chip} size={30} />
                    </div>
                ))}
                <div className="relative rounded-full bg-blue-600 border-zinc-400 p-2 cursor-pointer hover:scale-90 transition-transform" style={{width: 30, height: 30}} onClick={() => { 
                    attemptWagerUpdate(0); 
                    fetchNui("repeatWager", {});
                    playAudio("bet");
                }}>
                    <div className="absolute top-[50%] left-[50%] rounded-full z-1" style={{transform: "translate(-50%, -50%)"}}>
                        <RotateCw size={16}/>
                    </div>
                </div>
                <div className="relative rounded-full bg-secondary/80 border-zinc-400 p-2 cursor-pointer hover:scale-90 transition-transform" style={{width: 30, height: 30}} onClick={() => { 
                    attemptWagerUpdate(0); 
                    setWager(0, {
                        connects: GetDefaultRouletteConnections(),
                    });
                }}>
                    <div className="absolute top-[50%] left-[50%] rounded-full z-1" style={{transform: "translate(-50%, -50%)"}}>
                        <Trash2 size={16}/>
                    </div>
                </div>
            </div>
        </div>
    )
}

export function WagerComponent({wager, setWager, betRange, money, wagerData} : {wagerData?: any, wager: number, setWager: (value: number, data?: any) => void, betRange?: [number, number], money: number}) {
    const wagerTypeString = (wagerData && wagerData.type) ? wagerData.type : "default";
    const {config} = useConfig();
    const [value, setValue] = useState(wager);
    const chips = config.chips || [];
    let closestChip = chips[0];
    for (let i = 0; i < chips.length; i++) {
        if (value >= chips[i].value) {
            closestChip = chips[i];
        }
    }
    const setWagerValue = (wager: number) => {
        let num = wager;
        if (money < wager) {
            num = money;
        }
        setValue(num);
        if (wagerTypeString !== "roulette") {
            setWager(num);
        }
        return num;
    }
    const attemptWagerUpdate = (wager: number, strictMode?: boolean) => {
        if (wager == value) return false;
        if (strictMode && wager > money) {
            return false;
        }
        if (betRange) {
            if (wager < 0) {
                playAudio("clear");
                setWagerValue(0);
                return true
            }
            if (wager > betRange[1]) {
                playAudio("bet");
                setWagerValue(betRange[1]);
                return true
            }
        }
        if (value != 0 && wager <= 0) {
            playAudio("clear");
        }
        else {
            playAudio("bet");
        }
        setWagerValue(wager);
        return true; 
    }
    if (wagerData && wagerData.type == "roulette") {
        useNuiEvent("updateRouletteWagers", (data) => {
            setValue(data.data.wager);
        }); 
    }
    return (
        <>
            {wagerTypeString === "default" && ( <DefaultWagerComponent wager={value} setWager={setWager} betRange={betRange} money={money} chips={chips} attemptWagerUpdate={attemptWagerUpdate} closestChip={closestChip} config={config} /> )}
            {wagerTypeString === "roulette" && ( <RouletteWagerComponent connects={wagerData.connects} wager={value} setWager={setWager} betRange={betRange} money={money} chips={chips} attemptWagerUpdate={attemptWagerUpdate} closestChip={closestChip} config={config} /> )}
        </>
    );
}

export function CasinoControls() {
    return (
        <div className="bg-background/95 p-2 absolute top-[20px] left-[20px] flex items-center gap-2 rounded-md">
            <div className="flex items-center justify-center gap-2">
                <div className="font-bold text-sm p-[4px] text-black rounded-md bg-white">
                    ESC
                </div>
                <div className="font-bold text-xl text-primary">Leave Game</div>
            </div>
        </div>
    )
}

export function CasinoGameDisplay() {
    // const [currentGame, setCurrentGame] = useState<CasinoGame | null>(
    //     {
    //         type: "baccarat",
    //         visible: true,
    //         data: {
    //             seatId: 1,
    //             seats: [
    //                 {wager: 0, name: "Pickle"},
    //                 {wager: 0, name: "Pickle 2"},
    //                 {wager: 0, name: "Pickle 3"},
    //                 {wager: 0, name: "Pickle 4"},
    //             ],
    //             stage: {
    //                 type: "results",
    //                 winningWagers: {
    //                     player: false,
    //                     banker: false,
    //                     tie: false,
    //                     suitedPair: false,
    //                     playerPair: false,
    //                     bankerPair: false,
    //                     eitherPair: false
    //                 }
    //             },
    //         }
    //     }
    // );
    // const [currentGame, setCurrentGame] = useState<CasinoGame | null>(
    //     {
    //         type: "blackjack",
    //         visible: true,
    //         data: {
    //             seatId: 1,
    //             seats: [
    //                 {wager: 0, name: "Pickle", currentHand: 1, hands: [[], []]},
    //                 {wager: 0, name: "Pickle", currentHand: 1, hands: [[], []]},
    //                 {wager: 0, name: "Pickle a", currentHand: 1,  hands: [[], []]},
    //                 {wager: 0, name: "Pickle vb", currentHand: 1,  hands: [[], []]},
    //                 {wager: 0, name: "Pickle c", currentHand: 1,  hands: [[], []]},
    //             ],
    //             stage: {
    //                 type: "waiting",
    //             },
    //         }
    //     }
    // );
    // const [currentGame, setCurrentGame] = useState<CasinoGame | null>({
    //     type: "slots",
    //     visible: false,
    //     data: {
    //         foldername: "spacewarriors",
    //         headerTextImage: "header_title.png",
    //         backgroundImage: "background.png",
    //         reelCount: 5,
    //         reelSymbols: 3,
    //         paylineWinThreshold: 3,
    //         bonusTriggerCount: 3,
    //         bonusFreeSpins: 10,
    //         bonusSymbol: "Bonus Symbol",
    //         slotSymbols: {
    //             "Bonus Symbol": {
    //                 image: "bonus.png",
    //                 reels: [5, 5, 1, 1, 1],
    //                 pay: [0, 0, 0, 0, 0],
    //             },
    //             "Monkey": {
    //                 image: "monkey.png",
    //                 reels: [2, 2, 2, 2, 2],
    //                 pay: [0, 0, 3, 7, 30],
    //             },
    //             "Coconut": {
    //                 image: "coconut.png",
    //                 reels: [3, 3, 3, 3, 3],
    //                 pay: [0, 0, 1.5, 3.5, 10],
    //             },
    //             "Coconut Tree Bundle": {
    //                 image: "tree_2.png",
    //                 reels: [4, 4, 4, 4, 4],
    //                 pay: [0, 0, 1.2, 2, 6],
    //             },
    //             "Coconut Tree": {
    //                 image: "tree_1.png",
    //                 reels: [5, 5, 5, 5, 5],
    //                 pay: [0, 0, 0.8, 1.5, 4],
    //             },
    //             "Banana Bunch": {
    //                 image: "banana_2.png",
    //                 reels: [6, 6, 6, 6, 6],
    //                 pay: [0, 0, 0.35, 0.6, 1.75],
    //             },
    //             "Banana": {
    //                 image: "banana_1.png",
    //                 reels: [7, 7, 7, 7, 7],
    //                 pay: [0, 0, 0.2, 0.35, 1.25],
    //             },
    //         },
    //         paylines: [
    //             [1, 1, 1, 1, 1],
    //             [0, 0, 0, 0, 0],
    //             [2, 2, 2, 2, 2],
    //             [0, 1, 2, 1, 0],
    //             [2, 1, 0, 1, 2],
    //             [1, 0, 0, 0, 1],
    //             [1, 2, 2, 2, 1],
    //             [0, 0, 1, 2, 2],
    //             [2, 2, 1, 0, 0],
    //             [1, 2, 1, 0, 1],
    //             [1, 0, 1, 2, 1],
    //             [0, 1, 1, 1, 0],
    //             [2, 1, 1, 1, 2],
    //             [0, 1, 0, 1, 0],
    //             [2, 1, 2, 1, 2],
    //             [1, 1, 0, 1, 1],
    //             [1, 1, 2, 1, 1],
    //             [0, 0, 2, 0, 0],
    //             [2, 2, 0, 2, 2],
    //             [0, 2, 2, 2, 0],
    //         ],
    //     },
    // });
    const [currentGame, setCurrentGame] = useState<CasinoGame | null>({
        type: "wheel",
        visible: false,
        data: {
            money: 1000,
            stage: {
                type: "winner",
                section: "bonus"
            },
        }
    });
    // const [currentGame, setCurrentGame] = useState<CasinoGame | null>(null);
    const [isGameVisible, setGameVisible] = useState<boolean>(true);
    useEffect(() => {
        const handleKeyDown = (event: KeyboardEvent) => {
            if (event.key === "Escape" || event.key === "Backspace") {
                fetchNui("exitGame", {});
            }
        };

        window.addEventListener("keydown", handleKeyDown);

        return () => {
            window.removeEventListener("keydown", handleKeyDown);
        };
    });

    useNuiEvent("setCurrentGame", (data: any) => {
        if (data.game) {
            setCurrentGame({
                data: data.game.data,
                visible: data.game.visible,
                type: data.game.type,
            });
            setTimeout(() => {
                setGameVisible(true);
            }, 10);
        }
        else {
            setGameVisible(false);
            setTimeout(() => {
                setCurrentGame(null);
            }, 310);
        }

    });

    return currentGame != null && (
        <div className="w-screen h-screen absolute text-primary top-0 left-0 transition-opacity duration-300" style={{
            opacity: isGameVisible ? 1 : 0,
            backgroundColor: "var(--background-color)",
        }}>
            <CasinoControls/>
            <Results/>
            {(currentGame.type == "baccarat") && <Baccarat game={currentGame}/>}
            {(currentGame.type == "blackjack") && <Blackjack game={currentGame}/>}
            {(currentGame.type == "slots") && <Slots game={currentGame}/>}
            {(currentGame.type == "roulette") && <Roulette game={currentGame}/>}
            {(currentGame.type == "wheel") && <Wheel game={currentGame}/>}
            <div className="transform transform-z-0 rounded-md" id='dialog-container' style={{position: "absolute", top: 0, left: 0, width: "100%", height: "100%", overflow: "hidden", pointerEvents: "none", zIndex: 100}}></div>
        </div>
    )
}