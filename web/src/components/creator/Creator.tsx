import { Translate } from "@/providers/locale/Locale"
import { useState } from "react"
import { Button } from "../ui/button"
import { Edit, Plus, Save } from "lucide-react"
import { DisplayCurrency } from "../casino/Casino"

type GameSetting = {
    variable: string,
    type: string,
    default?: any,
    min?: number,
    max?: number,
    label: string,
    options?: {
        value: string,
        label: string,
    }[],
    placeholder?: string,
}

type GameSettingsType = {
    [key: string]: GameSetting[]
}
        

const GameSettings : GameSettingsType = {
    "blackjack": [
        {variable: "maxWager", type: "money", default: 100, min: 100, label: "Max Wager"},
    ],
    "roulette": [
        {variable: "maxWager", type: "money", default: 100, min: 100, label: "Max Wager"},
    ],
    "baccarat": [
        {variable: "maxWager", type: "money", default: 100, min: 100, label: "Max Wager"},
    ],
    "wheel": [
        {variable: "maxWager", type: "money", default: 100, min: 100, label: "Max Wager"},
        {variable: "maxWager", type: "money", default: 100, min: 100, label: "Max Wager"},
    ],
    "horseracing": [
        {variable: "maxWager", type: "money", default: 100, min: 100, label: "Max Wager"},
    ],
    "slots": [
        {variable: "game", type: "dropdown", label: "Max Wager", options: [
            {value: "bananabonanza", label: "Banana Bonanza"},
            {value: "spacewarriors", label: "Space Warriors"},
        ]},
        {variable: "maxWager", type: "money", default: 100, min: 100, label: "Max Wager"},
    ],
    "poker": [
        {variable: "smallBlind", type: "money", default: 10, min: 10, label: "Max Wager"},
        {variable: "bigBlind", type: "money", default: 15, min: 15, label: "Max Wager"},
    ],
}

type vector3 = {
    x: number,
    y: number,
    z: number,
}

type Location = {
    coords: vector3,
    rotation?: vector3,
}

type CasinoEntity = {
    id: string,
    type: string,
    location?: Location,
}

type Casino = {
    id: number,
    label: string,
    entities: CasinoEntity[],
    owner_info?: {
        identifier: string,
        name: string,
    },
    location: Location
}

function Location({ coords, className, onUpdate }: { coords?: vector3, className?: string, onUpdate?: (coords: vector3) => void }) {
    const coordinates = coords || {x: 0, y: 0, z: 0}
    return (
        <div className="flex flex-row items-center gap-2">
            <div className={className}>{`vector3(${coordinates.x}, ${coordinates.y}, ${coordinates.z})`}</div>
            {onUpdate && (
                <Edit size={16} className="cursor-pointer hover:scale-95 transition-all duration-200"/>
            )}
        </div>
    )
}

function GameSettingsDisplay({ game, settingIndex, onUpdate }: { game: string, settingIndex: number, onUpdate: (value: any) => void }) {
    const gameSetting = GameSettings[game as keyof typeof GameSettings][settingIndex];
    const [isEditing, setIsEditing] = useState(false)
    const [value, setValue] = useState<any>(gameSetting?.default || null)
    return gameSetting && (
        <div className="flex flex-row w-full items-center justify-between">
            <div className="text-md font-bold">{gameSetting.label}</div>
            {isEditing ? (
                <div className="flex flex-row items-center gap-2">
                    {gameSetting.type === "money" && (
                        <input type="number" className="bg-secondary/50 text-sm text-right text-zinc-400 rounded-md px-2 py-1" defaultValue={gameSetting.min} min={gameSetting.min} onChange={(e) => {
                            const value = parseFloat(e.target.value)
                            if (!isNaN(value)) {
                                setValue(value)
                            }
                        }
                        } placeholder="Enter value..." />
                    )}
                    <Save size={16} className="cursor-pointer hover:scale-95 transition-all duration-200" onClick={() => {
                        setIsEditing(false)
                        onUpdate(value)
                        setValue(value)
                    }}/>
                </div>
            ) : (
                <div className="flex flex-row items-center gap-2">
                    {gameSetting.type === "money" && (
                        <div className="text-sm text-zinc-400"><DisplayCurrency value={value} /></div>
                    )}
                    <Edit size={16} className="cursor-pointer hover:scale-95 transition-all duration-200" onClick={() => {
                        setIsEditing(true)
                    }}/>
                </div>
            )}
        </div>
    )
}

