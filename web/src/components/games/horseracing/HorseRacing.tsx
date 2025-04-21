import { CasinoGame, ChipDisplay, GameIcon, GetChipForValue, GetCurrencyString, playAudio, WagerControls } from "@/components/casino/Casino";
import { Button } from "@/components/ui/button";
import { useConfig } from "@/providers/config";
import { Translate } from "@/providers/locale/Locale";
import { fetchNui } from "@/providers/nui/fetchNui";
import { useNuiEvent } from "@/providers/nui/useNui";
import { useState } from "react";
import ReactSparkle from "react-sparkle";

const DEFAULT_HORSE_WAGERS = {0: 0, 1: 0, 2: 0, 3: 0, 4: 0, 5: 0, 6: 0, 7: 0, 8: 0, 9: 0, 10: 0, 11: 0};

export function HorseNumber({number, height} : {number: number, height?: number}) {
    const heightNum = height ? height : 24;
    const settings = [
        {color: "#F03334", darkText: false},
        {color: "#FFFFFF", darkText: true},
        {color: "#3045E0", darkText: false},
        {color: "#E8EA43", darkText: true},
        {color: "#009925", darkText: false},
        {color: "#1F1F1F", darkText: false},
        {color: "#E8B134", darkText: true},
        {color: "#F500E2", darkText: true},
        {color: "#00DBEC", darkText: false},
        {color: "#D212EB", darkText: false},
        {color: "#625D57", darkText: false},
        {color: "#00F2A4", darkText: true},
    ]
    return (
        <div className="relative font-bold" style={{
            width: heightNum,
            height: heightNum,
            fontSize: heightNum * 0.8,
            color: settings[number].darkText ? "#000000" : "#FFFFFF",
            backgroundColor: settings[number].color,
        }}>
            <div className="absolute top-[65%] left-[50%] translate-x-[-50%] translate-y-[-65%] text-center">
                {number + 1}
            </div>
        </div>
    )
}

type Horse = {
    odds: string;
    progress?: number;
}

type HorseTrack = {
    id: number;
    label: string;
    stage: any;
}

type HorseWager = {
    [key: string]: number;
}

function HorseRacingComponent({horses, horseWagers, isPlaying, onClick, winningHorse} : {horses: Horse[], horseWagers: HorseWager, isPlaying: boolean, winningHorse?: number, onClick: (data: any) => void}) {
    const {config} = useConfig();
    const chips = config.chips || [];
    return (
        <div className="grid grid-cols-6 gap-2" style={{
            pointerEvents: isPlaying ? "none" : "auto",
        }}>
            {horses.map((horse, horseIndex) => (
                <div key={horseIndex} className="flex flex-col gap-2">
                    <div className="relative flex flex-row items-center justify-center gap-2 cursor-pointer scale-100 hover:scale-95 transition-transform" style={{
                        filter: (isPlaying && (winningHorse == undefined || winningHorse != horseIndex)) ? "brightness(0.5)" : "none",
                    }} onClick={() => {
                        onClick({
                            type: "attemptWager",
                            id: horseIndex,
                        });
                    }}>
                        <div className="relative">
                            {(winningHorse != undefined && winningHorse == horseIndex) && (
                                <div className="absolute top-0 left-0 w-full scale-90 h-full" style={{ transformOrigin: "center" }}><ReactSparkle/></div>
                            )}
                            <HorseNumber number={horseIndex} height={50} />
                            {horseWagers[horseIndex as keyof HorseWager] > 0 && (
                                <div className="absolute top-[50%] left-[50%] translate-x-[-50%] translate-y-[-50%]">
                                    <ChipDisplay chip={GetChipForValue(horseWagers[horseIndex as keyof HorseWager], chips, true)} />
                                </div>
                            )}
                        </div>
                        
                        <div className="w-full h-[10px] flex items-center justify-center">
                            <div className="text-xs font-bold text-center text-white">
                                {horse.odds}
                            </div>
                        </div>
                    </div>
                </div>
            ))}
        </div>
    )
}

function CalculateHorseRacingWagers(wagers: HorseWager) {
    let totalWager = 0;
    for (const key in wagers) {
        totalWager += wagers[key as keyof HorseWager] || 0;
    }
    return totalWager;
}

