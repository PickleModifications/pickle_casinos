import React, { useEffect, useState } from 'react'
import RoulettePro from 'react-roulette-pro';
import 'react-roulette-pro/dist/index.css';
import { useConfig } from '@/providers/config';
import { useNuiEvent } from '@/providers/nui/useNui';

export default function BonusWheel({isSpinning, prizeWon, onSpinComplete} : {isSpinning: boolean, prizeWon: string, onSpinComplete?:() => void}) {
    const { config } = useConfig();
    const [currentTime, setCurrentTime] = useState(Math.floor(Date.now() / 1000));
    const prizeSize = 150;
    const prizeItemWidth = prizeSize;
    const prizeItemHeight = prizeSize;
    const minimumPrizesInAnimation = 50;
    const prizeList: any = [];
    const prizes = config.bonusWheelMultipliers || [];
    if (!prizes || prizes.length < 1) return null;
    let decoyPrizes = 0;
    let prizeIndex = 0;
    useEffect(() => {
        const interval = setInterval(() => {
            setCurrentTime(Math.floor(Date.now() / 1000));
        }, 1000);

        return () => clearInterval(interval);
    }, []);
    while (prizeList.length < minimumPrizesInAnimation || prizeList.length < prizes.length * 2) {
        prizes.map((prize) => {
            prizeList.push({
                ...prize,
                id: "sequence_" + decoyPrizes,
                prizeId: prize.id,
                text: "x" + prize.multiplier,
            });
            decoyPrizes++;
        });
    }
    for (let i=decoyPrizes - 1; i>=0; i--) {
        const decoyPrize = prizeList[i];
        const distance = Math.abs(decoyPrizes - i);
        console.log(decoyPrize.prizeId, prizeWon)
        if (decoyPrize.prizeId == prizeWon && distance > 5) {
            prizeIndex = i;
            break;
        }
    }
    console.log(prizeIndex)
    return (
        <RoulettePro
            start={isSpinning}
            prizes={prizeList}
            prizeIndex={prizeIndex}
            spinningTime={5}
            options={{stopInCenter: true}}
            soundWhileSpinning={"nui/audio/wheel/tick.mp3"}
            designPlugin={() => ({
                prizeItemWidth: prizeItemWidth,
                prizeItemHeight: prizeItemHeight,
                prizeItemRenderFunction: (item) => (
                    <div style={{borderRight: "2px solid hsl(var(--card))", borderLeft: "2px solid hsl(var(--card))", width: prizeItemWidth, height: prizeItemHeight}} className={'relative bg-secondary flex flex-col items-center justify-center roulette-item-bounds font-bold text-4xl prize-' + item.id}>
                        {item.text}
                    </div>
                )
            })}
            onPrizeDefined={() => {
                setTimeout(() => {
                    if (onSpinComplete) {
                        onSpinComplete();
                    }
                }, 1000);
            }}
        />
    )
}