function CasinoEntityDisplay({ entity, onExit }: { entity?: CasinoEntity, onExit: () => void }) {
    const [entityState, setEntityState] = useState<CasinoEntity | null>(entity || null)
    const [location, setLocation] = useState<vector3>({x: 0, y: 0, z: 0})
    return (
        <>
            {entityState && (
                <div className="flex flex-col gap-2">
                    <div className="px-2 font-semibold text-lg flex flex-row items-center justify-between">
                        <div className="flex flex-row gap-0 items-center justify-between w-full">
                            <div className="text-md font-bold"><Translate id={entityState.type + "_title"}/></div>
                            <p className="text-sm text-zinc-400"><Translate id="casino_id" args={[entityState.id]}/></p>
                        </div>
                    </div>
                    <hr/>
                    <div className="px-2 flex flex-col w-full gap-2 justify-between">
                        <div className="flex flex-row w-full items-center justify-between">
                            <div className="text-md font-bold"><Translate id="casino_location"/></div>
                            <Location className="text-sm text-zinc-400" coords={entityState.location?.coords} onUpdate={(coords: vector3) => {
                                setLocation(coords)
                            }} />
                        </div>
                        {GameSettings[entityState.type].map((setting, index) => (
                            <GameSettingsDisplay game={entityState.type} settingIndex={index} key={index} onUpdate={(value: any) => {
                            }}/>
                        ))}
                        <Button variant="secondary" className="w-full" onClick={onExit}>
                            <Translate id="casino_entity_exit"/>
                        </Button>
                    </div>
                </div>
            )}
        </>
    )
}