export function HorseRacing({game} : {game: CasinoGame}) {
    const {config} = useConfig();
    const wagerLimit = game.data.wagerLimit;
    const [currentTrack, setCurrentTrack] = useState<number | null>(null);
    const [tracks, setTracks] = useState<HorseTrack[]>(game.data.tracks || []);
    const [horses, setHorses] = useState<Horse[]>([
        {odds: "??", progress: 0.0},
        {odds: "??", progress: 0.0},
        {odds: "??", progress: 0.0},
        {odds: "??", progress: 0},
        {odds: "??", progress: 0},
        {odds: "??", progress: 0},
        {odds: "??", progress: 0},
        {odds: "??", progress: 0},
        {odds: "??", progress: 0},
        {odds: "??", progress: 0},
        {odds: "??", progress: 0},
        {odds: "??", progress: 0},
    ]);
    const [numberHistory, setNumberHistory] = useState<{
        horseId: number;
    }[]>(game.data.history || []);
    const [horseWagers, setHorseWagers] = useState<HorseWager>(game.data.wagers || DEFAULT_HORSE_WAGERS);
    const [stage, setStage] = useState<any>(game.data.stage || {type: "waiting"});
    const [isTrackModalOpen, setIsTrackModalOpen] = useState(currentTrack == null);
    const [chipValue, setChipValue] = useState(0);
    const [money, setMoney] = useState(game.data.money || 0);
    useNuiEvent("setHorseRacingTrack", function(data) {
        setIsTrackModalOpen(false);
        let newTracks = [];
        for (let i = 0; i < tracks.length; i++) {
            newTracks.push(tracks[i]);
        }
        newTracks[data.track.id - 1] = data.track;
        setTracks(newTracks);
        setCurrentTrack(data.track.id - 1);
        setHorseWagers(DEFAULT_HORSE_WAGERS);
        setChipValue(0);
        setStage(data.track.stage);
        setHorses(data.track.horses);
    });
    useNuiEvent("updateHorseRacingTracks", function(data) {
        setTracks(data.tracks);
    });
    useNuiEvent("updateHorseRacingStage", function(data) {
        setStage(data.stage);
    });
    useNuiEvent("updateHorseRacingHorses", function(data) {
        let newHorses = [];
        for (let i = 0; i < horses.length; i++) {
            let progress = data.horses[i].progress || (horses[i].progress || 0);
            let odds = data.horses[i].odds || horses[i].odds;
            newHorses.push({
                odds: odds,
                progress: progress,
            });
        }
        setHorses(newHorses);
    });
    useNuiEvent("updateHorseRacingWager", function(data) {
        setHorseWagers(data.wagers);
    });
    useNuiEvent("updateBalance", function(data) {
        setMoney(data.balance);
    });
    const horseProgress: number[] = [];
    const maxProgress = 1.0415;
    for (let i = 0; i < horses.length; i++) {
        let progress = horses[i].progress || 0;
        if (progress > maxProgress) {
            progress = maxProgress;
        }
        horseProgress.push(progress);
    }
    return (
        <div className='flex flex-col absolute w-full h-full select-none' style={{
            bottom: 0, 
            left: '0', 
            transition: "opacity 0.25s ease-in-out",
            // backgroundImage: `url("/nui/images/horseracing/debug.png")`,
        }}>
            {isTrackModalOpen && (
                <div className="absolute top-[50%] left-[50%] translate-x-[-50%] translate-y-[-50%] w-[700px] h-[400px] bg-background/95 rounded-lg border border-zinc-800 shadow-lg shadow-black/40">
                    <div className="flex flex-col gap-0 p-2 items-center">
                        <div className="text-2xl font-bold text-center text-white pb-3"><Translate id="horseracing_selecttrack" /></div>
                        <div className="overflow-y-auto h-[330px] w-full">
                            <div className="grid grid-cols-2 gap-1 w-full">
                                {tracks.map((track, trackId) => (
                                    <div key={trackId} className="relative p-4 rounded-md cursor-pointer hover:scale-95 transition-all duration-200 ease-in-out" style={{
                                        backgroundImage: `url("/nui/images/horseracing/trackbanner.png")`,
                                        backgroundSize: "cover",
                                        backgroundPosition:  "top",
                                        backgroundRepeat: "no-repeat",
                                    }} onClick={() => {
                                        setIsTrackModalOpen(false);
                                        fetchNui("setHorseRacingTrack", {
                                            trackId: track.id,
                                        });
                                    }}>
                                        <div className="relative z-10">
                                            <div className="text-lg font-bold whitespace-nowrap">{track.label}</div>
                                            <div className="text-sm font-semibold text-zinc-400">
                                                {track.stage.type == "waiting" && (<Translate id="horseracing_ext_waiting" />)}
                                                {track.stage.type != "waiting" && (<Translate id="horseracing_ext_racing" />)}
                                            </div>
                                        </div>
                                        <div className="z-0 absolute overflow-hidden top-0 left-0 h-full w-full">
                                            <div className="absolute rounded-md z-10 w-full h-full" style={{
                                                background: "linear-gradient(to right, rgba(0, 0, 0, 1.0) 40%, rgba(0, 0, 0, 0.0))",
                                            }}></div>
                                        </div>
                                    </div> 
                                ))}
                            </div>
                        </div>
                    </div>  
                </div>
            )}
            {currentTrack != null && (
                <div className="flex justify-between px-8 py-8 mt-auto bg-background/95 items-center justify-between items-center w-full select-none">
                    <div className='flex flex-col gap-2 h-full justify-center w-[33.333333%]'>
                        <div className="flex flex-col gap-2">
                            <div className='flex flex-row items-center justify-between gap-2'>
                                <div className='flex flex-row items-center gap-2'>
                                    <GameIcon name='horseracing' style={{fill: "yellow", width: 30, height: 30}} />
                                    <div className='font-bold text-2xl'><Translate id="horseracing_title" /> - {tracks[currentTrack].label}</div>
                                </div>
                                <div className='font-bold text-xl text-zinc-400'>
                                    {stage.type === "waiting" && <Translate id="horseracing_nextround" args={[stage.time]} />}
                                </div>
                            </div>
                            <div className="font-semibold text-md text-zinc-400"><Translate id="horseracing_desc" /></div>
                            <Button variant="secondary" className="w-full" onClick={() => {
                                setCurrentTrack(null);
                                setIsTrackModalOpen(true);
                                fetchNui("changeHorseRacingTrack", {});
                            }}><Translate id="horseracing_changetrack" /></Button>
                        </div>
                    </div>
                    <div className="flex flex-col gap-2 h-full justify-center items-center w-[33.333333%] px-8">
                        {(wagerLimit && stage.type == "waiting") && <div className="font-semibold text-zinc-400"><Translate id="casino_betrange" args={[GetCurrencyString(wagerLimit[0], config), GetCurrencyString(wagerLimit[1], config)]} /></div>}
                        {(stage.type == "waiting" || stage.type == "winner") && (
                            <HorseRacingComponent winningHorse={stage.winner != undefined ? stage.winner - 1 : undefined} horses={horses} horseWagers={horseWagers} isPlaying={stage.type !== "waiting"} onClick={(data) => {
                                if (data.type == "attemptWager") {
                                    playAudio("bet");
                                    let newWagers = {...horseWagers};
                                    newWagers[data.id as keyof HorseWager] = (newWagers[data.id as keyof HorseWager] || 0) + chipValue;
                                    if (CalculateHorseRacingWagers(newWagers) > money) { return; }
                                    setHorseWagers(newWagers);
                                    fetchNui("setHorseRacingWager", {
                                        wager: newWagers
                                    });
                                }
                            }}/>
                        )}
                        {stage.type == "waiting" && (
                            <>
                                <WagerControls betRange={wagerLimit} chipValue={chipValue} money={money} wager={CalculateHorseRacingWagers(horseWagers)} onClick={(data: any) => {
                                    if (data.type == "setCurrentChip") {
                                        playAudio("bet");
                                        setChipValue(data.value);
                                    }
                                    else if (data.type == "clearWager") {
                                        playAudio("clear");
                                        setHorseWagers(DEFAULT_HORSE_WAGERS as any);
                                        fetchNui("setHorseRacingWager", {
                                            wager: DEFAULT_HORSE_WAGERS
                                        });
                                    }
                                    else if (data.type == "doubleWager") {
                                        let newWagers = Object.keys(horseWagers).reduce((acc, key) => {
                                            acc[key as keyof HorseWager] = (horseWagers[key as keyof HorseWager] || 0) * 2;
                                            return acc;
                                        }, {} as HorseWager);
                                        if (CalculateHorseRacingWagers(newWagers) > money) { return; }
                                        setHorseWagers(newWagers);
                                        playAudio("bet");
                                        fetchNui("setHorseRacingWager", {
                                            wager: newWagers
                                        });
                                    }
                                    else if (data.type == "repeatWager") {
                                        playAudio("bet");
                                        fetchNui("repeatHorseRacingWager", {});
                                    }
                                }} />
                            </>
                        )}
                        {stage.type == "racing" && (
                            <div className="flex flex-row relative gap-0">
                                <div className="flex flex-col">
                                    {horses.map((_, horseIndex) => (
                                        <div className="flex flex-row gap-0" key={horseIndex}>
                                            <div className="z-10 absolute" key={horseIndex} style={{
                                                left: `${95 * (horseProgress[horseIndex])}%`,
                                                transform: `translateX(-${95 * (horseProgress[horseIndex])}%)`,
                                            }}>
                                                <HorseNumber number={horseIndex} height={9} key={horseIndex} />
                                            </div>
                                            <div className="relative w-[300px] h-[8.3px]" key={horseIndex}>
                                                <div className="absolute top-[3px] left-0 w-full h-[2px] bg-white/10" />
                                            </div>
                                            {Array.from({length: 2}).map((_, i) => ((horseIndex % 2 == 0 && i % 2 == 0) || (horseIndex % 2 != 0 && i % 2 != 0) )  ? (
                                                <div className="w-[8.3px] h-[8.3px] bg-white" key={i}></div>
                                            ) : (
                                                <div className="w-[8.3px] h-[8.3px] bg-transparent" key={i}></div>
                                            ))}
                                        </div>
                                    ))}
                                </div>
                            </div>
                        )}
                    </div>
                    <div className="flex flex-col gap-0 h-full justify-center items-end w-[33.333333%]">
                        <div className="flex flex-col gap-0 items-center">
                            <div className="grid grid-cols-12 gap-1 w-full">
                                    {numberHistory.map((number, index) => index < 36 && (
                                        <div className="relative" key={index}>
                                            <HorseNumber key={index} number={number.horseId} height={24} />
                                        </div>
                                    ))}
                            </div>
                        </div>
                    </div>
                </div>
            )}
        </div>
    )
}