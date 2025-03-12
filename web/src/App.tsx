import { Button } from "./components/ui/button";

export type User = {
  identifier: string;
  name: string;
  role: string;
  image: string;
}

function GameIcon({name, style}: {name: string, style?: React.CSSProperties}) {
  if (name === "blackjack") {
    return (
      <svg xmlns="http://www.w3.org/2000/svg" width={20} height={20} viewBox="0 0 15 15" version="1.1" style={style}>
        <path xmlns="http://www.w3.org/2000/svg" d="M8.5,10c0.4561,0.6072,1.1821,1,2,1c1.3807,0,2.5-1.1193,2.5-2.5c0-0.5642-0.1938-1.0789-0.509-1.4973L12.5,7l-5-6l-5,6&#10;&#9;l0.009,0.0027C2.1938,7.4211,2,7.9358,2,8.5C2,9.8807,3.1193,11,4.5,11c0.8179,0,1.5439-0.3928,2-1&#10;&#9;C6.5997,9.8672,6.7902,9.6135,7,9.3337V11.5C7,13,4.5,13,4.5,13C4.2239,13,4,13.2238,4,13.5C4,13.7761,4.2239,14,4.5,14H7h1h2.5&#10;&#9;c0.2761,0,0.5-0.2239,0.5-0.5c0-0.2762-0.2239-0.5-0.5-0.5c0,0-2.5,0-2.5-1.5V9.3337C8.2098,9.6135,8.4003,9.8672,8.5,10z"/>
      </svg>
    )
  }
}

function App() {
  let playerCards = [
    {class: "clubs", value: "A"},
    {class: "clubs", value: "2"},
    {class: "clubs", value: "3"},
    {class: "clubs", value: "4"},
    {class: "clubs", value: "5"},
    {class: "clubs", value: "6"},
    {class: "clubs", value: "7"},
    {class: "clubs", value: "8"},

  ]
  let players = [
    {
      name: "John Doe",
      cards: [
        {class: "clubs", value: "A"},
        {class: "clubs", value: "2"},
        {class: "clubs", value: "3"},
        {class: "clubs", value: "4"},
        {class: "clubs", value: "5"},
        {class: "clubs", value: "6"},
        {class: "clubs", value: "7"},
        {class: "clubs", value: "8"},
      ]
    },
    {
      name: "Jane Doe",
      cards: [
        {class: "clubs", value: "A"},
        {class: "clubs", value: "2"},
        {class: "clubs", value: "3"},
      ]
    },
    {
      name: "Johnathaneeeeeeeeeeeeeeeeeeeeeeeeeeeee Doe",
      cards: [

        {class: "clubs", value: "A"},
        {class: "clubs", value: "2"},
        {class: "clubs", value: "3"},
        {class: "clubs", value: "4"},
        {class: "clubs", value: "5"},
        {class: "clubs", value: "6"},
        {class: "clubs", value: "7"},
        {class: "clubs", value: "8"},
      ]
    },
    {
      name: "Jennifer Doe",
      cards: [
        {class: "clubs", value: "A"},
        {class: "clubs", value: "2"},
        {class: "clubs", value: "3"},
      ]
    }
  ];
  return (
    <div className="dark w-screen h-screen absolute text-primary top-0 left-0" style={{ backgroundImage: 'url(/nui/images/background.png)' }}>
      <div className='flex flex-col bg-background/95 absolute w-full p-8' style={{ height: 250, bottom: 0, left: '0', }}>
        <div className='flex justify-between h-full items-center'>
          <div className='flex flex-col gap-2'>
            <div className="flex flex-col gap-2">
              <div className='flex flex-row items-center gap-2'>
                <GameIcon name='blackjack' style={{fill: "yellow", width: 30, height: 30}} />
                <div className='font-bold text-4xl'>Blackjack</div>
              </div>
              <div className="font-semibold text-md text-zinc-400">Welcome to the Blackjack table, {playerCards.length} players are currently playing.</div>
            </div>
            <div className='flex flex-col gap-4'>
              <div className="flex flex-row items-end gap-2">
                <div className='flex flex-col gap-2'>
                  <div className='font-bold text-2xl'>Current Hand: (1/11)</div>
                    <div className='grid grid-cols-2 gap-1'>
                    <Button variant={"secondary"}>Hit</Button>
                    <Button variant={"secondary"}>Stand</Button>
                    <Button variant={"secondary"}>Double</Button>
                    <Button variant={"secondary"}>Split</Button>
                  </div>
                </div>
                <div className="flex flex-col gap-2 relative">
                  {playerCards.map((card, index) => (
                    <img src={`/nui/images/cards/${card.class}_${card.value}.png`} alt="card" className="h-28 border rounded-md" style={index > 0 ? {
                      position: "absolute",
                      left: index * 20,
                      zIndex: index,
                    } : undefined} />
                  ))}
                </div>
              </div>
            </div>
          </div>
          <div className="flex flex-col gap-2">
            {/* <div className='flex flex-row gap-2 items-center justify-between w-100'>
              <div className='font-bold text-2xl'>DEALER: (1/11)</div>
              <div className="flex flex-col gap-2 relative">
                {playerCards.map((card, index) => (
                  <img src={`/nui/images/cards/${card.class}_${card.value}.png`} alt="card" className="w-fit h-15 border rounded-md" style={index > 0 ? {
                    position: "absolute",
                    right: index * 10,
                    zIndex: playerCards.length - index,
                  } : {
                    zIndex: playerCards.length,
                  }} />
                ))}
              </div>
            </div> */}
            <div className="grid grid-cols-2 gap-4 w-150">
              {players.map((player, index) => (
                <div className='flex flex-row items-center justify-between gap-2 border p-2 rounded-md' key={index}>
                  <div className="flex flex-col gap-0 w-full">
                    <div className="flex flex-row gap-2 justify-between items-center">
                      <div className="flex flex-col gap-2 w-full">
                        <div className="flex flex-row gap-2 justify-between items-center">
                            <div className='font-bold text-lg truncate' style={{
                              maxWidth: 200 - (8 * (player.cards.length - 1)),
                            }}>{player.name}</div>
                        </div>
                        <div className="font-semibold text-md text-zinc-400">$10,000</div>
                      </div>
                      <div className="flex flex-row justify-end gap-2 items-center">
                      <div className="font-semibold text-sm text-zinc-400">9/19</div>

                        <div className="flex flex-col gap-2 relative items-end" style={{width: 33 + (8 * (player.cards.length - 1))}}>
                          {player.cards.map((card, index) => (
                            <img src={`/nui/images/cards/${card.class}_${card.value}.png`} alt="card" className="w-fit h-12 border rounded-md" style={index > 0 ? {
                              position: "absolute",
                              right: index * 8,
                              zIndex: player.cards.length - index,
                            } : {
                              zIndex: player.cards.length,
                            }} />
                          ))}
                        </div>
                      </div>
                    </div>

                  </div>
                </div>
              ))}
            </div>
          </div>
        </div>
        <div className="transform transform-z-0 rounded-md" id='dialog-container' style={{position: "absolute", top: 0, left: 0, width: "100%", height: "100%", overflow: "hidden", pointerEvents: "none", zIndex: 100}}></div>
      </div>
    </div>
  )
}

export default App