function CasinoDisplay({ casino, onExit }: { casino?: Casino, onExit: () => void }) {
    const [casinoState, setCasinoState] = useState<Casino | null>(casino || null)
    const [label, setLabel] = useState<string>("")
    const [location, setLocation] = useState<vector3>({x: 0, y: 0, z: 0})
    const [editingLabel, setEditingLabel] = useState(false);
    const [currentEntityId, setCurrentEntityId] = useState<string | null>(null)
    const [creatingEntity, setCreatingEntity] = useState(false)
    const currentEntity = casinoState?.entities.find(entity => entity.id === currentEntityId) || null
    return (
        <>
            {casinoState ? (
                <>
                    {(currentEntity || creatingEntity) && (
                        <CasinoEntityDisplay entity={currentEntity!} onExit={() => {
                            setCurrentEntityId(null)
                            setCreatingEntity(false)
                        }}/>
                    )}
                    {!currentEntity && (
                        <>
                            <div className="px-2 pb-2 font-semibold text-lg flex flex-row items-center justify-between">
                                {editingLabel ? (
                                    <>
                                        <p><Translate id="casino_name"/>:</p>
                                        <div className="flex flex-row items-center justify-between gap-2">
                                            <input type="text" className="bg-secondary/50 text-sm text-right text-zinc-400 rounded-md px-2 py-1" value={casinoState.label} onChange={(e) => setCasinoState((prev) => {
                                                if (prev) {
                                                    return {
                                                        ...prev,
                                                        label: e.target.value,
                                                    }
                                                }
                                                return null
                                            })} placeholder="Enter casino name..." />
                                            <Save size={16} className="cursor-pointer hover:scale-95 transition-all duration-200" onClick={() => {
                                                setEditingLabel(false)
                                            }}/>
                                        </div>
                                    </>
                                ) : ( 
                                    <>
                                        <div className="flex flex-row items-center">
                                            <p>{casinoState.label}</p> 
                                            <Edit size={16} className="cursor-pointer hover:scale-95 transition-all duration-200 ml-2" onClick={() => {
                                                setEditingLabel(true)
                                            }}/>
                                        </div>
                                        <p className="text-sm text-zinc-400"><Translate id="casino_id" args={[casinoState.id]}/></p>
                                    </>
                                )}
                            </div>
                            <hr/>
                            <div className="flex flex-col pt-2 gap-2 overflow-auto max-h-[950px] px-2">
                                <div className="flex flex-row w-full items-center justify-between">
                                    <div className="text-md font-bold"><Translate id="casino_location"/></div>
                                    <Location className="text-sm text-zinc-400" coords={casinoState.location.coords} onUpdate={(coords: vector3) => {
                                        setCasinoState((prev) => {
                                            if (prev) {
                                                return {
                                                    ...prev,
                                                    location: {
                                                        ...prev.location,
                                                        coords: coords,
                                                    },
                                                }
                                            }
                                            return null
                                        });
                                    }}/>
                                </div>
                                <div className="flex flex-col w-full justify-between">
                                    <div className="text-md font-bold"><Translate id="casino_entities"/></div>
                                    <div className="flex flex-col w-full max-h-[300px] overflow-auto gap-2 justify-between bg-background/50 p-2 mt-2">
                                        {casinoState.entities.map((entity, index) => (
                                            <div key={index} className="flex flex-col justify-between w-full p-2 bg-secondary/50 rounded-md select-none hover:scale-95 transition-all duration-200 cursor-pointer" onClick={() => {
                                                setCurrentEntityId(entity.id)
                                            }}>
                                                <div className="flex flex-row gap-0 items-center justify-between w-full">
                                                    <div className="text-md font-bold"><Translate id={entity.type + "_title"}/></div>
                                                    {entity.location && <Location className="text-sm text-zinc-400" coords={entity.location.coords}/>}
                                                </div>
                                                <div className="text-sm text-zinc-400"><Translate id={"casino_id"} args={[entity.id]}/></div>
                                            </div>
                                        ))}
                                    </div>
                                </div>

                                <Button variant="secondary" className="w-full" onClick={onExit}>
                                    <Translate id="casino_exit"/>
                                </Button>
                            </div>
                        </>
                    )}
                </>
            ) : (
                <>
                    <div className="px-2 pb-2 font-semibold text-2xl flex flex-row items-center justify-between">
                        <p><Translate id="casino_create"/></p>
                    </div>
                    <hr/>
                    <div className="flex flex-col pt-2 gap-2 overflow-auto max-h-[950px] px-2">
                        <div className="flex flex-row w-full items-center justify-between">
                            <div className="text-md font-bold"><Translate id="casino_name"/></div>
                            <input type="text" className="bg-secondary/50 text-sm text-right text-zinc-400 rounded-md px-2 py-1" value={label} onChange={(e) => setLabel(e.target.value)} placeholder="Enter casino name..." />
                        </div>
                        <div className="flex flex-row w-full items-center justify-between">
                            <div className="text-md font-bold"><Translate id="casino_location"/></div>
                            <Location className="text-sm text-zinc-400" coords={location} onUpdate={(coords: vector3) => {
                                setLocation(coords)
                            }} />
                        </div>
                        <Button variant="default" className="w-full" onClick={onExit}>
                            <Save size={16}/>
                            <Translate id="casino_create"/>
                        </Button>
                        <Button variant="secondary" className="w-full" onClick={onExit}>
                            <Translate id="casino_exit"/>
                        </Button>
                    </div>
                </>
            )}
        </>
    )
}

