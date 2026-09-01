const SOUNDS: Record<string, string> = {
  seatbeltOn: './sounds/seatbeltOn.mp3',
  seatbeltOff: './sounds/seatbeltOff.mp3',
}

const players = new Map<string, HTMLAudioElement>()

function player(id: string) {
  let audio = players.get(id)
  if (!audio) {
    audio = new Audio(SOUNDS[id])
    audio.preload = 'auto'
    players.set(id, audio)
  }
  return audio
}

export function playHudSound(id: string, volume = 0.45) {
  if (!SOUNDS[id]) return
  const audio = player(id)
  audio.volume = Math.min(1, Math.max(0, volume))
  audio.currentTime = 0
  void audio.play().catch(() => {})
}
