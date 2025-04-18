import { useState } from "react";
import Blackjack from "./components/games/blackjack/Blackjack";
import { Button } from "./components/ui/button";
import { useNuiEvent } from "./providers/nui/useNui";
import { CasinoGameDisplay } from "./components/casino/Casino";
import CreatorDisplay from "./components/creator/Creator";

export type User = {
  identifier: string;
  name: string;
  role: string;
  image: string;
}

function App() {
  return (
    <div className="dark w-screen h-screen absolute text-primary top-0 left-0">
      <CasinoGameDisplay />
      <CreatorDisplay />
    </div>
  )
}

export default App
