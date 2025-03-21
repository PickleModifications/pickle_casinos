import { AnimatedValue } from "@/components/casino/Casino"
import { useNuiEvent } from "@/providers/nui/useNui"
import { useEffect, useState } from "react"

function OutlinedText({children} : {children: any}) {
    return (
        <span style={{
            WebkitTextStroke: '2px black',
            color: 'white',
            fontWeight: 'bold',
        }}>{children}</span>
    )
}

type ResultsType = {
    winnings: number
}

export default function Results() {
    const [results, setResults] = useState<ResultsType | null>(null)
    const [scale, setScale] = useState(0)
    const [winnings, setWinnings] = useState(0)
    const [hiding, setHiding] = useState(false)
    const showResults = (results: ResultsType) => {
        setResults(results)
        setScale(0.0)
        setWinnings(0)
        setHiding(false)
    }
    useEffect(() => {
        if (results) {
            let animationFrame: number;
            let scaleSpeed = 0.04;
            const animateScale = () => {
                setScale((prev) => {
                    if (prev > 0.0 && winnings !== results.winnings) {
                        setWinnings(results.winnings);
                    }
                    if (prev < 1.0) {
                        return Math.min(prev + scaleSpeed, 1.0);
                    } else {
                        cancelAnimationFrame(animationFrame);
                        setTimeout(() => {
                            const reverseScale = () => {
                                setScale((prev) => {
                                    if (prev > 0.0) {
                                        return Math.max(prev - scaleSpeed, 0.0);
                                    } else {
                                        cancelAnimationFrame(animationFrame);
                                        return prev;
                                    }
                                });
                                animationFrame = requestAnimationFrame(reverseScale);
                            };
                            reverseScale();
                        }, 5000);
                        return prev;
                    }
                });
                animationFrame = requestAnimationFrame(animateScale);
            };
            animateScale();
            return () => cancelAnimationFrame(animationFrame);
        }
    }, [results]);
    useNuiEvent("displayResults", (data) => {
        showResults(data.results);
    });
    return (scale > 0.0) && (
        <div className="flex flex-col absolute w-full px-8 py-8">
            <div className="flex flex-col gap-2 items-center justify-center w-full" style={{
                transform: `scale(${scale})`,
                transformOrigin: "top",
            }}>
                <OutlinedText><div className="font-bold text-7xl">YOU WON</div></OutlinedText>
                <OutlinedText><div className="font-bold text-6xl text-green-400"><AnimatedValue value={winnings} time={30}/></div></OutlinedText>
            </div>
        </div>
    )
}