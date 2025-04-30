import { Translate } from "@/providers/locale/Locale"
import { useEffect, useState } from "react"
import { Button } from "../ui/button"
import { Edit, Plus, Save } from "lucide-react"
import { CasinoControls, DisplayCurrency } from "../casino/Casino"
import { useNuiEvent } from "@/providers/nui/useNui"
import { fetchNui } from "@/providers/nui/fetchNui"
import { useConfig } from "@/providers/config"

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

export type GameSettingsType = {
    [key: string]: GameSetting[]
}
        
const DEFAULT_LOCATION: Location = {
    coords: {x: 0, y: 0, z: 0},
    rotation: {x: 0, y: 0, z: 0},
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

type Player = {
    identifier: string,
    name: string,
}

type CasinoEntity = {
    id: string,
    type: string,
    location?: Location,
    settings: {
        [key: string]: any,
    },
}

type Casino = {
    id: number,
    settings: CasinoSettings,
    transactions: any[],
    entities: CasinoEntity[],
    owner_info?: Player | null,
}

function Location({ info, defaultLocation, className, onUpdate }: { info?: any, defaultLocation: Location, className?: string, onUpdate?: (location: Location) => void }) {
    const coordinates = defaultLocation.coords || {x: 0, y: 0, z: 0}
    const rotation = defaultLocation.rotation || {x: 0, y: 0, z: 0}
    useNuiEvent("setLocation", (data: any) => {
        if (onUpdate) {
            onUpdate(data.location)
        }
    })
    return (
        <div className="flex flex-row items-center gap-2">
            <div className={className}>{`vector3(${coordinates.x.toFixed(2)}, ${coordinates.y.toFixed(2)}, ${coordinates.z.toFixed(2)})`}</div>
            {onUpdate && (
                <Edit size={16} className="cursor-pointer hover:scale-95 transition-all duration-200" onClick={() => {
                    fetchNui("editLocation", {
                        info: info,
                        coords: coordinates, 
                        rotation: rotation,
                    })
                    // Do cool stuff here
                }}/>
            )}
        </div>
    )
}

function Player({ info, defaultPlayer, className, onUpdate }: { info?: any, defaultPlayer?: Player, className?: string, onUpdate?: (player: Player) => void }) {
    useNuiEvent("setPlayer", (data: any) => {
        if (onUpdate) {
            onUpdate(data.player)
        }
    })
    return (
        <div className="flex flex-row items-center gap-2">
            <div className={className}>{defaultPlayer?.name || <Translate id="none"/>}</div>
            {onUpdate && (
                <Edit size={16} className="cursor-pointer hover:scale-95 transition-all duration-200" onClick={() => {
                    fetchNui("editPlayer", {
                        info: info,
                        player: defaultPlayer, 
                    })
                    // Do cool stuff here
                }}/>
            )}
        </div>
    )
}

function GameSettingsDisplay({ game, variable, defaultValue, onUpdate }: { game: string, variable: string, defaultValue: any, onUpdate: (value: any) => void }) {
    const {config} = useConfig()
    const GameSettings: GameSettingsType = config.gameSettings || {}
    const gameSetting = GameSettings[game as keyof typeof GameSettings].find(setting => setting.variable === variable)
    const [isEditing, setIsEditing] = useState(false)
    const [value, setValue] = useState<any>(defaultValue || null)
    const dropdownLabel = gameSetting?.options?.find(option => option.value === value)?.label || gameSetting?.default || null
    useEffect(() => {
        if (gameSetting) {
            setValue(defaultValue || (gameSetting.default || null))
        }
    }, [gameSetting])
    return gameSetting && (
        <div className="flex flex-row w-full items-center justify-between">
            <div className="text-md font-bold">{gameSetting.label}</div>
            {isEditing ? (
                <div className="flex flex-row items-center gap-2">
                    {gameSetting.type === "money" && (
                        <input type="number" className="bg-secondary/50 text-sm text-right text-zinc-400 rounded-md px-2 py-1" defaultValue={value || gameSetting.min} min={gameSetting.min} onChange={(e) => {
                            const value = parseFloat(e.target.value)
                            if (!isNaN(value)) {
                                setValue(value)
                            }
                        }
                        } placeholder="Enter value..." />
                    )}
                    {gameSetting.type === "dropdown" && (
                        <select className="bg-secondary/50 text-sm text-right rounded-md px-2 py-1" value={value} onChange={(e) => {
                            setValue(parseInt(e.target.value) || e.target.value)
                        }}>
                            {gameSetting.options && gameSetting.options.map((option, index) => (
                                <option key={index} value={option.value}>{option.label}</option>
                            ))}
                        </select>
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
                    {gameSetting.type === "dropdown" && (
                        <div className="text-sm text-zinc-400">{dropdownLabel}</div>
                    )}
                    <Edit size={16} className="cursor-pointer hover:scale-95 transition-all duration-200" onClick={() => {
                        setIsEditing(true)
                    }}/>
                </div>
            )}
        </div>
    )
}

type CasinoEntitySettings = {
    [key: string]: any,
}

function CasinoEntityDisplay({casinoId, entity, onExit }: {casinoId: number, entity?: CasinoEntity, onExit: () => void }) {
    const {config} = useConfig()
    const GameSettings: GameSettingsType = config.gameSettings || {}
    const entityState = (entity || null)
    const [entityType, setEntityType] = useState<string>(entityState?.type || "slot")
    const getDefaultSettings = () => {
        let initialSettings: CasinoEntitySettings = {}
        for (let i=0; i<GameSettings[entityType].length; i++) {
            let setting = GameSettings[entityType][i]
            initialSettings[setting.variable] = setting.default
        }
        initialSettings.location = DEFAULT_LOCATION
        if (entityState) {
            Object.keys(entityState.settings).map((key) => {
                const value = entityState.settings[key];
                initialSettings[key] = value;
            });
        }
        return initialSettings;
    }
    const [entitySettings, setEntitySettings] = useState<CasinoEntitySettings>(getDefaultSettings)
    useEffect(() => {
        setEntitySettings(getDefaultSettings)
    }, [entityType])
    const startExit = () => {
        fetchNui("exitCasinoEntityEditor", {})
        onExit()
    }
    useNuiEvent("updateCasinoEntitySetting", (data: any) => {
        if (!entityState || data.casinoId !== casinoId || data.entityId !== entityState.id) return;
        setEntitySettings((prev) => {
            return {
                ...prev,
                [data.variable]: data.value,
            }
        });
    });
    return (
        <>
            {entityState && (
                <div className="flex flex-col gap-2 h-[92%]">
                    <div className="px-2 font-semibold text-lg flex flex-row items-center justify-between">
                        <div className="flex flex-row gap-0 items-center justify-between w-full">
                            <div className="text-md font-bold"><Translate id={entityState.type + "_title"}/></div>
                            <p className="text-sm text-zinc-400"><Translate id="casino_id" args={[entityState.id]}/></p>
                        </div>
                    </div>
                    <hr/>
                    <div className="px-2 flex flex-col w-full gap-2 justify-between h-full">
                        <div className="flex flex-row w-full items-center justify-between">
                            <div className="text-md font-bold"><Translate id="casino_location"/></div>
                            <Location info={{casinoId: casinoId, entityId: entityState.id, settings: entitySettings}} className="text-sm text-zinc-400" defaultLocation={entitySettings.location || DEFAULT_LOCATION} onUpdate={(location: Location) => {
                                setEntitySettings((prev) => {
                                    return {
                                        ...prev,
                                        location: location,
                                    }
                                });
                                fetchNui("updateCasinoEntitySetting", {
                                    casinoId: casinoId,
                                    entityId: entityState.id,
                                    variable: "location",
                                    value: location,
                                })
                            }} />
                        </div>
                        {GameSettings[entityState.type].map((setting, index) => {
                            return (
                                <GameSettingsDisplay game={entityState.type} variable={setting.variable} defaultValue={entitySettings[setting.variable] || setting.default} key={index} onUpdate={(value: any) => {
                                    setEntitySettings((prev) => {
                                        return {
                                            ...prev,
                                            [setting.variable]: value,
                                        }
                                    });
                                    fetchNui("updateCasinoEntitySetting", {
                                        casinoId: casinoId,
                                        entityId: entityState.id,
                                        variable: setting.variable,
                                        value: value,
                                    })
                                }}/>
                            )
                        })}
                        <div className="flex flex-row w-full items-center justify-between">
                            <div className="text-md font-bold"><Translate id="casino_vipenabled"/></div>
                            <input type="checkbox" className="bg-secondary/50 text-sm text-right text-zinc-400 rounded-md px-2 py-1" checked={entitySettings.vip} onChange={(e) => {
                                setEntitySettings((prev) => {
                                    return {
                                        ...prev,
                                        vip: e.target.checked,
                                    }
                                })
                                fetchNui("updateCasinoEntitySetting", {
                                    casinoId: casinoId,
                                    entityId: entityState.id,
                                    variable: "vip",
                                    value: e.target.checked,
                                })
                            }} />
                        </div>
                        <Button variant="secondary" className="w-full" onClick={() => {
                            fetchNui("teleportToEntity", {
                                casinoId: casinoId,
                                entityId: entityState.id,
                            })
                        }}>
                            <Translate id="casino_entity_teleport"/>
                        </Button>
                        <Button variant="secondary" className="w-full" onClick={startExit}>
                            <Translate id="casino_entity_exit"/>
                        </Button>
                        <Button variant="destructive" className="w-full mt-auto" onClick={() => {
                            fetchNui("deleteCasinoEntity", {
                                casinoId: casinoId,
                                entityId: entityState?.id,
                            })
                            startExit()
                        }}>
                            <Translate id="casino_entity_delete"/>
                        </Button>
                    </div>
                </div>
            )}
            {!entityState && (
                <div className="flex flex-col gap-2">
                    <div className="px-2 font-semibold text-lg flex flex-row items-center justify-between">
                        <div className="flex flex-row gap-0 items-center justify-between w-full">
                            <div className="text-md font-bold"><Translate id={"casino_entity_create_title"}/></div>
                        </div>
                    </div>
                    <hr/>
                    <div className="px-2 flex flex-col w-full gap-2 justify-between">
                        <div className="flex flex-row w-full items-center justify-between">
                            <div className="text-md font-bold"><Translate id="casino_entity_type"/></div>
                            <select className="bg-secondary/50 text-sm text-right rounded-md px-2 py-1" value={entityType} onChange={(e) => {
                                setEntityType(e.target.value)
                            }}>
                                {Object.keys(GameSettings).map((game, index) => (
                                    <option key={index} value={game}><Translate id={game + "_title"}/></option>
                                ))}
                            </select>
                        </div>
                    </div>
                    <div className="px-2 flex flex-col w-full gap-2 justify-between">
                        <div className="flex flex-row w-full items-center justify-between">
                            <div className="text-md font-bold"><Translate id="casino_location"/></div>
                            <Location info={{casinoId: casinoId, entityType: entityType, settings: entitySettings}} className="text-sm text-zinc-400" defaultLocation={entitySettings.location || DEFAULT_LOCATION} onUpdate={(location: Location) => {
                                setEntitySettings((prev) => {
                                    return {
                                        ...prev,
                                        location: location,
                                    }
                                });
                            }} />
                        </div>
                        {GameSettings[entityType].map((setting, index) => (
                            <GameSettingsDisplay game={entityType} variable={setting.variable} defaultValue={setting.default} key={index} onUpdate={(value: any) => {
                                let newSettings = {
                                    ...entitySettings,
                                    [setting.variable]: value,
                                }
                                setEntitySettings(newSettings)
                                fetchNui("updateTempCasinoEntitySettings", {
                                    entityType: entityType,
                                    settings: newSettings,
                                })
                            }}/>
                        ))}
                        <div className="flex flex-row w-full items-center justify-between">
                            <div className="text-md font-bold"><Translate id="casino_vipenabled"/></div>
                            <input type="checkbox" className="bg-secondary/50 text-sm text-right text-zinc-400 rounded-md px-2 py-1" checked={entitySettings.vip} onChange={(e) => {
                                setEntitySettings((prev) => {
                                    return {
                                        ...prev,
                                        vip: e.target.checked,
                                    }
                                })
                            }} />
                        </div>
                        <Button variant="default" className="w-full" onClick={() => {
                            fetchNui("createCasinoEntity", {
                                casinoId: casinoId,
                                type: entityType,
                                settings: entitySettings,
                            })
                            startExit()
                        }}>
                            <Save size={16}/>
                            <Translate id="casino_entity_create_title"/>
                        </Button>
                        <Button variant="secondary" className="w-full" onClick={startExit}>
                            <Translate id="casino_entity_exit"/>
                        </Button>
                    </div>
                </div>
            )}
        </>
    )
}

type CasinoSettings = {
    label: string,
    chipItem: string,
    location: Location,
    blipEnabled: boolean,
    template: string,
    cashEnabled: boolean,
    markedEnabled: boolean,
}

function CasinoDisplay({ isManager, casino, onExit }: { isManager?: boolean, casino?: Casino, onExit: () => void }) {
    const {config} = useConfig()
    const [casinoState, setCasinoState] = useState<Casino | null>(casino || null)
    const [currentEditingSetting, setCurrentEditingSetting] = useState<string | null>(null)
    const [label, setLabel] = useState<string>(casino?.settings.label || "")
    const [chipItem, setChipItem] = useState<string>(casino?.settings.chipItem || "")
    const [settings, setSettings] = useState<CasinoSettings>({
        label: casino?.settings.label || "",
        chipItem: casino?.settings.chipItem || "",
        location: casino?.settings.location || DEFAULT_LOCATION,
        blipEnabled: casino?.settings.blipEnabled || false,
        cashEnabled: casino?.settings.cashEnabled || false,
        markedEnabled: casino?.settings.markedEnabled || false,
        template: casino?.settings.template || "default",
    })
    const [currentEntityId, setCurrentEntityId] = useState<string | null>(null)
    const [creatingEntity, setCreatingEntity] = useState(false)
    const currentEntity = casinoState?.entities.find(entity => entity.id === currentEntityId) || null
    const startExit = () => {
        fetchNui("highlightCasinoEntity", {})
        onExit()
    }
    useEffect(() => {
        setLabel(settings.label || "")
        setChipItem(settings.chipItem || "")
    }, [settings])
    useNuiEvent("updateCasinoSetting", (data: any) => {
        if (!casinoState || data.casinoId !== casinoState.id) return;
        setCasinoState((prev) => {
            if (prev) {
                return {
                    ...prev,
                    settings: {
                        ...prev.settings,
                        [data.variable]: data.value,
                    },
                }
            }
            return null
        });
        setSettings((prev) => {
            return {
                ...prev,
                [data.variable]: data.value,
            }
        });
    });
    useNuiEvent("updateCasinoEntities", (data: any) => {
        if (!casinoState || data.casinoId !== casinoState.id) return;
        setCasinoState((prev) => {
            if (prev) {
                return {
                    ...prev,
                    entities: data.entities,
                }
            }
            return null
        });
    });
    useNuiEvent("updateCasinoOwner", (data: any) => {
        if (!casinoState || data.casinoId !== casinoState.id) return;
        setCasinoState((prev) => {
            if (prev) {
                return {
                    ...prev,
                    owner_info: data.owner_info,
                }
            }
            return null
        });
    });
    return (
        <>
            {casinoState ? (
                <>
                    {(currentEntity || creatingEntity) && (
                        <CasinoEntityDisplay casinoId={casinoState.id} entity={currentEntity!} onExit={() => {
                            setCurrentEntityId(null)
                            setCreatingEntity(false)
                        }}/>
                    )}
                    {!(currentEntity || creatingEntity) && (
                        <>
                            <div className="px-2 pb-2 font-semibold text-lg flex flex-row items-center justify-between">
                                <div className="flex flex-row items-center">
                                    <p>{settings.label}</p> 
                                </div>
                                <p className="text-sm text-zinc-400"><Translate id="casino_id" args={[casinoState.id]}/></p>
                            </div>
                            <hr/>
                            <div className="flex flex-col pt-2 gap-2 overflow-auto h-[90%] px-2">
                                <div className="flex flex-row w-full items-center justify-between">
                                    <div className="text-md font-bold"><Translate id="casino_location"/></div>
                                    <Location info={{casinoId: casinoState.id}} className="text-sm text-zinc-400" defaultLocation={settings.location} onUpdate={(location: Location) => {
                                        setSettings((prev) => {
                                            return {
                                                ...prev,
                                                location: location,
                                            }
                                        })
                                        fetchNui("updateCasinoSetting", {
                                            casinoId: casinoState.id,
                                            variable: "location",
                                            value: location,
                                        })
                                    }}/>
                                </div>
                                <div className="flex flex-row w-full items-center justify-between">
                                    <div className="text-md font-bold"><Translate id="casino_name"/></div>
                                    {(currentEditingSetting == "label") ? (
                                        <>
                                            <div className="flex flex-row items-center gap-2">
                                                <input type="text" className="bg-secondary/50 text-sm text-right text-zinc-400 rounded-md px-2 py-1" value={label} onChange={(e) => {
                                                    setLabel(e.target.value)
                                                }} placeholder="Enter casino name..." />
                                                <Save size={16} className="cursor-pointer hover:scale-95 transition-all duration-200" onClick={() => {
                                                    setSettings((prev) => {
                                                        return {
                                                            ...prev,
                                                            label: label,
                                                        }
                                                    });
                                                    fetchNui("updateCasinoSetting", {
                                                        casinoId: casinoState.id,
                                                        variable: "label",
                                                        value: label,
                                                    })
                                                    setCurrentEditingSetting(null)
                                                }}/>
                                            </div>
                                        </>
                                    ) : ( 
                                        <div className="flex flex-row items-center gap-2">
                                            <div className="text-sm text-zinc-400">{settings.label}</div>
                                            <Edit size={16} className="cursor-pointer hover:scale-95 transition-all duration-200 ml-2" onClick={() => {
                                                setCurrentEditingSetting("label")
                                            }}/>
                                        </div>
                                    )}
                                </div>
                                {!isManager && (<div className="flex flex-row w-full items-center justify-between">
                                    <div className="text-md font-bold"><Translate id="casino_item"/></div>
                                    {(currentEditingSetting == "chipItem") ? (
                                        <>
                                            <div className="flex flex-row items-center gap-2">
                                                <input type="text" className="bg-secondary/50 text-sm text-right text-zinc-400 rounded-md px-2 py-1" value={chipItem} onChange={(e) => {
                                                    setChipItem(e.target.value)
                                                }} placeholder="Enter item name..." />
                                                <Save size={16} className="cursor-pointer hover:scale-95 transition-all duration-200" onClick={() => {
                                                    setSettings((prev) => {
                                                        return {
                                                            ...prev,
                                                            chipItem: chipItem,
                                                        }
                                                    });
                                                    fetchNui("updateCasinoSetting", {
                                                        casinoId: casinoState.id,
                                                        variable: "chipItem",
                                                        value: chipItem,
                                                    })
                                                    setCurrentEditingSetting(null)
                                                }}/>
                                            </div>
                                        </>
                                    ) : ( 
                                        <div className="flex flex-row items-center gap-2">
                                            <div className="text-sm text-zinc-400">{settings.chipItem}</div>
                                            <Edit size={16} className="cursor-pointer hover:scale-95 transition-all duration-200 ml-2" onClick={() => {
                                                setCurrentEditingSetting("chipItem")
                                            }}/>
                                        </div>
                                    )}
                                </div>)}
                                <div className="flex flex-row w-full items-center justify-between">
                                    <div className="text-md font-bold"><Translate id="casino_blipenabled"/></div>
                                    <input type="checkbox" className="bg-secondary/50 text-sm text-right text-zinc-400 rounded-md px-2 py-1" checked={settings.blipEnabled} onChange={(e) => {
                                        setSettings((prev) => {
                                            return {
                                                ...prev,
                                                blipEnabled: e.target.checked,
                                            }
                                        })
                                        fetchNui("updateCasinoSetting", {
                                            casinoId: casinoState.id,
                                            variable: "blipEnabled",
                                            value: e.target.checked ? true : false,
                                        })
                                    }} />
                                </div>
                                {!isManager && (<div className="flex flex-row w-full items-center justify-between">
                                    <div className="text-md font-bold"><Translate id="casino_cashenabled"/></div>
                                    <input type="checkbox" className="bg-secondary/50 text-sm text-right text-zinc-400 rounded-md px-2 py-1" checked={settings.cashEnabled} onChange={(e) => {
                                        setSettings((prev) => {
                                            return {
                                                ...prev,
                                                cashEnabled: e.target.checked,
                                            }
                                        })
                                        fetchNui("updateCasinoSetting", {
                                            casinoId: casinoState.id,
                                            variable: "cashEnabled",
                                            value: e.target.checked ? true : false,
                                        })
                                    }} />
                                </div>)}
                                {!isManager && (<div className="flex flex-row w-full items-center justify-between">
                                    <div className="text-md font-bold"><Translate id="casino_markedenabled"/></div>
                                    <input type="checkbox" className="bg-secondary/50 text-sm text-right text-zinc-400 rounded-md px-2 py-1" checked={settings.markedEnabled} onChange={(e) => {
                                        setSettings((prev) => {
                                            return {
                                                ...prev,
                                                markedEnabled: e.target.checked,
                                            }
                                        })
                                        fetchNui("updateCasinoSetting", {
                                            casinoId: casinoState.id,
                                            variable: "markedEnabled",
                                            value: e.target.checked ? true : false,
                                        })
                                    }} />
                                </div>)}
                                {!isManager && (<div className="flex flex-row w-full items-center justify-between">
                                    <div className="text-md font-bold"><Translate id="casino_owner"/></div>
                                    <Player info={{casinoId: casinoState.id}} className="text-sm text-zinc-400" defaultPlayer={casinoState.owner_info || undefined} onUpdate={(player: Player) => {
                                        setCasinoState((prev) => {
                                            if (prev) {
                                                return {
                                                    ...prev,
                                                    owner_info: player,
                                                }
                                            }
                                            return null
                                        })
                                        fetchNui("updateCasinoOwner", {
                                            casinoId: casinoState.id,
                                            value: player,
                                        })
                                    }}/>
                                </div>)}
                                <div className="flex flex-col w-full justify-between">
                                    <div className="text-md font-bold"><Translate id="casino_entities"/></div>
                                    <div className="flex flex-col w-full max-h-[300px] overflow-auto gap-2 justify-between bg-background/50 p-2 mt-2">
                                        <Button variant="secondary" className="w-full hover:scale-95 transition-all duration-200" onClick={() => {
                                            fetchNui("highlightCasinoEntity", {})
                                            setCreatingEntity(true)
                                            setCurrentEntityId(null)
                                        }}>
                                            <Plus size={16} />
                                            <Translate id="casino_entity_create"/>
                                        </Button>
                                        {casinoState.entities.map((entity, index) => (
                                            <div key={index} className="flex flex-col justify-between w-full p-2 bg-secondary/50 rounded-md select-none hover:scale-95 transition-all duration-200 cursor-pointer" onMouseEnter={ () => {
                                                fetchNui("highlightCasinoEntity", {
                                                    casinoId: casinoState.id,
                                                    entityId: entity.id,
                                                })
                                            }} onMouseLeave={() => {
                                                fetchNui("highlightCasinoEntity", {})
                                            }} onClick={() => {
                                                fetchNui("highlightCasinoEntity", {})
                                                setCurrentEntityId(entity.id)
                                            }}>
                                                <div className="flex flex-row gap-0 items-center justify-between w-full">
                                                    <div className="text-md font-bold"><Translate id={entity.type + "_title"}/></div>
                                                    {entity.location && <Location className="text-sm text-zinc-400" defaultLocation={entity.location}/>}
                                                </div>
                                                <div className="text-sm text-zinc-400"><Translate id={"casino_id"} args={[entity.id]}/></div>
                                            </div>
                                        ))}
                                    </div>
                                </div>
                                <Button variant="secondary" className="w-full" onClick={() => {
                                    fetchNui("teleportToCasino", {
                                        casinoId: casinoState.id,
                                    })
                                }}>
                                    <Translate id="casino_teleport"/>
                                </Button>
                                <Button variant="secondary" className="w-full" onClick={startExit}>
                                    <Translate id={isManager ? "casino_exit_editor" : "casino_exit"}/>
                                </Button>
                                {!isManager && (<Button variant="destructive" className="w-full mt-auto" onClick={() => {
                                    fetchNui("deleteCasino", {
                                        id: casinoState.id,
                                    })
                                }}>
                                    <Translate id="casino_delete"/>
                                </Button>)}
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
                            <div className="text-md font-bold"><Translate id="casino_location"/></div>
                            <Location className="text-sm text-zinc-400" defaultLocation={settings.location} onUpdate={(location: Location) => {
                                setSettings((prev) => {
                                    return {
                                        ...prev,
                                        location: location,
                                    }
                                })
                            }} />
                        </div>
                        <div className="flex flex-row w-full items-center justify-between">
                            <div className="text-md font-bold"><Translate id="casino_name"/></div>
                            <input type="text" className="bg-secondary/50 text-sm text-right text-zinc-400 rounded-md px-2 py-1" value={settings.label} onChange={(e) => {
                                setSettings((prev) => {
                                    return {
                                        ...prev,
                                        label: e.target.value,
                                    }
                                })
                            }} placeholder="Enter casino name..." />
                        </div>
                        <div className="flex flex-row w-full items-center justify-between">
                            <div className="text-md font-bold"><Translate id="casino_item"/></div>
                            <input type="text" className="bg-secondary/50 text-sm text-right text-zinc-400 rounded-md px-2 py-1" value={settings.chipItem} onChange={(e) => {
                                setSettings((prev) => {
                                    return {
                                        ...prev,
                                        chipItem: e.target.value,
                                    }
                                })
                            }} placeholder="Enter item name..." />
                        </div>
                        <div className="flex flex-row w-full items-center justify-between">
                            <div className="text-md font-bold"><Translate id="casino_blipenabled"/></div>
                            <input type="checkbox" className="bg-secondary/50 text-sm text-right text-zinc-400 rounded-md px-2 py-1" checked={settings.blipEnabled} onChange={(e) => {
                                setSettings((prev) => {
                                    return {
                                        ...prev,
                                        blipEnabled: e.target.checked,
                                    }
                                })
                            }} />
                        </div>
                        <div className="flex flex-row w-full items-center justify-between">
                            <div className="text-md font-bold"><Translate id="casino_template"/></div>
                            <select className="bg-secondary/50 text-sm text-right rounded-md px-2 py-1" value={settings.template} onChange={(e) => {
                                setSettings((prev) => {
                                    return {
                                        ...prev,
                                        template: e.target.value,
                                    }
                                });
                            }}>
                                {config.templates.map((template, index) => (
                                    <option key={index} value={template.value}>{template.label}</option>
                                ))}
                            </select>
                        </div>
                        <Button variant="default" className="w-full"  onClick={() => {
                            fetchNui("createCasino", settings)
                            startExit();
                        }}>
                            <Save size={16}/>
                            <Translate id="casino_create"/>
                        </Button>
                        <Button variant="secondary" className="w-full" onClick={startExit}>
                            <Translate id="casino_exit"/>
                        </Button>
                    </div>
                </>
            )}
        </>
    )
}

function Creator({ defaultCasinos }: { defaultCasinos: Casino[] }) {
    const [currentCasinoId, setCurrentCasinoId] = useState<number | null>(null)
    const [casinos, setCasinos] = useState<Casino[]>(defaultCasinos)
    const currentCasino: Casino | null = casinos.find(casino => casino.id === currentCasinoId) || null
    const [creatingCasino, setCreatingCasino] = useState(false)
    useNuiEvent("updateCasinos", (data: any) => {
        setCasinos(data.casinos)
    });
    return (
        <>
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
                                    <h2 className="text-md font-bold">{casino.settings.label}</h2>
                                    <p className="text-sm text-zinc-400"><Translate id="casino_id" args={[casino.id]}/></p>
                                </div>
                                <div className="flex flex-row items-center justify-between">
                                    <Location className="text-sm text-zinc-400" defaultLocation={casino.settings.location} />
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
        </>
    )
}

export default function CreatorDisplay() {
    const [visible, setVisible] = useState(false)
    const [casinos, setCasinos] = useState<Casino[]>([])
    const [focus, setFocus] = useState(false)
    const [hidden, setHidden] = useState(true)
    const [casinoId, setCasinoId] = useState<number | null>(null)
    useNuiEvent("setEditorHidden", (data: any) => {
        setHidden(data.hidden)
    });
    useNuiEvent("updateCasinos", (data: any) => {
        setCasinos(data.casinos)
    });
    useNuiEvent("updateCasinoEntities", (data: any) => {
        setCasinos((prev) => {
            return prev.map((casino) => {
                if (casino.id === data.casinoId) {
                    return {
                        ...casino,
                        entities: data.entities,
                    }
                }
                return casino
            })
        })
    });
    useEffect(() => {
        const handleKeyDown = (event: KeyboardEvent) => {
            if (event.target instanceof HTMLInputElement || event.target instanceof HTMLTextAreaElement) return;
            if (!visible) return;
            if (event.key === "Escape" || event.key === "Backspace") {
                fetchNui("exitCasinoEditor", {});
            }
            if (event.key === "g") {
                fetchNui("disableEditorFocus", {});
            }
        };

        window.addEventListener("keydown", handleKeyDown);

        return () => {
            window.removeEventListener("keydown", handleKeyDown);
        };
    });
    useNuiEvent("setEditorFocus", (data: any) => {
        setFocus(data.toggle)
    });

    useNuiEvent("openCasinoEditor", (data: any) => {
        setCasinos(data.casinos)
        setCasinoId(data.casinoId || null)
        setHidden(true)
        setVisible(true)
        setTimeout(() => {
            setHidden(false)
        }, 10)
    });
    useNuiEvent("closeCasinoEditor", () => {
        setHidden(true)
        setFocus(false)
        setTimeout(() => {
            setVisible(false)
        }, 300)
    });
    return (
        <>
            
            {(visible && !hidden) && <CasinoControls controls={[{key: "G", label: <Translate id={"focus_" + (focus ? "off" :  "on")}/>}]} />}
            {visible && (
                <div className="absolute top-0 left-0 w-full h-full overflow-hidden">
                    <div
                        className={`relative ml-auto px-2 py-2 w-[400px] h-full bg-background/95 transition-transform duration-300 ${
                        hidden ? "translate-x-full" : "translate-x-0"
                        }`}
                    > 
                    {casinoId ? (
                        <CasinoDisplay isManager={true} casino={casinos.find(casino => casino.id === casinoId)} onExit={() => {
                            fetchNui("exitCasinoEditor", {})
                        }}/>
                    ) : (
                        <Creator defaultCasinos={casinos} />
                    )}
                    </div>
                </div>  
            )}
        </>
    )
}