function Creator() {
    const [currentCasinoId, setCurrentCasinoId] = useState<number | null>(1)
    const [casinos, setCasinos] = useState<Casino[]>([
        {
            id: 1,
            label: "Casino 1",
            owner_info: {
                identifier: "owner1",
                name: "Pickle Rick",
            },
            location: {
                coords: {x: 123.45, y: 67.89, z: 10.11},
                rotation: {x: 0, y: 0, z: 0},
            },
            entities: [
                {
                    id: "333333_333331",
                    type: "blackjack",
                    location: {
                        coords: {x: 123.45, y: 67.89, z: 10.11},
                        rotation: {x: 0, y: 0, z: 0},
                    },
                },
                {
                    id: "333333_333332",
                    type: "roulette",
                    location: {
                        coords: {x: 123.45, y: 67.89, z: 10.11},
                        rotation: {x: 0, y: 0, z: 0},
                    },
                },
                {
                    id: "333333_333333",
                    type: "baccarat",
                    location: {
                        coords: {x: 123.45, y: 67.89, z: 10.11},
                        rotation: {x: 0, y: 0, z: 0},
                    },
                },
                {
                    id: "333333_333334",
                    type: "wheel",
                    location: {
                        coords: {x: 123.45, y: 67.89, z: 10.11},
                        rotation: {x: 0, y: 0, z: 0},
                    },
                },
                {
                    id: "333333_333335",
                    type: "slots",
                    location: {
                        coords: {x: 123.45, y: 67.89, z: 10.11},
                        rotation: {x: 0, y: 0, z: 0},
                    },
                },
                {
                    id: "333333_333336",
                    type: "horseracing",
                    location: {
                        coords: {x: 123.45, y: 67.89, z: 10.11},
                        rotation: {x: 0, y: 0, z: 0},
                    },
                },
                {
                    id: "333333_333337",
                    type: "poker",
                    location: {
                        coords: {x: 123.45, y: 67.89, z: 10.11},
                        rotation: {x: 0, y: 0, z: 0},
                    },
                },
            ],
        },
    ])
    const currentCasino: Casino | null = casinos.find(casino => casino.id === currentCasinoId) || null
    const [creatingCasino, setCreatingCasino] = useState(false)
    return (
        <div className="relative ml-auto px-2 py-2 w-[400px] h-full bg-background/95">
            {(currentCasino || creatingCasino) && (
                <CasinoDisplay casino={currentCasino!} onExit={() => {
                    setCurrentCasinoId(null)
                    setCreatingCasino(false)
                }}/>
            )}
            {(!currentCasino && !creatingCasino) && (
                <>
                    <div className="px-2 pb-2 font-semibold text-2xl">Casinos</div>
                    <hr/>
                    <div className="flex flex-col pt-4 gap-2 overflow-auto max-h-[950px] px-2">
                        <Button variant="secondary" className="w-full hover:scale-95 transition-all duration-200" onClick={() => setCreatingCasino(true)}>
                            <Plus size={16} />
                            <Translate id="casino_create"/>
                        </Button>   
                        {casinos.map((casino) => (
                            <div key={casino.id} className="p-4 bg-secondary cursor-pointer hover:scale-95 transition-all duration-200" onClick={() => setCurrentCasinoId(casino.id)}>
                                <div className="flex flex-row items-center justify-between">
                                    <h2 className="text-lg font-bold">{casino.label}</h2>
                                    <Location className="text-sm text-zinc-400" coords={casino.location.coords} />
                                </div>
                                <div className="flex flex-row items-center justify-between">
                                    <p className="text-sm text-zinc-400"><Translate id="casino_id" args={[casino.id]}/></p>
                                    {casino.owner_info && (<p className="text-sm text-zinc-400"><Translate id="casino_owner" args={[casino.owner_info?.name]}/></p>)}
                                </div>
                            </div> 
                        ))}
                    </div>
                </>
            )}
            <div className="position absolute bottom-0 left-[50%] translate-x-[-50%] w-full h-[50px] bg-secondary/50 flex items-center justify-center gap-2">
                <div className="font-semibold">&copy; Pickle Mods</div>
            </div>
        </div>
    )
}

export default function CreatorDisplay() {
    const [visible, setVisible] = useState(true)
    return (
        <>
            {visible && <Creator />}
        </>
    )
}